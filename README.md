<div align="center">

# 🍔 Food Delivery Platform

### A production-ready, full-stack food delivery ecosystem for the modern web

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org)
[![License](https://img.shields.io/badge/License-MIT-D4AF37?style=for-the-badge)](LICENSE)

</div>

---

## 🌟 Overview

**Food Delivery Platform** is a complete, production-grade food ordering system built for worldwide use. It connects **Customers**, **Restaurants**, **Riders**, and **Administrators** in a single, unified app with a premium **forest green + gold** design.

Unlike typical tutorial projects, this platform ships with:

- **Real-time order tracking** via WebSockets + OpenStreetMap
- **Live in-app chat** between every role
- **Wallet & card payments** with saved cards
- **Worldwide location search** (Nominatim — no API key)
- **Admin console** with full platform control
- **Responsive UI** for mobile, tablet, and desktop

---

## ✨ Features

### 🍕 Customer App
- Premium product grid with real photos
- Search any dish globally
- Category filters (Burgers, Pizza, Chicken, Salads, Desserts, Coffee, Sushi)
- Quick add-to-cart with `+` button
- Food details with related foods
- Real-time cart & checkout
- Live order tracking with animated scooter
- Order timeline (Pending → Delivered)
- In-app chat with restaurant & rider
- Call buttons for direct contact
- Wallet & saved card payments
- Order history with reorder
- Notifications with unread badge
- Profile with worldwide location search
- Full settings (notifications, language, privacy)

### 🏪 Restaurant Dashboard
- Auto-refreshing incoming orders
- Accept → Prepare → Ready workflow
- Rider contact (Call + Chat)
- Menu management (add, edit, delete)
- Image upload (file + URL)
- 19 food categories
- Availability toggle

### 🏍️ Rider Dashboard
- Online/Offline toggle
- Auto-refreshing jobs
- Accept & deliver
- Active delivery tracking
- Earnings history
- Customer contact (Call + Chat)

### 👑 Admin Console
- Live revenue stats
- Restaurant approval (approve, suspend, delete)
- User management (block, unblock, delete)
- Create new users
- Clickable stat cards

---

## 🎨 Design System

| Color | Hex | Usage |
|-------|-----|-------|
| **Deep Forest** | `#0D2B1A` | Primary brand |
| **Premium Gold** | `#D4AF37` | Accents, CTAs |
| **Light Gold** | `#F3E5AB` | Highlights |
| **Off-White** | `#F9F9F9` | Backgrounds |
| **Danger Red** | `#E63946` | Errors |

**Design:** Rounded corners, subtle shadows, curved headers, gold accents.

---

## 🛠 Tech Stack

### Backend
- **FastAPI** (async Python)
- **PostgreSQL 16**
- **SQLAlchemy 2.0** (async)
- **Alembic** (migrations)
- **JWT** + **Argon2** (auth)
- **WebSockets** (real-time)

### Frontend
- **Flutter** (Android, iOS, Web)
- **Provider** (state)
- **flutter_map** (OpenStreetMap)
- **flutter_svg** (logo)
- **web_socket_channel** (live tracking)
- **url_launcher** (calls)
- **file_picker** (image upload)

---

## 🚀 Installation

### Prerequisites
- Python 3.10+
- Flutter 3.0+
- PostgreSQL 14+

### Backend Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Edit .env with your DATABASE_URL and JWT_SECRET

createdb fooddelivery
export PYTHONPATH="$(pwd):$PYTHONPATH"
alembic upgrade head

uvicorn app.main:app --host 0.0.0.0 --port 8001
