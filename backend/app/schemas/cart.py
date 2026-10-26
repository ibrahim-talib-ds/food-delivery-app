from decimal import Decimal
from pydantic import BaseModel, Field


class CartItemIn(BaseModel):
    menu_item_id: int
    quantity: int = Field(default=1, ge=1, le=99)


class CartItemUpdate(BaseModel):
    quantity: int = Field(ge=0, le=99)


class CartItemOut(BaseModel):
    id: int
    menu_item_id: int
    quantity: int
    menu_item_name: str
    unit_price: Decimal
    line_total: Decimal


class CartOut(BaseModel):
    id: int | None = None
    restaurant_id: int | None = None
    items: list[CartItemOut] = []
    subtotal: Decimal = Decimal("0")
    delivery_fee: Decimal = Decimal("0")
    total: Decimal = Decimal("0")
    currency: str = "USD"
