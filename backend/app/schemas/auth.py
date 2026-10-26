from pydantic import BaseModel, EmailStr, Field
from app.models import UserRole


class RegisterIn(BaseModel):
    phone: str = Field(min_length=6, max_length=32)
    email: EmailStr | None = None
    password: str = Field(min_length=6, max_length=128)
    full_name: str = Field(min_length=2, max_length=120)
    role: UserRole = UserRole.customer
    city: str | None = None
    country: str | None = None
    language_pref: str = "en"


class LoginIn(BaseModel):
    phone: str
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: UserRole


class UserOut(BaseModel):
    id: int
    phone: str
    email: str | None
    full_name: str
    role: UserRole
    city: str | None
    country: str | None
    language_pref: str

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    full_name: str | None = None
    full_address: str | None = None
    place: str | None = None
    email: EmailStr | None = None
    city: str | None = None
    country: str | None = None
    language_pref: str | None = None
