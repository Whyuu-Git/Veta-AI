# Endpoint profil user yang sedang login: GET /users/me, PATCH /users/me/profile
# (dipakai frontend saat app dibuka ulang & saat submit setup wizard)

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.connection import get_db
from app.models.user import User
from app.schemas.user import UserProfileUpdateRequest, UserResponse
from app.core.deps import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)


@router.patch("/me/profile", response_model=UserResponse)
async def update_my_profile(
    data: UserProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Update cuma field yang benar-benar dikirim (tidak None)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(current_user, field, value)

    current_user.setup_complete = True  # wizard dianggap selesai setelah endpoint ini dipanggil
    await db.commit()
    await db.refresh(current_user)

    return UserResponse.model_validate(current_user)
