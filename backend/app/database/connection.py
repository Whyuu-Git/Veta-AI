# Koneksi ke PostgreSQL, pakai SQLAlchemy versi async + driver asyncpg.
#
# CATATAN PENTING soal DATABASE_URL di .env:
# asyncpg butuh format "postgresql+asyncpg://...", bukan "postgresql://...".
# Supaya kamu tidak perlu ubah .env manual, kode di bawah otomatis
# menambahkan "+asyncpg" kalau belum ada.

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.core.config import settings

def _to_async_url(url: str) -> str:
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return url

engine = create_async_engine(_to_async_url(settings.database_url), echo=False)

# Pabrik untuk membuat sesi database baru tiap ada request masuk
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


# Dependency FastAPI: dipakai di router lewat Depends(get_db),
# otomatis buka sesi database di awal request dan tutup lagi di akhir.
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session