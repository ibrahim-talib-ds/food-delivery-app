from decimal import Decimal
from pydantic import BaseModel, Field


class CategoryIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    sort_order: int = 0


class CategoryOut(BaseModel):
    id: int
    restaurant_id: int
    name: str
    sort_order: int

    class Config:
        from_attributes = True


class MenuItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    description: str | None = None
    price: Decimal
    currency: str = "USD"
    image_url: str | None = None
    category_id: int | None = None
    available: bool = True
    sort_order: int = 0


class MenuItemUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    price: Decimal | None = None
    currency: str | None = None
    image_url: str | None = None
    category_id: int | None = None
    available: bool | None = None
    sort_order: int | None = None


class MenuItemOut(BaseModel):
    id: int
    restaurant_id: int
    category_id: int | None
    name: str
    description: str | None
    price: Decimal
    currency: str
    image_url: str | None
    available: bool
    sort_order: int

    class Config:
        from_attributes = True
