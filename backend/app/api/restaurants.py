from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_role
from app.core.database import get_db
from app.models import Restaurant, RestaurantStatus, User, UserRole
from app.schemas.restaurant import (
    RestaurantIn, RestaurantOut, RestaurantUpdate, StatusUpdate,
)

router = APIRouter(prefix="/restaurants", tags=["restaurants"])


@router.get("", response_model=list[RestaurantOut])
async def list_restaurants(
    city: str | None = None,
    country: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    q = select(Restaurant).where(Restaurant.status == RestaurantStatus.approved)
    if city:
        q = q.where(Restaurant.city.ilike(f"%{city}%"))
    if country:
        q = q.where(Restaurant.country.ilike(f"%{country}%"))
    q = q.order_by(Restaurant.name)
    r = await db.execute(q)
    return r.scalars().all()


@router.get("/{rid}", response_model=RestaurantOut)
async def get_restaurant(rid: int, db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Restaurant).where(Restaurant.id == rid))
    obj = r.scalar_one_or_none()
    if not obj:
        raise HTTPException(404, "Restaurant not found")
    return obj


@router.post("", response_model=RestaurantOut, status_code=201)
async def create_restaurant(
    data: RestaurantIn,
    user: User = Depends(require_role(UserRole.restaurant_owner)),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(select(Restaurant).where(Restaurant.owner_id == user.id))
    if existing.scalar_one_or_none():
        raise HTTPException(400, "You already have a restaurant")
    obj = Restaurant(owner_id=user.id, **data.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


async def _own_restaurant(rid: int, user: User, db: AsyncSession) -> Restaurant:
    r = await db.execute(select(Restaurant).where(Restaurant.id == rid))
    obj = r.scalar_one_or_none()
    if not obj:
        raise HTTPException(404, "Restaurant not found")
    if obj.owner_id != user.id and user.role != UserRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your restaurant")
    return obj


@router.patch("/{rid}", response_model=RestaurantOut)
async def update_restaurant(
    rid: int,
    data: RestaurantUpdate,
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    obj = await _own_restaurant(rid, user, db)
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.patch("/{rid}/status", response_model=RestaurantOut)
async def set_status(
    rid: int,
    data: StatusUpdate,
    user: User = Depends(require_role(UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    obj = await _own_restaurant(rid, user, db)
    obj.status = data.status
    await db.commit()
    await db.refresh(obj)
    return obj
