from decimal import Decimal
from pydantic import BaseModel, Field
from app.models import RestaurantStatus


class RestaurantIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    description: str | None = None
    image_url: str | None = None
    city: str | None = None
    country: str | None = None
    address: str | None = None
    lat: Decimal | None = None
    lng: Decimal | None = None
    service_areas: list[str] | None = None
    delivery_fee: Decimal = Decimal("0")
    currency: str = "USD"


class RestaurantUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    image_url: str | None = None
    city: str | None = None
    country: str | None = None
    address: str | None = None
    lat: Decimal | None = None
    lng: Decimal | None = None
    service_areas: list[str] | None = None
    delivery_fee: Decimal | None = None
    currency: str | None = None


class RestaurantOut(BaseModel):
    id: int
    owner_id: int
    name: str
    description: str | None
    image_url: str | None
    city: str | None
    country: str | None
    address: str | None
    lat: Decimal | None
    lng: Decimal | None
    service_areas: list | None
    delivery_fee: Decimal
    currency: str
    status: RestaurantStatus

    class Config:
        from_attributes = True


class StatusUpdate(BaseModel):
    status: RestaurantStatus
