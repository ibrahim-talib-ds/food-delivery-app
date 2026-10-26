from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt

from app.core.config import settings

router = APIRouter()


class ConnectionManager:
    def __init__(self):
        self.rooms: dict[int, list[WebSocket]] = {}

    async def connect(self, order_id: int, ws: WebSocket):
        await ws.accept()
        self.rooms.setdefault(order_id, []).append(ws)

    def disconnect(self, order_id: int, ws: WebSocket):
        if order_id in self.rooms and ws in self.rooms[order_id]:
            self.rooms[order_id].remove(ws)

    async def broadcast(self, order_id: int, data: dict):
        for ws in list(self.rooms.get(order_id, [])):
            try:
                await ws.send_json(data)
            except Exception:
                self.disconnect(order_id, ws)


manager = ConnectionManager()


@router.websocket("/ws/orders/{order_id}")
async def ws_order(ws: WebSocket, order_id: int, token: str = Query(...)):
    try:
        jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        await ws.close(code=1008)
        return
    await manager.connect(order_id, ws)
    try:
        while True:
            await ws.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(order_id, ws)
