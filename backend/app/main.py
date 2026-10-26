from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
import os
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, restaurants, menu, cart, orders, riders, admin, payments, ws, communications, wallet
from app.core.config import settings

app = FastAPI(title=settings.PROJECT_NAME, version="0.4.0")

# ─── FIXED CORS CONFIGURATION ───
# We must set allow_credentials=False when using allow_origins=["*"] to prevent Chrome from blocking it.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(restaurants.router)
app.include_router(menu.router)
app.include_router(cart.router)
app.include_router(orders.router)
app.include_router(riders.router)
app.include_router(admin.router)
app.include_router(payments.router)
app.include_router(ws.router)
app.include_router(communications.router)
app.include_router(wallet.router)

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "project": settings.PROJECT_NAME}
