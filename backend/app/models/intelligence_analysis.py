# Model SQLAlchemy untuk tabel "intelligence_analyses" (lihat database_schema.sql).

import uuid
from datetime import datetime
from sqlalchemy import Text, SmallInteger, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base


class IntelligenceAnalysis(Base):
    __tablename__ = "intelligence_analyses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    research_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("researches.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    health_score: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    publication_readiness: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)

    gap_analysis: Mapped[str | None] = mapped_column(Text, nullable=True)
    novelty_assessment: Mapped[str | None] = mapped_column(Text, nullable=True)
    strengths: Mapped[list | None] = mapped_column(JSONB, nullable=True)        # array string
    weaknesses: Mapped[list | None] = mapped_column(JSONB, nullable=True)       # array string
    recommendations: Mapped[list | None] = mapped_column(JSONB, nullable=True)  # array string

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())