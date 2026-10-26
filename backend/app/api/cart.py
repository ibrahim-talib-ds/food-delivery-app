from decimal import Decimal
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import require_role
from app.core.database import get_db
from app.models import Cart, CartItem, MenuItem, Restaurant, User, UserRole
from app.schemas.cart import CartItemIn, CartItemUpdate, CartItemOut, CartOut

router = APIRouter(prefix="/cart", tags=["cart"])


async def _load_cart(db: AsyncSession, customer_id: int) -> Cart | None:
    r = await db.execute(
        select(Cart).where(Cart.customer_id == customer_id).options(selectinload(Cart.items)).execution_options(populate_existing=True)
    )
    return r.scalar_one_or_none()


async def _build_out(db: AsyncSession, cart: Cart | None) -> CartOut:
    if not cart:
        return CartOut()
    items_out: list[CartItemOut] = []
    subtotal = Decimal("0")
    currency = "USD"
    for ci in cart.items:
        mi_r = await db.execute(select(MenuItem).where(MenuItem.id == ci.menu_item_id))
        mi = mi_r.scalar_one_or_none()
        if not mi:
            continue
        line = mi.price * ci.quantity
        subtotal += line
        currency = mi.currency
        items_out.append(CartItemOut(
            id=ci.id, menu_item_id=ci.menu_item_id, quantity=ci.quantity,
            menu_item_name=mi.name, unit_price=mi.price, line_total=line,
        ))
    delivery_fee = Decimal("0")
    if cart.restaurant_id:
        rs_r = await db.execute(select(Restaurant).where(Restaurant.id == cart.restaurant_id))
        rs = rs_r.scalar_one_or_none()
        if rs:
            delivery_fee = rs.delivery_fee
    return CartOut(
        id=cart.id, restaurant_id=cart.restaurant_id, items=items_out,
        subtotal=subtotal, delivery_fee=delivery_fee, total=subtotal + delivery_fee,
        currency=currency,
    )


@router.get("", response_model=CartOut)
async def get_cart(user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    return await _build_out(db, await _load_cart(db, user.id))


@router.post("/items", response_model=CartOut)
async def add_item(data: CartItemIn, user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    mi_r = await db.execute(select(MenuItem).where(MenuItem.id == data.menu_item_id))
    mi = mi_r.scalar_one_or_none()
    if not mi or not mi.available:
        raise HTTPException(404, "Menu item not available")

    cart = await _load_cart(db, user.id)
    if not cart:
        cart = Cart(customer_id=user.id)
        db.add(cart)
        await db.commit()
        await db.refresh(cart)
        cart = await _load_cart(db, user.id)

    if cart.restaurant_id and cart.restaurant_id != mi.restaurant_id:
        for ci in cart.items:
            await db.delete(ci)
        cart.restaurant_id = mi.restaurant_id
        await db.commit()
        cart = await _load_cart(db, user.id)
    elif not cart.restaurant_id:
        cart.restaurant_id = mi.restaurant_id
        await db.commit()
        cart = await _load_cart(db, user.id)

    existing = next((c for c in cart.items if c.menu_item_id == mi.id), None)
    if existing:
        existing.quantity += data.quantity
    else:
        db.add(CartItem(cart_id=cart.id, menu_item_id=mi.id, quantity=data.quantity))
    await db.commit()
    cart = await _load_cart(db, user.id)
    return await _build_out(db, cart)


@router.patch("/items/{item_id}", response_model=CartOut)
async def update_item(item_id: int, data: CartItemUpdate, user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    cart = await _load_cart(db, user.id)
    if not cart:
        raise HTTPException(404, "Cart empty")
    ci = next((c for c in cart.items if c.id == item_id), None)
    if not ci:
        raise HTTPException(404, "Item not in cart")
    if data.quantity <= 0:
        await db.delete(ci)
    else:
        ci.quantity = data.quantity
    await db.commit()
    return await _build_out(db, await _load_cart(db, user.id))


@router.delete("/items/{item_id}", response_model=CartOut)
async def remove_item(item_id: int, user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    return await update_item(item_id, CartItemUpdate(quantity=0), user, db)


@router.delete("", status_code=204)
async def clear_cart(user: User = Depends(require_role(UserRole.customer)), db: AsyncSession = Depends(get_db)):
    cart = await _load_cart(db, user.id)
    if cart:
        for ci in cart.items:
            await db.delete(ci)
        cart.restaurant_id = None
        await db.commit()
