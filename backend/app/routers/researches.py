# Endpoint CRUD riset (FR-03 & FR-04 di BRD).
# Semua endpoint di sini butuh login — riset yang diambil/diubah selalu
# difilter berdasarkan user yang sedang login, supaya user A tidak bisa
# melihat/mengubah riset milik user B.

import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.models.user import User
from app.models.research import Research
from app.schemas.research import (
    ResearchCreateRequest,
    ResearchUpdateRequest,
    ResearchResponse,
)
from app.core.deps import get_current_user

router = APIRouter(prefix="/researches", tags=["researches"])


@router.post("", response_model=ResearchResponse, status_code=status.HTTP_201_CREATED)
async def create_research(
    data: ResearchCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    research = Research(user_id=current_user.id, **data.model_dump())
    db.add(research)
    await db.commit()
    await db.refresh(research)
    return ResearchResponse.model_validate(research)


@router.get("", response_model=list[ResearchResponse])
async def list_researches(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Research)
        .where(Research.user_id == current_user.id)
        .order_by(Research.updated_at.desc())
    )
    researches = result.scalars().all()
    return [ResearchResponse.model_validate(r) for r in researches]


# Dipakai internal file ini & router lain: ambil 1 riset + pastikan miliknya user ini
async def get_owned_research(db: AsyncSession, research_id: uuid.UUID, user: User) -> Research:
    result = await db.execute(
        select(Research).where(Research.id == research_id, Research.user_id == user.id)
    )
    research = result.scalar_one_or_none()
    if research is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Riset tidak ditemukan")
    return research


@router.get("/{research_id}", response_model=ResearchResponse)
async def get_research(
    research_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    research = await get_owned_research(db, research_id, current_user)
    return ResearchResponse.model_validate(research)


@router.patch("/{research_id}", response_model=ResearchResponse)
async def update_research(
    research_id: uuid.UUID,
    data: ResearchUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    research = await get_owned_research(db, research_id, current_user)

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(research, field, value)

    await db.commit()
    await db.refresh(research)
    return ResearchResponse.model_validate(research)


@router.delete("/{research_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_research(
    research_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    research = await get_owned_research(db, research_id, current_user)
    await db.delete(research)
    await db.commit()
