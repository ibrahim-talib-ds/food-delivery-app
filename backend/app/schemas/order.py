from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel, Field
from app.models import OrderStatus


class OrderCreateIn(BaseModel):
    address: str = Field(min_length=3, max_length=500)
    city: str | None = None
    country: str | None = None
    lat: Decimal | None = None
    lng: Decimal | None = None
    note: str | None = None


class OrderItemOut(BaseModel):
    id: int
    name_snapshot: str
    price_snapshot: Decimal
    quantity: int

    class Config:
        from_attributes = True


class StatusHistoryOut(BaseModel):
    status: OrderStatus
    note: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class OrderOut(BaseModel):
    id: int
    customer_id: int
    restaurant_id: int
    rider_id: int | None
    status: OrderStatus
    subtotal: Decimal
    delivery_fee: Decimal
    total: Decimal
    currency: str
    address: str
    city: str | None
    country: str | None
    note: str | None
    created_at: datetime
    items: list[OrderItemOut]
    status_history: list[StatusHistoryOut]

    class Config:
        from_attributes = True


class OrderStatusIn(BaseModel):
    status: OrderStatus
    note: str | None = None
