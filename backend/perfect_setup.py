import requests

API = "http://localhost:8001"

def register(phone, name, role):
    requests.post(f"{API}/auth/register", json={"phone": phone, "password": "1542004ibrahim", "full_name": name, "role": role})

# 1. Create all accounts (safely, won't crash if they exist)
register("+255692034380", "Ibrahim Customer", "customer")
register("+255692034381", "Ibrahim Admin", "customer") # Promoted to admin later
register("+255692034382", "Ibrahim Owner", "restaurant_owner")
register("+255692034383", "Ibrahim Rider", "rider")

# Promote Admin
import subprocess
subprocess.run(["sudo", "-u", "postgres", "psql", "-d", "fooddelivery", "-c", "UPDATE users SET role='admin' WHERE phone='+255692034381';"], capture_output=True)

# 2. Login Admin & Approve Restaurant
admin = requests.post(f"{API}/auth/login", json={"phone": "+255692034381", "password": "1542004ibrahim"}).json()
if "access_token" in admin:
    requests.patch(f"{API}/admin/restaurants/1/approve", headers={"Authorization": f"Bearer {admin['access_token']}"})

# 3. Login Owner & Add Food Items
owner = requests.post(f"{API}/auth/login", json={"phone": "+255692034382", "password": "1542004ibrahim"}).json()
if "access_token" in owner:
    headers = {"Authorization": f"Bearer {owner['access_token']}"}
    rs = requests.get(f"{API}/restaurants").json()
    if rs:
        rid = rs[0]['id']
        items = [
            {"name": "Classic Cheeseburger", "description": "Beef patty, cheddar", "price": "12.99", "currency": "USD"},
            {"name": "Margherita Pizza", "description": "Fresh mozzarella", "price": "11.99", "currency": "USD"},
            {"name": "Truffle Fries", "description": "Crispy fries", "price": "6.50", "currency": "USD"}
        ]
        for item in items:
            requests.post(f"{API}/menu/restaurants/{rid}/items", headers=headers, json=item)

print("✅ ALL ACCOUNTS CREATED & DATA SEEDED")
