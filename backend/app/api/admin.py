from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import require_role
from app.core.database import get_db
from app.core.security import hash_password
from app.models import Order, OrderStatus, PlatformSetting, Restaurant, RestaurantStatus, User, UserRole
from app.schemas.admin import AdminUserOut, ReportsOut, SettingIn, SettingOut
from app.schemas.restaurant import RestaurantOut

router = APIRouter(prefix="/admin", tags=["admin"])

# --- RESTAURANTS ---
@router.get("/restaurants", response_model=list[RestaurantOut])
async def get_all_restaurants(user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Restaurant).order_by(Restaurant.created_at.desc()))
    return r.scalars().all()

@router.get("/restaurants/pending")
async def pending_restaurants(user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Restaurant).where(Restaurant.status == RestaurantStatus.pending))
    return r.scalars().all()

@router.patch("/restaurants/{rid}/approve")
async def approve_restaurant(rid: int, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Restaurant).where(Restaurant.id == rid))
    rs = r.scalar_one_or_none()
    if not rs: raise HTTPException(404, "Restaurant not found")
    rs.status = RestaurantStatus.approved
    await db.commit()
    await db.refresh(rs)
    return rs

@router.patch("/restaurants/{rid}/suspend")
async def suspend_restaurant(rid: int, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Restaurant).where(Restaurant.id == rid))
    rs = r.scalar_one_or_none()
    if not rs: raise HTTPException(404, "Restaurant not found")
    rs.status = RestaurantStatus.suspended
    await db.commit()
    await db.refresh(rs)
    return rs

@router.delete("/restaurants/{rid}", status_code=204)
async def delete_restaurant(rid: int, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Restaurant).where(Restaurant.id == rid))
    rs = r.scalar_one_or_none()
    if not rs: raise HTTPException(404, "Restaurant not found")
    await db.delete(rs)
    await db.commit()

# --- USERS ---
@router.get("/users", response_model=list[AdminUserOut])
async def list_users(user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(User).order_by(User.id))
    return r.scalars().all()

@router.post("/users", response_model=AdminUserOut)
async def admin_create_user(data: dict, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.phone == data['phone']))
    if existing.scalar_one_or_none():
        raise HTTPException(400, "Phone already registered")
    new_user = User(
        phone=data['phone'], password_hash=hash_password(data['password']),
        full_name=data['full_name'], role=UserRole(data['role']), is_active=True
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.patch("/users/{uid}/deactivate")
async def deactivate_user(uid: int, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(User).where(User.id == uid))
    u = r.scalar_one_or_none()
    if not u: raise HTTPException(404, "User not found")
    if u.id == user.id: raise HTTPException(400, "Cannot deactivate self")
    u.is_active = False
    await db.commit()
    return {"ok": True, "id": uid, "is_active": False}

@router.patch("/users/{uid}/activate")
async def activate_user(uid: int, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(User).where(User.id == uid))
    u = r.scalar_one_or_none()
    if not u: raise HTTPException(404, "User not found")
    u.is_active = True
    await db.commit()
    return {"ok": True, "id": uid, "is_active": True}

@router.delete("/users/{uid}", status_code=204)
async def delete_user(uid: int, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(User).where(User.id == uid))
    u = r.scalar_one_or_none()
    if not u: raise HTTPException(404, "User not found")
    if u.id == user.id: raise HTTPException(400, "Cannot delete self")
    await db.delete(u)
    await db.commit()

# --- SETTINGS & REPORTS ---
@router.get("/settings", response_model=list[SettingOut])
async def list_settings(user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(PlatformSetting).order_by(PlatformSetting.key))
    return r.scalars().all()

@router.put("/settings", response_model=SettingOut)
async def upsert_setting(data: SettingIn, user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(PlatformSetting).where(PlatformSetting.key == data.key))
    s = r.scalar_one_or_none()
    if s: s.value = data.value
    else:
        s = PlatformSetting(key=data.key, value=data.value)
        db.add(s)
    await db.commit()
    await db.refresh(s)
    return s

@router.get("/reports", response_model=ReportsOut)
async def reports(user: User = Depends(require_role(UserRole.admin)), db: AsyncSession = Depends(get_db)):
    total_users = (await db.execute(select(func.count()).select_from(User))).scalar() or 0
    total_customers = (await db.execute(select(func.count()).select_from(User).where(User.role == UserRole.customer))).scalar() or 0
    total_restaurants = (await db.execute(select(func.count()).select_from(Restaurant))).scalar() or 0
    total_riders = (await db.execute(select(func.count()).select_from(User).where(User.role == UserRole.rider))).scalar() or 0
    total_orders = (await db.execute(select(func.count()).select_from(Order))).scalar() or 0
    total_delivered = (await db.execute(select(func.count()).select_from(Order).where(Order.status == OrderStatus.delivered))).scalar() or 0
    pending = (await db.execute(select(func.count()).select_from(Restaurant).where(Restaurant.status == RestaurantStatus.pending))).scalar() or 0
    revenue = (await db.execute(select(func.coalesce(func.sum(Order.total), 0)).where(Order.status == OrderStatus.delivered))).scalar() or 0
    return ReportsOut(
        total_users=total_users, total_customers=total_customers,
        total_restaurants=total_restaurants, total_riders=total_riders,
        total_orders=total_orders, total_delivered=total_delivered,
        total_revenue=str(revenue), pending_restaurants=pending,
    )
