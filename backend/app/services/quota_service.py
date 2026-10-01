# Pembatasan kuota harian per tier (FR-11, NFR-06).
#
# Tanpa tabel baru: pemakaian dihitung langsung dari data yang sudah ada —
# pesan user hari ini (mentor_messages via mentor_conversations) dan
# analisis hari ini (intelligence_analyses). Sederhana dan selalu akurat.
#
# Angka kuota di bawah masih sementara (model bisnis di BRD masih draft) —
# gampang diubah kapan saja tanpa menyentuh kode lain.

from datetime import datetime, time
from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.mentor_conversation import MentorConversation
from app.models.mentor_message import MentorMessage
from app.models.intelligence_analysis import IntelligenceAnalysis

# Kuota per hari per tier: (chat_mentor, analisis_intelligence)
# None = tanpa batas
DAILY_LIMITS: dict[str, dict[str, int | None]] = {
    "gratis":      {"mentor_chat": 10,   "intelligence": 3},
    "individu":    {"mentor_chat": 50,   "intelligence": 10},
    "profesional": {"mentor_chat": 200,  "intelligence": 30},
    "institusi":   {"mentor_chat": None, "intelligence": None},
}


def _today_start() -> datetime:
    """Awal hari ini (00:00) — batas bawah penghitungan pemakaian harian."""
    return datetime.combine(datetime.now().date(), time.min)


async def check_mentor_quota(db: AsyncSession, user: User) -> None:
    """Lempar HTTPException 429 kalau kuota chat mentor hari ini habis."""
    limit = DAILY_LIMITS.get(user.tier, DAILY_LIMITS["gratis"])["mentor_chat"]
    if limit is None:
        return

    result = await db.execute(
        select(func.count(MentorMessage.id))
        .join(MentorConversation, MentorMessage.conversation_id == MentorConversation.id)
        .where(
            MentorConversation.user_id == user.id,
            MentorMessage.role == "user",
            MentorMessage.created_at >= _today_start(),
        )
    )
    used = result.scalar_one()

    if used >= limit:
        raise HTTPException(
            status_code=429,
            detail=f"Kuota chat Mentor AI harian tier '{user.tier}' ({limit} pesan) sudah habis. "
                   "Coba lagi besok, atau upgrade akun untuk kuota lebih besar.",
        )


async def check_intelligence_quota(db: AsyncSession, user: User) -> None:
    """Lempar HTTPException 429 kalau kuota analisis Intelligence hari ini habis."""
    limit = DAILY_LIMITS.get(user.tier, DAILY_LIMITS["gratis"])["intelligence"]
    if limit is None:
        return

    result = await db.execute(
        select(func.count(IntelligenceAnalysis.id))
        .where(
            IntelligenceAnalysis.user_id == user.id,
            IntelligenceAnalysis.created_at >= _today_start(),
        )
    )
    used = result.scalar_one()

    if used >= limit:
        raise HTTPException(
            status_code=429,
            detail=f"Kuota analisis Intelligence harian tier '{user.tier}' ({limit} analisis) sudah habis. "
                   "Coba lagi besok, atau upgrade akun untuk kuota lebih besar.",
        )