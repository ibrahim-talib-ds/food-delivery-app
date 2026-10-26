from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password, verify_password
from app.models import User, UserRole


async def register_user(db: AsyncSession, data) -> User:
    existing = await db.execute(select(User).where(User.phone == data.phone))
    if existing.scalar_one_or_none():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Phone already registered")

    if data.email:
        e = await db.execute(select(User).where(User.email == data.email))
        if e.scalar_one_or_none():
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Email already registered")

    # Never allow self-registration as admin via API — force customer/owner/rider
    role = data.role if data.role in (UserRole.customer, UserRole.restaurant_owner, UserRole.rider) else UserRole.customer

    user = User(
        phone=data.phone,
        email=data.email,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
        role=role,
        city=data.city,
        country=data.country,
        language_pref=data.language_pref,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def authenticate(db: AsyncSession, phone: str, password: str) -> User:
    r = await db.execute(select(User).where(User.phone == phone))
    user = r.scalar_one_or_none()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid phone or password")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account disabled")
    return user
