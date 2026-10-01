# Model SQLAlchemy untuk tabel "researches" (lihat database_schema.sql).

import uuid
from datetime import datetime
from sqlalchemy import String, Text, SmallInteger, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base


class Research(Base):
    __tablename__ = "researches"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    title: Mapped[str] = mapped_column(String(300), nullable=False)
    field: Mapped[str | None] = mapped_column(String(150), nullable=True)
    topic: Mapped[str | None] = mapped_column(String(300), nullable=True)
    keywords: Mapped[list | None] = mapped_column(JSONB, nullable=True)  # array string
    goal: Mapped[str | None] = mapped_column(Text, nullable=True)
    abstract: Mapped[str | None] = mapped_column(Text, nullable=True)

    current_stage: Mapped[str] = mapped_column(String(30), default="ide")
    progress_percentage: Mapped[int] = mapped_column(SmallInteger, default=0)

    citation_style: Mapped[str | None] = mapped_column(String(20), default="APA")
    status: Mapped[str] = mapped_column(String(20), default="active")

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
