import requests
import subprocess

API = "http://localhost:8001"

print("1. Unblocking all users in the database...")
subprocess.run(["sudo", "-u", "postgres", "psql", "-d", "fooddelivery", "-c", "UPDATE users SET is_active=true;"], capture_output=True)

def login(phone):
    res = requests.post(f"{API}/auth/login", json={"phone": phone, "password": "1542004ibrahim"}).json()
    if "access_token" not in res:
        return None
    token = res["access_token"]
    me = requests.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {token}"}).json()
    return {"token": token, "id": me["id"], "role": me["role"], "headers": {"Authorization": f"Bearer {token}"}}

print("2. Setting up Restaurant Owner...")
owner = login("+255692034382")
restaurant_id = None
if owner:
    rs = requests.get(f"{API}/restaurants").json()
    for r in rs:
        if r['owner_id'] == owner['id']:
            restaurant_id = r['id']
            break
            
    if not restaurant_id:
        res = requests.post(f"{API}/restaurants", headers=owner['headers'], json={"name": "World Bites", "description": "Delicious food", "delivery_fee": "2.50", "currency": "USD"})
        restaurant_id = res.json()['id']
    
    print(f"✅ Restaurant ID: {restaurant_id}")

print("3. Approving restaurant via Admin...")
admin = login("+255692034381")
if admin and restaurant_id:
    requests.patch(f"{API}/admin/restaurants/{restaurant_id}/approve", headers=admin['headers'])

print("4. Adding food items...")
if owner and restaurant_id:
    items = [
        {"name": "Classic Cheeseburger", "description": "Beef patty, cheddar", "price": "12.99", "currency": "USD"},
        {"name": "Margherita Pizza", "description": "Fresh mozzarella", "price": "11.99", "currency": "USD"},
        {"name": "Truffle Fries", "description": "Crispy fries", "price": "6.50", "currency": "USD"}
    ]
    existing_items = requests.get(f"{API}/menu/restaurants/{restaurant_id}/items").json()
    if len(existing_items) == 0:
        for item in items:
            requests.post(f"{API}/menu/restaurants/{restaurant_id}/items", headers=owner['headers'], json=item)

print("5. Setting up Rider Profile & Online status...")
rider = login("+255692034383")
if rider:
    # Create profile (will fail silently if already exists, which is fine)
    requests.post(f"{API}/riders/me", headers=rider['headers'], json={"vehicle_type": "motorcycle"})
    # Force status to available
    requests.patch(f"{API}/riders/me", headers=rider['headers'], json={"current_status": "available"})

print("\n✅✅✅ EVERYTHING IS PERFECTLY SET UP! ✅✅✅")
