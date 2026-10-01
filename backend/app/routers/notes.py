# Endpoint Catatan Riset (FR-05) + simpan jurnal sebagai catatan (FR-07d).

import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.models.user import User
from app.models.research_note import ResearchNote
from app.models.journal import Journal
from app.schemas.research_note import (
    NoteCreateRequest,
    NoteUpdateRequest,
    NoteFromJournalRequest,
    NoteResponse,
)
from app.core.deps import get_current_user
from app.routers.researches import get_owned_research

router = APIRouter(tags=["research_notes"])


@router.post("/researches/{research_id}/notes", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_note(
    research_id: uuid.UUID,
    data: NoteCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await get_owned_research(db, research_id, current_user)

    if data.type not in ("note", "reference", "writing", "idea"):
        raise HTTPException(status_code=400, detail="Tipe catatan tidak valid")

    note = ResearchNote(
        research_id=research_id,
        user_id=current_user.id,
        title=data.title,
        content=data.content,
        type=data.type,
    )
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return NoteResponse.model_validate(note)


@router.post("/researches/{research_id}/notes/from-journal", response_model=NoteResponse, status_code=status.HTTP_201_CREATED)
async def create_note_from_journal(
    research_id: uuid.UUID,
    data: NoteFromJournalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """FR-07d: satu aksi untuk menyimpan jurnal rekomendasi Mentor AI
    sebagai catatan tipe 'reference' — judul & isi otomatis dari metadata jurnal."""
    await get_owned_research(db, research_id, current_user)

    result = await db.execute(select(Journal).where(Journal.id == data.journal_id))
    journal = result.scalar_one_or_none()
    if journal is None:
        raise HTTPException(status_code=404, detail="Jurnal tidak ditemukan")

    parts = []
    if journal.authors:
        parts.append(f"Penulis: {journal.authors}")
    if journal.year:
        parts.append(f"Tahun: {journal.year}")
    if journal.doi:
        parts.append(f"DOI: {journal.doi}")
    if journal.url:
        parts.append(f"URL: {journal.url}")
    if journal.abstract:
        parts.append(f"\nAbstrak:\n{journal.abstract}")

    note = ResearchNote(
        research_id=research_id,
        user_id=current_user.id,
        journal_id=journal.id,
        title=journal.title[:300],
        content="\n".join(parts),
        type="reference",
    )
    db.add(note)
    await db.commit()
    await db.refresh(note)
    return NoteResponse.model_validate(note)


@router.get("/researches/{research_id}/notes", response_model=list[NoteResponse])
async def list_notes(
    research_id: uuid.UUID,
    type: str | None = Query(default=None, description="Filter: note|reference|writing|idea"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await get_owned_research(db, research_id, current_user)

    query = select(ResearchNote).where(ResearchNote.research_id == research_id)
    if type:
        query = query.where(ResearchNote.type == type)
    query = query.order_by(ResearchNote.updated_at.desc())

    result = await db.execute(query)
    notes = result.scalars().all()
    return [NoteResponse.model_validate(n) for n in notes]


async def _get_owned_note(db: AsyncSession, note_id: uuid.UUID, user: User) -> ResearchNote:
    result = await db.execute(
        select(ResearchNote).where(ResearchNote.id == note_id, ResearchNote.user_id == user.id)
    )
    note = result.scalar_one_or_none()
    if note is None:
        raise HTTPException(status_code=404, detail="Catatan tidak ditemukan")
    return note


@router.patch("/notes/{note_id}", response_model=NoteResponse)
async def update_note(
    note_id: uuid.UUID,
    data: NoteUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await _get_owned_note(db, note_id, current_user)

    if data.type is not None and data.type not in ("note", "reference", "writing", "idea"):
        raise HTTPException(status_code=400, detail="Tipe catatan tidak valid")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(note, field, value)

    await db.commit()
    await db.refresh(note)
    return NoteResponse.model_validate(note)


@router.delete("/notes/{note_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_note(
    note_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    note = await _get_owned_note(db, note_id, current_user)
    await db.delete(note)
    await db.commit()