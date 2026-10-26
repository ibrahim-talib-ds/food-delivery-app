from pydantic import BaseModel


class SettingIn(BaseModel):
    key: str
    value: str


class SettingOut(BaseModel):
    id: int
    key: str
    value: str

    class Config:
        from_attributes = True


class AdminUserOut(BaseModel):
    id: int
    phone: str
    full_name: str
    role: str
    is_active: bool

    class Config:
        from_attributes = True


class ReportsOut(BaseModel):
    total_users: int
    total_customers: int
    total_restaurants: int
    total_riders: int
    total_orders: int
    total_delivered: int
    total_revenue: str
    pending_restaurants: int
