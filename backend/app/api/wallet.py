from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models import User
from app.models.card import SavedCard, Wallet

router = APIRouter(prefix="/wallet", tags=["wallet"])

# --- GET WALLET BALANCE ---
@router.get("/balance")
async def get_balance(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(Wallet).where(Wallet.user_id == user.id))
    wallet = r.scalar_one_or_none()
    if not wallet:
        wallet = Wallet(user_id=user.id, balance=0.0)
        db.add(wallet)
        await db.commit()
        await db.refresh(wallet)
    return {"balance": wallet.balance}

# --- ADD A CARD ---
@router.post("/cards")
async def add_card(data: dict, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    card_number = data['card_number'].replace(" ", "")
    card_type = "visa" if card_number.startswith("4") else "mastercard"
    
    new_card = SavedCard(
        user_id=user.id,
        card_number=card_number,
        card_holder=data['card_holder'],
        expiry_date=data['expiry_date'],
        card_type=card_type
    )
    db.add(new_card)
    await db.commit()
    await db.refresh(new_card)
    return new_card

# --- LIST CARDS ---
@router.get("/cards")
async def list_cards(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(SavedCard).where(SavedCard.user_id == user.id))
    return r.scalars().all()

# --- DELETE CARD ---
@router.delete("/cards/{card_id}")
async def delete_card(card_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(SavedCard).where(SavedCard.id == card_id, SavedCard.user_id == user.id))
    card = r.scalar_one_or_none()
    if not card: raise HTTPException(404, "Card not found")
    await db.delete(card)
    await db.commit()
    return {"ok": True}
