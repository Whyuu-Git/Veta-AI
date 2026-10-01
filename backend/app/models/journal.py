# Model SQLAlchemy untuk tabel "journals" + tabel penghubung
# "mentor_message_journals" (lihat database_schema.sql).

import uuid
from datetime import datetime
from sqlalchemy import String, Text, Integer, DateTime, ForeignKey, Table, Column, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base

# Tabel penghubung many-to-many: pesan mentor <-> jurnal yang disitasi.
# Didefinisikan sebagai Table biasa (bukan class) karena isinya cuma 2 FK.
mentor_message_journals = Table(
    "mentor_message_journals",
    Base.metadata,
    Column("message_id", UUID(as_uuid=True),
           ForeignKey("mentor_messages.id", ondelete="CASCADE"), primary_key=True),
    Column("journal_id", UUID(as_uuid=True),
           ForeignKey("journals.id", ondelete="CASCADE"), primary_key=True),
)


class Journal(Base):
    __tablename__ = "journals"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    authors: Mapped[str | None] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(String(30), nullable=False)
    year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    field: Mapped[str | None] = mapped_column(String(150), nullable=True)
    citation_count: Mapped[int | None] = mapped_column(Integer, default=0)
    doi: Mapped[str | None] = mapped_column(String(150), nullable=True)
    url: Mapped[str | None] = mapped_column(Text, nullable=True)
    abstract: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())