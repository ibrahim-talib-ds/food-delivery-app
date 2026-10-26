from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, require_role
from app.api.ws import manager
from app.core.database import get_db
from app.models import Order, OrderStatus, Restaurant, User, UserRole
from app.schemas.order import OrderCreateIn, OrderOut, OrderStatusIn
from app.services.orders import create_order_from_cart, transition_status

router = APIRouter(prefix="/orders", tags=["orders"])


def _load():
    return select(Order).options(selectinload(Order.items), selectinload(Order.status_history))


@router.post("", response_model=OrderOut, status_code=201)
async def create_order(data: OrderCreateIn, user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    order = await create_order_from_cart(db, user.id, data)
    r = await db.execute(_load().where(Order.id == order.id))
    return r.scalar_one()


@router.get("", response_model=list[OrderOut])
async def my_orders(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    q = _load().order_by(Order.created_at.desc())
    if user.role == UserRole.customer:
        q = q.where(Order.customer_id == user.id)
    elif user.role == UserRole.restaurant_owner:
        rs_r = await db.execute(select(Restaurant).where(Restaurant.owner_id == user.id))
        rs = rs_r.scalar_one_or_none()
        if not rs:
            return []
        q = q.where(Order.restaurant_id == rs.id)
    elif user.role == UserRole.rider:
        return []
    r = await db.execute(q)
    return r.scalars().all()


@router.get("/{oid}", response_model=OrderOut)
async def get_order(oid: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(_load().where(Order.id == oid))
    order = r.scalar_one_or_none()
    if not order:
        raise HTTPException(404, "Order not found")
    if user.role == UserRole.customer and order.customer_id != user.id:
        raise HTTPException(403, "Not your order")
    if user.role == UserRole.restaurant_owner:
        rs_r = await db.execute(select(Restaurant).where(Restaurant.owner_id == user.id))
        rs = rs_r.scalar_one_or_none()
        if not rs or order.restaurant_id != rs.id:
            raise HTTPException(403, "Not your restaurant's order")
    return order


@router.patch("/{oid}/status", response_model=OrderOut)
async def update_status(oid: int, data: OrderStatusIn, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(_load().where(Order.id == oid))
    order = r.scalar_one_or_none()
    if not order:
        raise HTTPException(404, "Order not found")

    if user.role == UserRole.restaurant_owner:
        rs_r = await db.execute(select(Restaurant).where(Restaurant.owner_id == user.id))
        rs = rs_r.scalar_one_or_none()
        if not rs or order.restaurant_id != rs.id:
            raise HTTPException(403, "Not your restaurant's order")
    elif user.role == UserRole.customer:
        if order.customer_id != user.id:
            raise HTTPException(403, "Not your order")
        if data.status != OrderStatus.cancelled:
            raise HTTPException(403, "Customers can only cancel")

    await transition_status(db, order, data.status, data.note)
    r = await db.execute(_load().where(Order.id == oid))
    order = r.scalar_one()
    await manager.broadcast(oid, {"event": "status_changed", "order_id": oid, "status": order.status.value})
    return order
