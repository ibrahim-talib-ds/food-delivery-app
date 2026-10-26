import requests
import subprocess

API = "http://127.0.0.1:8001"

def login(phone):
    r = requests.post(f"{API}/auth/login", json={"phone": phone, "password": "1542004ibrahim"}).json()
    if "access_token" not in r:
        print(f"❌ Login failed for {phone}")
        return None
    token = r["access_token"]
    me = requests.get(f"{API}/auth/me", headers={"Authorization": f"Bearer {token}"}).json()
    return {"token": token, "id": me["id"], "headers": {"Authorization": f"Bearer {token}"}}

owner = login("+255692034382")
if not owner:
    exit(1)
print(f"✅ Owner logged in (ID: {owner['id']})")

# Get or create restaurant for this owner
all_restaurants = requests.get(f"{API}/restaurants").json()
my_restaurant = next((r for r in all_restaurants if r['owner_id'] == owner['id']), None)

if not my_restaurant:
    print("Creating new restaurant...")
    res = requests.post(f"{API}/restaurants", headers=owner['headers'], json={
        "name": "World Bites", "description": "Delicious food",
        "delivery_fee": "2.50", "currency": "USD"
    })
    my_restaurant = res.json()

restaurant_id = my_restaurant['id']
print(f"✅ Using Restaurant ID: {restaurant_id}")

# Approve restaurant via admin
admin = login("+255692034381")
if admin:
    requests.patch(f"{API}/admin/restaurants/{restaurant_id}/approve", headers=admin['headers'])
    print(f"✅ Restaurant approved")

# Clear existing items
existing = requests.get(f"{API}/menu/restaurants/{restaurant_id}/items").json()
for item in existing:
    requests.delete(f"{API}/menu/items/{item['id']}", headers=owner['headers'])
print(f"✅ Cleared {len(existing)} old items")

# Add new products
products = [
    {"name": "Classic Cheeseburger", "description": "Juicy beef patty, melted cheddar, fresh lettuce, tomato, pickles, and our secret sauce in a brioche bun", "price": "12.99", "image_url": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600"},
    {"name": "Pepperoni Pizza", "description": "Hand-tossed dough with marinara sauce, premium mozzarella, and double pepperoni", "price": "14.99", "image_url": "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600"},
    {"name": "Grilled Chicken Burger", "description": "Flame-grilled chicken breast, avocado, bacon, and garlic aioli", "price": "13.50", "image_url": "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=600"},
    {"name": "Margherita Pizza", "description": "Fresh mozzarella, basil, cherry tomatoes, and olive oil on thin crust", "price": "11.99", "image_url": "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600"},
    {"name": "Crispy Chicken Wings", "description": "8 pieces tossed in your choice of buffalo or BBQ sauce", "price": "10.99", "image_url": "https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=600"},
    {"name": "Caesar Salad", "description": "Romaine lettuce, parmesan, croutons, and classic Caesar dressing", "price": "8.99", "image_url": "https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=600"},
    {"name": "Truffle Fries", "description": "Golden fries tossed in truffle oil, parmesan, and fresh herbs", "price": "6.50", "image_url": "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600"},
    {"name": "Chocolate Lava Cake", "description": "Warm chocolate cake with molten center, served with vanilla ice cream", "price": "7.99", "image_url": "https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=600"},
    {"name": "Iced Caramel Macchiato", "description": "Espresso, steamed milk, vanilla, and caramel drizzle over ice", "price": "4.99", "image_url": "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600"},
    {"name": "Sushi Platter", "description": "Assorted nigiri and maki rolls with wasabi and pickled ginger", "price": "18.99", "image_url": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=600"},
]

for p in products:
    r = requests.post(f"{API}/menu/restaurants/{restaurant_id}/items", headers=owner['headers'], json={
        "name": p["name"], "description": p["description"], "price": p["price"],
        "currency": "USD", "image_url": p["image_url"],
        "available": True, "sort_order": 0,
    })
    if r.status_code == 201:
        print(f"✅ {p['name']}")
    else:
        print(f"❌ {p['name']}: {r.status_code} - {r.text[:100]}")

print(f"\n🎉 Done! Check http://127.0.0.1:8001/menu/all")
