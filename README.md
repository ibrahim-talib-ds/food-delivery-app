# 🍔 Food Delivery Platform

A production-ready, full-stack food delivery ecosystem built for worldwide use.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org)
[![License](https://img.shields.io/badge/License-MIT-D4AF37?style=for-the-badge)](LICENSE)

---

## 🌟 Overview

**Food Delivery Platform** is a complete, production-grade food ordering system. It connects **Customers**, **Restaurants**, **Riders**, and **Administrators** in one app with a premium **forest green + gold** design.

- **Real-time order tracking** via WebSockets + OpenStreetMap
- **Live in-app chat** between all roles
- **Wallet & card payments**
- **Worldwide location search** (no API key)
- **Admin console** for full control
- **Responsive UI** for mobile, tablet, and desktop

---

## ✨ Features

### 🍕 Customer App
- Product grid with real photos
- Global search + category filters
- Quick add-to-cart
- Food details with related suggestions
- Live order tracking with animated map
- In-app chat + call buttons
- Wallet & card payments
- Order history
- Notifications
- Profile & settings

### 🏪 Restaurant Dashboard
- Auto-refreshing incoming orders
- Accept → Prepare → Ready workflow
- Rider contact (Call + Chat)
- Menu management (add, edit, delete)
- Image upload (file or URL)

### 🏍️ Rider Dashboard
- Online/Offline toggle
- Auto-refreshing available jobs
- Accept and deliver
- Active delivery tracking
- Earnings history

### 👑 Admin Console
- Revenue stats
- Restaurant approval (approve, suspend, delete)
- User management
- Create users

---

## 🛠 Tech Stack

**Backend:** FastAPI • PostgreSQL • SQLAlchemy 2.0 • Alembic • JWT • Argon2 • WebSockets

**Frontend:** Flutter • Provider • flutter_map • flutter_svg • web_socket_channel

---

## 🚀 Quick Start

### Backend
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with DATABASE_URL and JWT_SECRET
createdb fooddelivery
export PYTHONPATH="$(pwd):$PYTHONPATH"
alembic upgrade head
uvicorn app.main:app --host 0.0.0.0 --port 8001
