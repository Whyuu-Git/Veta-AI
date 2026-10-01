# Endpoint Ekspor PDF (FR-09): generate laporan, unduh, dan riwayat.

import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.models.user import User
from app.models.research_note import ResearchNote
from app.models.intelligence_analysis import IntelligenceAnalysis
from app.models.pdf_report import PdfReport
from app.core.deps import get_current_user
from app.routers.researches import get_owned_research
from app.services.pdf_service import generate_research_pdf

# CATATAN: kalau model intelligence kamu bernama intelligence_analysis.py,
# ganti baris import IntelligenceAnalysis di atas menjadi:
# from app.models.intelligence_analysis import IntelligenceAnalysis

router = APIRouter(prefix="/pdf", tags=["pdf_reports"])

VALID_TYPES = ("summary", "full_report", "progress_report")


@router.post("/{research_id}", status_code=status.HTTP_201_CREATED)
async def create_pdf(
    research_id: uuid.UUID,
    report_type: str = "summary",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate PDF baru. report_type: summary | full_report | progress_report
    (MVP: ketiganya memakai template sama, dibedakan judul)."""
    if report_type not in VALID_TYPES:
        raise HTTPException(status_code=400, detail="report_type tidak valid")

    research = await get_owned_research(db, research_id, current_user)

    # Ambil catatan
    notes_result = await db.execute(
        select(ResearchNote)
        .where(ResearchNote.research_id == research_id)
        .order_by(ResearchNote.created_at.asc())
    )
    notes = [
        {"title": n.title, "content": n.content, "type": n.type}
        for n in notes_result.scalars().all()
    ]

    # Ambil analisis Intelligence terakhir (boleh tidak ada)
    analysis_result = await db.execute(
        select(IntelligenceAnalysis)
        .where(IntelligenceAnalysis.research_id == research_id)
        .order_by(IntelligenceAnalysis.created_at.desc())
        .limit(1)
    )
    latest = analysis_result.scalar_one_or_none()
    latest_analysis = None
    if latest:
        latest_analysis = {
            "health_score": latest.health_score,
            "publication_readiness": latest.publication_readiness,
            "gap_analysis": latest.gap_analysis,
            "novelty_assessment": latest.novelty_assessment,
            "strengths": latest.strengths,
            "weaknesses": latest.weaknesses,
            "recommendations": latest.recommendations,
        }

    file_path = generate_research_pdf(
        report_type=report_type,
        research={
            "title": research.title,
            "field": research.field,
            "topic": research.topic,
            "keywords": research.keywords,
            "goal": research.goal,
            "abstract": research.abstract,
            "current_stage": research.current_stage,
            "progress_percentage": research.progress_percentage,
            "citation_style": research.citation_style,
        },
        notes=notes,
        latest_analysis=latest_analysis,
    )

    report = PdfReport(
        research_id=research_id,
        user_id=current_user.id,
        report_type=report_type,
        file_path=file_path,
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    return {"id": str(report.id), "report_type": report.report_type, "created_at": str(report.created_at)}


@router.get("/{report_id}/download")
async def download_pdf(
    report_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PdfReport).where(PdfReport.id == report_id, PdfReport.user_id == current_user.id)
    )
    report = result.scalar_one_or_none()
    if report is None or not report.file_path or not os.path.exists(report.file_path):
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")

    return FileResponse(
        report.file_path,
        media_type="application/pdf",
        filename=os.path.basename(report.file_path),
    )


@router.get("/history/{research_id}")
async def list_reports(
    research_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await get_owned_research(db, research_id, current_user)

    result = await db.execute(
        select(PdfReport)
        .where(PdfReport.research_id == research_id)
        .order_by(PdfReport.created_at.desc())
    )
    return [
        {"id": str(r.id), "report_type": r.report_type, "created_at": str(r.created_at)}
        for r in result.scalars().all()
    ]