from decimal import Decimal
from pydantic import BaseModel
from app.models import PaymentStatus


class PaymentInitiateIn(BaseModel):
    order_id: int
    provider: str


class PaymentOut(BaseModel):
    id: int
    order_id: int
    provider: str
    status: PaymentStatus
    transaction_ref: str | None
    amount: Decimal
    currency: str

    class Config:
        from_attributes = True


class PaymentInitiateOut(BaseModel):
    payment_id: int
    status: PaymentStatus
    transaction_ref: str | None
    message: str
