# Endpoint API untuk register, login. Path di sini HARUS cocok dengan
# yang dipanggil auth_service.dart di frontend.

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.schemas.user import (
    UserRegisterRequest,
    UserLoginRequest,
    UserResponse,
    AuthResponse,
)
from app.services.auth_service import register_user, login_user, AuthError

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse)
async def register(data: UserRegisterRequest, db: AsyncSession = Depends(get_db)):
    try:
        user, token = await register_user(db, data)
    except AuthError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return AuthResponse(access_token=token, user=UserResponse.model_validate(user))


@router.post("/login", response_model=AuthResponse)
async def login(data: UserLoginRequest, db: AsyncSession = Depends(get_db)):
    try:
        user, token = await login_user(db, data)
    except AuthError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))

    return AuthResponse(access_token=token, user=UserResponse.model_validate(user))
