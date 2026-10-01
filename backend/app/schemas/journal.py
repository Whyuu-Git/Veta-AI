# Pydantic schema (request/response) untuk data jurnal.

import uuid
from pydantic import BaseModel


class JournalResponse(BaseModel):
    id: uuid.UUID
    title: str
    authors: str | None
    source: str
    year: int | None
    citation_count: int | None
    doi: str | None
    url: str | None

    class Config:
        from_attributes = True