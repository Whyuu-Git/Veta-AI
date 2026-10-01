# Pydantic schema (request/response) untuk fitur "mentor" (chat AI).

import uuid
from datetime import datetime
from pydantic import BaseModel

from app.schemas.journal import JournalResponse


class ConversationCreateRequest(BaseModel):
    research_id: uuid.UUID
    title: str | None = None


class ConversationResponse(BaseModel):
    id: uuid.UUID
    research_id: uuid.UUID
    title: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class MessageSendRequest(BaseModel):
    content: str


class MessageResponse(BaseModel):
    id: uuid.UUID
    role: str  # 'user' | 'assistant'
    content: str
    created_at: datetime
    # Jurnal yang disitasi Mentor AI di pesan ini (FR-07c) —
    # kosong untuk pesan biasa tanpa pencarian literatur
    journals: list[JournalResponse] = []

    class Config:
        from_attributes = True