# Endpoint Mentor AI (FR-06 & FR-07 di BRD):
# - buat/lihat sesi percakapan per riset
# - kirim pesan -> disimpan -> LLM dipanggil dengan konteks riset + riwayat
#   -> balasan disimpan & dikirim balik ke frontend
#
# CATATAN: pemanggilan LLM di sini masih sinkron/blocking (menunggu balasan
# penuh, belum streaming). Cukup untuk MVP; efek streaming (NFR-04) bisa
# ditambah nanti setelah alur dasarnya stabil.

import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from google.genai import errors as genai_errors

from app.database.connection import get_db
from app.models.user import User
from app.models.mentor_conversation import MentorConversation
from app.models.mentor_message import MentorMessage
from app.models.journal import Journal, mentor_message_journals
from app.schemas.journal import JournalResponse
from app.schemas.mentor import (
    ConversationCreateRequest,
    ConversationResponse,
    MessageSendRequest,
    MessageResponse,
)
from app.core.deps import get_current_user
from app.routers.researches import get_owned_research
from app.services.llm_service import LlmService
from app.services.quota_service import check_mentor_quota

router = APIRouter(prefix="/mentor", tags=["mentor"])

llm_service = LlmService()


@router.post("/conversations", response_model=ConversationResponse, status_code=status.HTTP_201_CREATED)
async def create_conversation(
    data: ConversationCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Pastikan risetnya milik user ini (sekaligus validasi research_id benar)
    await get_owned_research(db, data.research_id, current_user)

    conversation = MentorConversation(
        research_id=data.research_id,
        user_id=current_user.id,
        title=data.title or "Percakapan baru",
    )
    db.add(conversation)
    await db.commit()
    await db.refresh(conversation)
    return ConversationResponse.model_validate(conversation)


@router.get("/conversations", response_model=list[ConversationResponse])
async def list_conversations(
    research_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await get_owned_research(db, research_id, current_user)

    result = await db.execute(
        select(MentorConversation)
        .where(MentorConversation.research_id == research_id)
        .order_by(MentorConversation.updated_at.desc())
    )
    conversations = result.scalars().all()
    return [ConversationResponse.model_validate(c) for c in conversations]


async def _get_owned_conversation(
    db: AsyncSession, conversation_id: uuid.UUID, user: User
) -> MentorConversation:
    result = await db.execute(
        select(MentorConversation).where(
            MentorConversation.id == conversation_id,
            MentorConversation.user_id == user.id,
        )
    )
    conversation = result.scalar_one_or_none()
    if conversation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Percakapan tidak ditemukan")
    return conversation


@router.get("/conversations/{conversation_id}/messages", response_model=list[MessageResponse])
async def list_messages(
    conversation_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_owned_conversation(db, conversation_id, current_user)

    result = await db.execute(
        select(MentorMessage)
        .where(MentorMessage.conversation_id == conversation_id)
        .order_by(MentorMessage.created_at.asc())
    )
    messages = result.scalars().all()
    return [MessageResponse.model_validate(m) for m in messages]


@router.post("/conversations/{conversation_id}/messages", response_model=MessageResponse)
async def send_message(
    conversation_id: uuid.UUID,
    data: MessageSendRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conversation = await _get_owned_conversation(db, conversation_id, current_user)
    research = await get_owned_research(db, conversation.research_id, current_user)

    # Cek kuota harian tier sebelum memproses (FR-11) — ditolak 429 kalau habis
    await check_mentor_quota(db, current_user)

    # 1. Ambil riwayat pesan sebelumnya (untuk konteks LLM)
    result = await db.execute(
        select(MentorMessage)
        .where(MentorMessage.conversation_id == conversation_id)
        .order_by(MentorMessage.created_at.asc())
    )
    history = [{"role": m.role, "content": m.content} for m in result.scalars().all()]

    # 2. Simpan pesan user
    user_message = MentorMessage(conversation_id=conversation_id, role="user", content=data.content)
    db.add(user_message)
    await db.commit()

    # 3. Panggil LLM — mengembalikan (teks, jurnal yang ditemukan)
    try:
        reply_text, found_journals = llm_service.generate_reply(
            user_message=data.content,
            research_context={
                "title": research.title,
                "field": research.field,
                "current_stage": research.current_stage,
            },
            chat_history=history,
        )
    except genai_errors.ClientError as e:
        if e.code == 429:
            raise HTTPException(
                status_code=429,
                detail="Mentor AI sedang sibuk (batas kuota per menit tercapai). Tunggu sebentar lalu coba lagi.",
            )
        raise

    # 4. Simpan balasan asisten
    assistant_message = MentorMessage(
        conversation_id=conversation_id, role="assistant", content=reply_text
    )
    db.add(assistant_message)
    await db.commit()
    await db.refresh(assistant_message)

    # 5. Simpan jurnal hasil pencarian ke tabel journals (cache) dan
    #    tautkan ke pesan ini (mentor_message_journals) untuk sitasi.
    #    Hanya jurnal yang BENAR-BENAR DISEBUT Gemini di jawaban yang
    #    disimpan sebagai sitasi.
    saved_journals: list[Journal] = []
    seen_keys: set[str] = set()
    reply_lower = reply_text.lower()
    for j in found_journals:
        # Filter relevansi: judul harus benar-benar disebut di jawaban.
        # Untuk judul pendek/generik (mis. "Natural language processing"),
        # frasanya bisa muncul kebetulan di kalimat biasa — jadi khusus
        # judul < 35 karakter, wajib muncul dalam tanda kutip.
        title_lower = j["title"].lower()
        if title_lower[:60] not in reply_lower:
            continue
        if len(title_lower) < 35 and f'"{title_lower}"' not in reply_lower:
            continue

        # Lewati duplikat dalam satu balasan
        key = j.get("doi") or j["title"]
        if key in seen_keys:
            continue
        seen_keys.add(key)

        # Cek dulu apakah jurnal ini sudah pernah tersimpan (dedup by DOI/judul)
        if j.get("doi"):
            existing = await db.execute(select(Journal).where(Journal.doi == j["doi"]))
        else:
            existing = await db.execute(select(Journal).where(Journal.title == j["title"]))
        journal = existing.scalar_one_or_none()

        if journal is None:
            journal = Journal(
                title=j["title"],
                authors=j.get("authors"),
                source=j["source"],
                year=j.get("year"),
                citation_count=j.get("citation_count", 0),
                doi=j.get("doi"),
                url=j.get("url"),
                abstract=j.get("abstract"),
            )
            db.add(journal)
            await db.flush()  # supaya journal.id terisi sebelum dipakai di bawah

        await db.execute(
            pg_insert(mentor_message_journals)
            .values(message_id=assistant_message.id, journal_id=journal.id)
            .on_conflict_do_nothing()
        )
        saved_journals.append(journal)

    await db.commit()

    # 6. Kirim balasan + sitasi ke frontend
    response = MessageResponse.model_validate(assistant_message)
    response.journals = [JournalResponse.model_validate(j) for j in saved_journals]
    return response