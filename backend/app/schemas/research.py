# Pydantic schema (request/response) untuk fitur "research".

import uuid
from datetime import datetime
from pydantic import BaseModel, Field


# Data yang dikirim frontend saat BUAT riset baru
class ResearchCreateRequest(BaseModel):
    title: str
    field: str | None = None
    topic: str | None = None
    keywords: list[str] = []
    goal: str | None = None
    citation_style: str = "APA"


# Data yang dikirim frontend saat UPDATE riset (semua opsional —
# cuma field yang dikirim yang diubah)
class ResearchUpdateRequest(BaseModel):
    title: str | None = None
    field: str | None = None
    topic: str | None = None
    keywords: list[str] | None = None
    goal: str | None = None
    abstract: str | None = None
    current_stage: str | None = None
    progress_percentage: int | None = Field(default=None, ge=0, le=100)
    citation_style: str | None = None
    status: str | None = None


# Bentuk data riset yang dikirim BALIK ke frontend
class ResearchResponse(BaseModel):
    id: uuid.UUID
    title: str
    field: str | None
    topic: str | None
    keywords: list[str] | None
    goal: str | None
    abstract: str | None
    current_stage: str
    progress_percentage: int
    citation_style: str | None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
