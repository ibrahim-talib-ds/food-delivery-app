from decimal import Decimal
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import (
    Cart, MenuItem, Order, OrderItem, OrderStatus, OrderStatusHistory,
    Restaurant, RestaurantStatus, User, UserRole
)
from app.models.notification import Notification

ALLOWED_TRANSITIONS: dict[OrderStatus, set[OrderStatus]] = {
    OrderStatus.pending:    {OrderStatus.accepted, OrderStatus.cancelled},
    OrderStatus.accepted:   {OrderStatus.preparing, OrderStatus.cancelled},
    OrderStatus.preparing:  {OrderStatus.ready, OrderStatus.cancelled},
    OrderStatus.ready:      {OrderStatus.picked_up, OrderStatus.cancelled},
    OrderStatus.picked_up:  {OrderStatus.delivered},
    OrderStatus.delivered:  set(),
    OrderStatus.cancelled:  set(),
}


async def create_order_from_cart(db: AsyncSession, customer_id: int, data) -> Order:
    r = await db.execute(
        select(Cart).where(Cart.customer_id == customer_id).options(selectinload(Cart.items))
    )
    cart = r.scalar_one_or_none()
    if not cart or not cart.items:
        raise HTTPException(400, "Cart is empty")
    if not cart.restaurant_id:
        raise HTTPException(400, "Cart has no restaurant")

    rs_r = await db.execute(select(Restaurant).where(Restaurant.id == cart.restaurant_id))
    rs = rs_r.scalar_one_or_none()
    if not rs or rs.status != RestaurantStatus.approved:
        raise HTTPException(400, "Restaurant not available")

    order = Order(
        customer_id=customer_id,
        restaurant_id=cart.restaurant_id,
        status=OrderStatus.pending,
        address=data.address,
        city=data.city or rs.city,
        country=data.country or rs.country,
        lat=data.lat,
        lng=data.lng,
        note=data.note,
        currency=rs.currency,
        delivery_fee=rs.delivery_fee,
    )
    db.add(order)
    await db.flush()

    subtotal = Decimal("0")
    for ci in cart.items:
        mi_r = await db.execute(select(MenuItem).where(MenuItem.id == ci.menu_item_id))
        mi = mi_r.scalar_one_or_none()
        if not mi:
            continue
        line = mi.price * ci.quantity
        subtotal += line
        db.add(OrderItem(
            order_id=order.id, menu_item_id=mi.id,
            name_snapshot=mi.name, price_snapshot=mi.price, quantity=ci.quantity,
        ))

    order.subtotal = subtotal
    order.total = subtotal + rs.delivery_fee
    db.add(OrderStatusHistory(order_id=order.id, status=OrderStatus.pending, note="Order placed"))
    
    # Notify owner safely
    if rs.owner_id:
        db.add(Notification(
            user_id=rs.owner_id, 
            title="New Order!", 
            body=f"Order #{order.id} received.", 
            type="order", 
            reference_id=order.id
        ))

    for ci in cart.items:
        await db.delete(ci)
    cart.restaurant_id = None

    await db.commit()
    await db.refresh(order)
    return order


async def transition_status(db: AsyncSession, order: Order, new_status: OrderStatus, note: str | None = None) -> Order:
    if new_status not in ALLOWED_TRANSITIONS.get(order.status, set()):
        raise HTTPException(400, f"Cannot transition {order.status.value} → {new_status.value}")
    order.status = new_status
    db.add(OrderStatusHistory(order_id=order.id, status=new_status, note=note))
    
    if new_status == OrderStatus.ready:
        riders = await db.execute(select(User.id).where(User.role == UserRole.rider, User.is_active == True))
        for rider_id in riders.scalars().all():
            db.add(Notification(
                user_id=rider_id, 
                title="New Job Available", 
                body=f"Order #{order.id} is ready for pickup.", 
                type="order", 
                reference_id=order.id
            ))
            
    await db.commit()
    await db.refresh(order)
    return order
