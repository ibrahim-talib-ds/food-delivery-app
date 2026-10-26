from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel
from app.models import RiderStatus


class RiderProfileIn(BaseModel):
    vehicle_type: str = "motorcycle"
    city: str | None = None
    country: str | None = None


class RiderProfileOut(BaseModel):
    id: int
    user_id: int
    vehicle_type: str
    current_status: RiderStatus
    city: str | None
    country: str | None

    class Config:
        from_attributes = True


class RiderStatusIn(BaseModel):
    current_status: RiderStatus
    lat: Decimal | None = None
    lng: Decimal | None = None


class AvailableJobOut(BaseModel):
    order_id: int
    restaurant_id: int
    restaurant_name: str
    address: str
    city: str | None
    total: Decimal
    currency: str
    created_at: datetime


class DeliveryOut(BaseModel):
    id: int
    order_id: int
    rider_id: int
    pickup_time: datetime | None
    dropoff_time: datetime | None
    earnings: Decimal

    class Config:
        from_attributes = True


class EarningsOut(BaseModel):
    total_earnings: Decimal
    currency: str
    deliveries: list[DeliveryOut]
