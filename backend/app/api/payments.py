from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_role
from app.core.database import get_db
from app.models import Order, Payment, PaymentStatus, User, UserRole
from app.schemas.payment import PaymentInitiateIn, PaymentInitiateOut, PaymentOut
from app.services.payments import get_provider

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/initiate", response_model=PaymentInitiateOut)
async def initiate(data: PaymentInitiateIn, user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Order).where(Order.id == data.order_id))
    order = r.scalar_one_or_none()
    if not order:
        raise HTTPException(404, "Order not found")
    if order.customer_id != user.id:
        raise HTTPException(403, "Not your order")

    provider = get_provider(data.provider)
    result = await provider.initiate(order.id, str(order.total), order.currency)

    payment = Payment(
        order_id=order.id, provider=data.provider,
        status=PaymentStatus.pending,
        amount=order.total, currency=order.currency,
    )
    db.add(payment)
    await db.commit()
    await db.refresh(payment)

    return PaymentInitiateOut(
        payment_id=payment.id, status=payment.status,
        transaction_ref=payment.transaction_ref,
        message=result["message"],
    )


@router.get("/{pid}", response_model=PaymentOut)
async def get_payment(pid: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Payment).where(Payment.id == pid))
    p = r.scalar_one_or_none()
    if not p:
        raise HTTPException(404, "Payment not found")
    if user.role == UserRole.customer:
        or_r = await db.execute(select(Order).where(Order.id == p.order_id))
        order = or_r.scalar_one_or_none()
        if order and order.customer_id != user.id:
            raise HTTPException(403, "Not your payment")
    return p


@router.post("/webhook/{provider}")
async def webhook(provider: str, payload: dict, db: AsyncSession = Depends(get_db)):
    # Stub — real providers will POST here once wired
    return {"ok": True, "provider": provider, "note": "webhook stub — integration pending"}
