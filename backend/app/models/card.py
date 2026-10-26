from datetime import datetime
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.core.database import Base

class SavedCard(Base):
    __tablename__ = "saved_cards"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    card_number: Mapped[str] = mapped_column(String(32)) # In production, NEVER store this in plain text!
    card_holder: Mapped[str] = mapped_column(String(100))
    expiry_date: Mapped[str] = mapped_column(String(5)) # MM/YY
    card_type: Mapped[str] = mapped_column(String(20)) # visa, mastercard
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class Wallet(Base):
    __tablename__ = "wallets"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True)
    balance: Mapped[float] = mapped_column(default=0.0)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
