# Pydantic schema (request/response) untuk fitur "research notes".

import uuid
from datetime import datetime
from pydantic import BaseModel


class NoteCreateRequest(BaseModel):
    title: str
    content: str | None = None
    type: str = "note"  # note | reference | writing | idea


class NoteUpdateRequest(BaseModel):
    title: str | None = None
    content: str | None = None
    type: str | None = None


# Untuk FR-07d: simpan jurnal rekomendasi Mentor sebagai catatan reference
class NoteFromJournalRequest(BaseModel):
    journal_id: uuid.UUID


class NoteResponse(BaseModel):
    id: uuid.UUID
    research_id: uuid.UUID
    journal_id: uuid.UUID | None
    title: str
    content: str | None
    type: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True