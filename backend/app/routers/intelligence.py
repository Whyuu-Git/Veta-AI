# Endpoint Intelligence (FR-08): jalankan analisis AI atas proyek riset,
# simpan hasilnya, dan sediakan riwayat analisis.

import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from google.genai import errors as genai_errors

from app.database.connection import get_db
from app.models.user import User
from app.models.intelligence_analysis import IntelligenceAnalysis
from app.schemas.intelligence import IntelligenceResponse
from app.core.deps import get_current_user
from app.routers.researches import get_owned_research
from app.services.llm_service import LlmService
from app.services.quota_service import check_intelligence_quota

router = APIRouter(prefix="/intelligence", tags=["intelligence"])

llm_service = LlmService()


@router.post("/{research_id}", response_model=IntelligenceResponse, status_code=status.HTTP_201_CREATED)
async def run_analysis(
    research_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Jalankan analisis AI baru atas riset ini. Bisa dipanggil berulang —
    setiap pemanggilan menghasilkan baris riwayat baru."""
    research = await get_owned_research(db, research_id, current_user)

    # Cek kuota harian tier sebelum memproses (FR-11)
    await check_intelligence_quota(db, current_user)

    try:
        result = llm_service.generate_intelligence_analysis({
            "title": research.title,
            "field": research.field,
            "topic": research.topic,
            "keywords": research.keywords,
            "goal": research.goal,
            "abstract": research.abstract,
            "current_stage": research.current_stage,
            "progress_percentage": research.progress_percentage,
        })
    except genai_errors.ClientError as e:
        if e.code == 429:
            raise HTTPException(
                status_code=429,
                detail="Analisis AI sedang sibuk (batas kuota per menit tercapai). Tunggu sebentar lalu coba lagi.",
            )
        raise
    except (ValueError, KeyError):
        # json.loads gagal atau struktur tak terduga — sangat jarang karena
        # response_mime_type sudah memaksa JSON, tapi tetap dijaga
        raise HTTPException(
            status_code=502,
            detail="Hasil analisis AI tidak dapat diproses. Coba jalankan ulang.",
        )

    analysis = IntelligenceAnalysis(
        research_id=research_id,
        user_id=current_user.id,
        health_score=result.get("health_score"),
        publication_readiness=result.get("publication_readiness"),
        gap_analysis=result.get("gap_analysis"),
        novelty_assessment=result.get("novelty_assessment"),
        strengths=result.get("strengths"),
        weaknesses=result.get("weaknesses"),
        recommendations=result.get("recommendations"),
    )
    db.add(analysis)
    await db.commit()
    await db.refresh(analysis)

    return IntelligenceResponse.model_validate(analysis)


@router.get("/{research_id}", response_model=list[IntelligenceResponse])
async def list_analyses(
    research_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Riwayat analisis riset ini, terbaru dulu. Frontend tinggal ambil
    elemen pertama untuk menampilkan hasil terkini di layar Intelligence."""
    await get_owned_research(db, research_id, current_user)

    result = await db.execute(
        select(IntelligenceAnalysis)
        .where(IntelligenceAnalysis.research_id == research_id)
        .order_by(IntelligenceAnalysis.created_at.desc())
    )
    analyses = result.scalars().all()
    return [IntelligenceResponse.model_validate(a) for a in analyses]