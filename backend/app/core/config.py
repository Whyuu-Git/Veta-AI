# Konfigurasi aplikasi (env variables): DATABASE_URL, JWT_SECRET, LLM_API_KEY, dll.
#
# Pakai pydantic-settings supaya otomatis baca file .env dan langsung dapat
# validasi tipe data (kalau ada yang lupa diisi, error-nya jelas saat startup,
# bukan baru ketahuan pas fitur dipakai).

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    llm_api_key: str

    # model_config (bukan "class Config") adalah cara pydantic v2 mengatur
    # dari mana env variable dibaca. env_file=".env" artinya dicari relatif
    # terhadap folder tempat kamu MENJALANKAN perintah (folder "backend"),
    # jadi pastikan file .env memang ada langsung di dalam folder backend/,
    # sejajar dengan folder app/ -- bukan di dalam app/.
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


# Dipanggil sekali, dipakai di seluruh aplikasi lewat: from app.core.config import settings
settings = Settings()
