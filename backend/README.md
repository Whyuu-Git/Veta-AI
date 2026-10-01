# Backend — AI Research Companion

Backend FastAPI untuk aplikasi AI Research Companion.

## Struktur folder
- app/core       -> konfigurasi & keamanan (JWT)
- app/database   -> koneksi & base model database
- app/models     -> model SQLAlchemy (1:1 dengan database_schema.sql)
- app/schemas    -> skema request/response (Pydantic)
- app/routers    -> endpoint API per fitur
- app/services   -> business logic (LLM, pencarian jurnal, PDF, auth)
- alembic        -> migration database
- tests          -> unit test

Status: struktur dasar saja, implementasi kode menyusul.
