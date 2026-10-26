from datetime import datetime, timezone
from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_role
from app.api.ws import manager
from app.core.database import get_db
from app.models import (
    Delivery, Order, OrderStatus, Restaurant, Rider, RiderStatus, User, UserRole,
)
from app.schemas.rider import (
    AvailableJobOut, DeliveryOut, EarningsOut, RiderProfileIn,
    RiderProfileOut, RiderStatusIn,
)
from app.services.orders import transition_status

router = APIRouter(prefix="/riders", tags=["riders"])


async def _get_rider(db: AsyncSession, user_id: int) -> Rider | None:
    r = await db.execute(select(Rider).where(Rider.user_id == user_id))
    return r.scalar_one_or_none()


@router.post("/me", response_model=RiderProfileOut, status_code=201)
async def create_profile(data: RiderProfileIn, user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    existing = await _get_rider(db, user.id)
    if existing:
        raise HTTPException(400, "Rider profile already exists")
    rider = Rider(user_id=user.id, vehicle_type=data.vehicle_type, city=data.city, country=data.country, current_status=RiderStatus.offline)
    db.add(rider)
    await db.commit()
    await db.refresh(rider)
    return rider


@router.get("/me", response_model=RiderProfileOut)
async def get_profile(user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    rider = await _get_rider(db, user.id)
    if not rider:
        raise HTTPException(404, "Rider profile not created — POST /riders/me first")
    return rider


@router.patch("/me", response_model=RiderProfileOut)
async def update_profile(data: RiderStatusIn, user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    rider = await _get_rider(db, user.id)
    if not rider:
        raise HTTPException(404, "Rider profile not created")
    rider.current_status = data.current_status
    if data.lat is not None: rider.current_lat = data.lat
    if data.lng is not None: rider.current_lng = data.lng
    await db.commit()
    await db.refresh(rider)
    return rider


@router.get("/available", response_model=list[AvailableJobOut])
async def available(user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    rider = await _get_rider(db, user.id)
    if not rider:
        raise HTTPException(400, "Create rider profile first")
    r = await db.execute(
        select(Order).where(Order.status == OrderStatus.ready, Order.rider_id.is_(None)).order_by(Order.created_at)
    )
    orders = r.scalars().all()
    out = []
    for o in orders:
        rs_r = await db.execute(select(Restaurant).where(Restaurant.id == o.restaurant_id))
        rs = rs_r.scalar_one_or_none()
        out.append(AvailableJobOut(
            order_id=o.id, restaurant_id=o.restaurant_id,
            restaurant_name=rs.name if rs else "",
            address=o.address, city=o.city, total=o.total,
            currency=o.currency, created_at=o.created_at,
        ))
    return out


@router.post("/accept/{order_id}", response_model=DeliveryOut)
async def accept_delivery(order_id: int, user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    rider = await _get_rider(db, user.id)
    if not rider:
        raise HTTPException(400, "Create rider profile first")
    if rider.current_status != RiderStatus.available:
        raise HTTPException(400, "Set status to 'available' before accepting")

    r = await db.execute(select(Order).where(Order.id == order_id))
    order = r.scalar_one_or_none()
    if not order:
        raise HTTPException(404, "Order not found")
    if order.status != OrderStatus.ready:
        raise HTTPException(400, f"Order is '{order.status.value}', not 'ready'")
    if order.rider_id is not None:
        raise HTTPException(400, "Order already assigned")

    order.rider_id = rider.id
    rider.current_status = RiderStatus.busy
    # Don't change status to picked_up yet — the rider is just assigned. Restaurant still needs to see it as 'ready'.
    # Actually transition to 'picked_up' since rider is picking up
    order.status = OrderStatus.picked_up
    db.add(OrderStatusHistory(order_id=order.id, status=OrderStatus.picked_up, note=f"Rider {rider.id} accepted"))

    delivery = Delivery(
        order_id=order.id, rider_id=rider.id,
        pickup_time=datetime.now(timezone.utc),
        earnings=order.delivery_fee,
    )
    db.add(delivery)
    await db.commit()
    await db.refresh(delivery)

    await manager.broadcast(order.id, {"event": "rider_assigned", "order_id": order.id, "rider_id": rider.id})
    return delivery


@router.patch("/deliveries/{order_id}/complete", response_model=DeliveryOut)
async def complete_delivery(order_id: int, user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    rider = await _get_rider(db, user.id)
    if not rider:
        raise HTTPException(400, "Create rider profile first")
    r = await db.execute(select(Order).where(Order.id == order_id))
    order = r.scalar_one_or_none()
    if not order or order.rider_id != rider.id:
        raise HTTPException(404, "Order not assigned to you")

    d_r = await db.execute(select(Delivery).where(Delivery.order_id == order_id))
    delivery = d_r.scalar_one_or_none()
    if not delivery:
        raise HTTPException(404, "Delivery not found")

    await transition_status(db, order, OrderStatus.delivered, "Delivered")
    delivery.dropoff_time = datetime.now(timezone.utc)
    rider.current_status = RiderStatus.available
    await db.commit()
    await db.refresh(delivery)

    await manager.broadcast(order.id, {"event": "status_changed", "order_id": order.id, "status": "delivered"})
    return delivery


@router.get("/earnings", response_model=EarningsOut)
async def earnings(user: User = Depends(require_role(UserRole.rider)), db: AsyncSession = Depends(get_db)):
    rider = await _get_rider(db, user.id)
    if not rider:
        raise HTTPException(400, "Create rider profile first")
    r = await db.execute(select(Delivery).where(Delivery.rider_id == rider.id).order_by(Delivery.created_at.desc()))
    deliveries = r.scalars().all()
    total = sum((d.earnings for d in deliveries), Decimal("0"))
    return EarningsOut(total_earnings=total, currency="USD", deliveries=deliveries)
