import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import require_role
from app.core.database import get_db
from app.models import (
    MenuCategory, MenuItem, Restaurant, User, UserRole,
)
from app.schemas.menu import (
    CategoryIn, CategoryOut, MenuItemIn, MenuItemOut, MenuItemUpdate,
)

router = APIRouter(prefix="/menu", tags=["menu"])


async def _own(restaurant_id: int, user: User, db: AsyncSession) -> Restaurant:
    r = await db.execute(select(Restaurant).where(Restaurant.id == restaurant_id))
    obj = r.scalar_one_or_none()
    if not obj:
        raise HTTPException(404, "Restaurant not found")
    if obj.owner_id != user.id and user.role != UserRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your restaurant")
    return obj


# ---- UPLOAD IMAGE ---- 
@router.post("/upload-image")
async def upload_image(
    file: UploadFile = File(...),
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
):
    allowed_types = ["image/jpeg", "image/png", "image/jpg", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(400, "Only JPG, PNG, and WebP images are allowed")
    
    ext = file.filename.split(".")[-1] if file.filename else "jpg"
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = f"uploads/{filename}"
    
    with open(filepath, "wb") as f:
        content = await file.read()
        f.write(content)
    
    return {"url": f"http://127.0.0.1:8001/uploads/{filename}"}


# ---- ALL PRODUCTS (Global Home Screen) ----
@router.get("/all")
async def all_products(db: AsyncSession = Depends(get_db)):
    from sqlalchemy.orm import selectinload
    r = await db.execute(
        select(MenuItem).options(selectinload(MenuItem.restaurant))
        .where(MenuItem.available == True)
        .order_by(MenuItem.id.desc())
    )
    items = r.scalars().all()
    result = []
    for item in items:
        result.append({
            "id": item.id,
            "name": item.name,
            "description": item.description,
            "price": str(item.price),
            "currency": item.currency,
            "image_url": item.image_url,
            "restaurant_id": item.restaurant_id,
            "restaurant_name": item.restaurant.name if item.restaurant else "Restaurant",
            "available": item.available,
        })
    return result


# ---- RELATED PRODUCTS ----
@router.get("/related/{item_id}")
async def related_items(item_id: int, db: AsyncSession = Depends(get_db)):
    r = await db.execute(select(MenuItem).where(MenuItem.id == item_id))
    current = r.scalar_one_or_none()
    if not current:
        return []
    
    # Get 4 similar products (excluding current)
    q = select(MenuItem).where(
        MenuItem.id != item_id,
        MenuItem.available == True,
        MenuItem.restaurant_id == current.restaurant_id
    ).order_by(MenuItem.id.desc()).limit(4)
    r = await db.execute(q)
    items = r.scalars().all()
    
    result = []
    for item in items:
        result.append({
            "id": item.id,
            "name": item.name,
            "description": item.description,
            "price": str(item.price),
            "currency": item.currency,
            "image_url": item.image_url,
            "restaurant_id": item.restaurant_id,
            "available": item.available,
        })
    return result


# ---- PUBLIC LISTING ----
@router.get("/restaurants/{rid}/categories", response_model=list[CategoryOut])
async def list_categories(rid: int, db: AsyncSession = Depends(get_db)):
    r = await db.execute(
        select(MenuCategory).where(MenuCategory.restaurant_id == rid)
        .order_by(MenuCategory.sort_order, MenuCategory.id)
    )
    return r.scalars().all()


@router.get("/restaurants/{rid}/items", response_model=list[MenuItemOut])
async def list_items(rid: int, db: AsyncSession = Depends(get_db)):
    r = await db.execute(
        select(MenuItem).where(MenuItem.restaurant_id == rid)
        .order_by(MenuItem.sort_order, MenuItem.id)
    )
    return r.scalars().all()


# ---- CATEGORY CRUD ----
@router.post("/restaurants/{rid}/categories", response_model=CategoryOut, status_code=201)
async def create_category(
    rid: int,
    data: CategoryIn,
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    await _own(rid, user, db)
    obj = MenuCategory(restaurant_id=rid, **data.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.delete("/categories/{cid}", status_code=204)
async def delete_category(
    cid: int,
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(MenuCategory).where(MenuCategory.id == cid))
    obj = r.scalar_one_or_none()
    if not obj:
        raise HTTPException(404, "Category not found")
    await _own(obj.restaurant_id, user, db)
    await db.delete(obj)
    await db.commit()


# ---- ITEM CRUD ----
@router.post("/restaurants/{rid}/items", response_model=MenuItemOut, status_code=201)
async def create_item(
    rid: int,
    data: MenuItemIn,
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    await _own(rid, user, db)
    obj = MenuItem(restaurant_id=rid, **data.model_dump())
    db.add(obj)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.patch("/items/{iid}", response_model=MenuItemOut)
async def update_item(
    iid: int,
    data: MenuItemUpdate,
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(MenuItem).where(MenuItem.id == iid))
    obj = r.scalar_one_or_none()
    if not obj:
        raise HTTPException(404, "Item not found")
    await _own(obj.restaurant_id, user, db)
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    await db.commit()
    await db.refresh(obj)
    return obj


@router.delete("/items/{iid}", status_code=204)
async def delete_item(
    iid: int,
    user: User = Depends(require_role(UserRole.restaurant_owner, UserRole.admin)),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(MenuItem).where(MenuItem.id == iid))
    obj = r.scalar_one_or_none()
    if not obj:
        raise HTTPException(404, "Item not found")
    await _own(obj.restaurant_id, user, db)
    await db.delete(obj)
    await db.commit()
