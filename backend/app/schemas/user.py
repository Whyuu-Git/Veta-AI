# Pydantic schema untuk fitur "user" — beda dengan model SQLAlchemy di atas.
#
# Bedanya: models/user.py = bentuk tabel di DATABASE.
#          schemas/user.py = bentuk data yang keluar-masuk lewat API (JSON).

import uuid
from pydantic import BaseModel, EmailStr


class UserRegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserProfileUpdateRequest(BaseModel):
    role: str | None = None
    university: str | None = None
    faculty: str | None = None
    major: str | None = None
    writing_style: str | None = None
    academic_tone: str | None = None


class UserResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    role: str | None
    university: str | None
    faculty: str | None
    major: str | None
    ai_language: str
    writing_style: str
    academic_tone: str
    tier: str
    setup_complete: bool

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    access_token: str
    user: UserResponse