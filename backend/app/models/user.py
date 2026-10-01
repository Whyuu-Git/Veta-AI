# Model SQLAlchemy untuk tabel "users" (lihat database_schema.sql).
# Class ini merepresentasikan tabel di database — tiap atribut = 1 kolom.

import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    email: Mapped[str] = mapped_column(String(150), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)

    # Profil akademik (diisi saat setup wizard)
    role: Mapped[str | None] = mapped_column(String(30), nullable=True)
    university: Mapped[str | None] = mapped_column(String(200), nullable=True)
    faculty: Mapped[str | None] = mapped_column(String(150), nullable=True)
    major: Mapped[str | None] = mapped_column(String(150), nullable=True)

    # Preferensi AI
    ai_language: Mapped[str] = mapped_column(String(30), default="id")
    writing_style: Mapped[str] = mapped_column(String(30), default="formal")
    academic_tone: Mapped[str] = mapped_column(String(30), default="suportif")

    tier: Mapped[str] = mapped_column(String(30), default="gratis")
    setup_complete: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())