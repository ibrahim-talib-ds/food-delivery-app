from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, or_, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models import User, Order, Restaurant, Rider
from app.models.notification import Notification, Message

router = APIRouter(tags=["communications"])


# ─── NOTIFICATIONS ───
@router.get("/notifications")
async def get_notifications(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(
        select(Notification).where(Notification.user_id == user.id).order_by(Notification.created_at.desc())
    )
    return r.scalars().all()


@router.get("/notifications/count")
async def get_unread_count(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    from sqlalchemy import func
    r = await db.execute(
        select(func.count()).select_from(Notification)
        .where(Notification.user_id == user.id, Notification.is_read == False)
    )
    return {"count": r.scalar() or 0}


@router.post("/notifications/{nid}/read")
async def mark_read(nid: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Notification).where(Notification.id == nid, Notification.user_id == user.id))
    n = r.scalar_one_or_none()
    if n:
        n.is_read = True
        await db.commit()
    return {"ok": True}


# ─── MESSAGES ───
@router.get("/messages/{order_id}")
async def get_messages(order_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(
        select(Message).where(Message.order_id == order_id).order_by(Message.created_at.asc())
    )
    messages = r.scalars().all()
    
    # Mark messages sent to me as read
    for m in messages:
        if m.receiver_id == user.id and not m.is_read:
            m.is_read = True
    await db.commit()
    
    return messages


@router.post("/messages")
async def send_message(data: dict, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    if data.get('receiver_id') == user.id:
        raise HTTPException(400, "Cannot send message to yourself")
    
    receiver_r = await db.execute(select(User).where(User.id == data['receiver_id']))
    if not receiver_r.scalar_one_or_none():
        raise HTTPException(404, "Receiver not found")
    
    msg = Message(
        order_id=data['order_id'],
        sender_id=user.id,
        receiver_id=data['receiver_id'],
        text=data['text'],
        is_read=False,
    )
    db.add(msg)
    await db.commit()
    await db.refresh(msg)
    return msg


# ─── CONVERSATIONS (List of chats per user) ───
@router.get("/conversations")
async def get_conversations(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(
        select(Message).where(or_(Message.sender_id == user.id, Message.receiver_id == user.id))
        .order_by(Message.created_at.desc())
    )
    messages = r.scalars().all()

    # Group by (other_user_id, order_id)
    grouped = {}
    for m in messages:
        other_id = m.receiver_id if m.sender_id == user.id else m.sender_id
        key = (other_id, m.order_id)
        if key not in grouped:
            grouped[key] = {
                'last_message': m.text,
                'time': m.created_at,
                'order_id': m.order_id,
                'unread': 0,
            }
        if m.receiver_id == user.id and not m.is_read:
            grouped[key]['unread'] += 1

    result = []
    for (other_id, order_id), info in grouped.items():
        u_r = await db.execute(select(User).where(User.id == other_id))
        other_user = u_r.scalar_one_or_none()
        if other_user:
            result.append({
                'user_id': other_id,
                'full_name': other_user.full_name,
                'role': other_user.role.value,
                'phone': other_user.phone,
                'order_id': order_id,
                'last_message': info['last_message'],
                'time': info['time'].isoformat() if info['time'] else None,
                'unread': info['unread'],
            })
    return result


# ─── ORDER CONTACTS (to know who you can chat with) ───
@router.get("/order-contacts/{order_id}")
async def get_order_contacts(order_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Order).where(Order.id == order_id))
    order = r.scalar_one_or_none()
    if not order:
        raise HTTPException(404, "Order not found")

    contacts = {'customer': None, 'restaurant': None, 'rider': None}

    cu_r = await db.execute(select(User).where(User.id == order.customer_id))
    customer = cu_r.scalar_one_or_none()
    if customer:
        contacts['customer'] = {'id': customer.id, 'name': customer.full_name, 'phone': customer.phone}

    rs_r = await db.execute(select(Restaurant).where(Restaurant.id == order.restaurant_id))
    restaurant = rs_r.scalar_one_or_none()
    if restaurant:
        owner_r = await db.execute(select(User).where(User.id == restaurant.owner_id))
        owner = owner_r.scalar_one_or_none()
        if owner:
            contacts['restaurant'] = {'id': owner.id, 'name': restaurant.name, 'phone': owner.phone}

    if order.rider_id:
        rd_r = await db.execute(select(Rider).where(Rider.id == order.rider_id))
        rider = rd_r.scalar_one_or_none()
        if rider:
            ru_r = await db.execute(select(User).where(User.id == rider.user_id))
            rider_user = ru_r.scalar_one_or_none()
            if rider_user:
                contacts['rider'] = {'id': rider_user.id, 'name': rider_user.full_name, 'phone': rider_user.phone}

    return contacts
