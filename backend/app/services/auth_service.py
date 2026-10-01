# Logika register/login, verifikasi user. Router tidak boleh langsung
# akses database — selalu lewat service ini.

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import UserRegisterRequest, UserLoginRequest
from app.core.security import hash_password, verify_password, create_access_token


class AuthError(Exception):
    """Dilempar kalau email sudah dipakai, atau email/password salah saat login."""
    pass


async def register_user(db: AsyncSession, data: UserRegisterRequest) -> tuple[User, str]:
    existing = await db.execute(select(User).where(User.email == data.email))
    if existing.scalar_one_or_none():
        raise AuthError("Email sudah terdaftar")

    user = User(
        name=data.name,
        email=data.email,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(str(user.id))
    return user, token


async def login_user(db: AsyncSession, data: UserLoginRequest) -> tuple[User, str]:
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        # Pesannya sengaja tidak dibedakan (email salah vs password salah)
        # supaya orang luar tidak bisa menebak email mana yang terdaftar
        raise AuthError("Email atau password salah")

    token = create_access_token(str(user.id))
    return user, token


async def get_user_by_id(db: AsyncSession, user_id: str) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()
