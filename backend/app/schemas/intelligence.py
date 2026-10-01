# Pydantic schema (request/response) untuk fitur "intelligence" (analisis AI).

import uuid
from datetime import datetime
from pydantic import BaseModel


class IntelligenceResponse(BaseModel):
    id: uuid.UUID
    research_id: uuid.UUID

    health_score: int | None          # 0-100, kesehatan riset keseluruhan
    publication_readiness: int | None # 0-100, kesiapan publikasi

    gap_analysis: str | None
    novelty_assessment: str | None
    strengths: list[str] | None
    weaknesses: list[str] | None
    recommendations: list[str] | None

    created_at: datetime

    class Config:
        from_attributes = True