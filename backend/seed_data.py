import requests

API = "http://127.0.0.1:8001"

# 1. Login as Admin to approve the restaurant
admin_login = requests.post(f"{API}/auth/login", json={"phone": "+255692034381", "password": "1542004ibrahim"}).json()
admin_token = admin_login.get("access_token")

# Approve restaurant ID 1
requests.patch(f"{API}/admin/restaurants/1/approve", headers={"Authorization": f"Bearer {admin_token}"})
print("✅ Restaurant Approved")

# 2. Login as Owner to add items
owner_login = requests.post(f"{API}/auth/login", json={"phone": "+255692034382", "password": "1542004ibrahim"}).json()
owner_token = owner_login.get("access_token")
owner_headers = {"Authorization": f"Bearer {owner_token}"}

# Find Restaurant ID
rs = requests.get(f"{API}/restaurants").json()
if not rs:
    print("No restaurant found. Run the app to create it first.")
    exit()
restaurant_id = rs[0]['id']

items = [
    {"name": "Classic Cheeseburger", "description": "Beef patty, cheddar, pickles, special sauce", "price": "12.99", "currency": "USD", "available": True},
    {"name": "Bacon Avocado Burger", "description": "Smoked bacon, fresh avocado, swiss cheese", "price": "14.50", "currency": "USD", "available": True},
    {"name": "Margherita Pizza", "description": "Fresh mozzarella, basil, tomato sauce", "price": "11.99", "currency": "USD", "available": True},
    {"name": "Pepperoni Pizza", "description": "Double pepperoni, extra cheese", "price": "13.99", "currency": "USD", "available": True},
    {"name": "Truffle Fries", "description": "Crispy fries with truffle oil and parmesan", "price": "6.50", "currency": "USD", "available": True},
    {"name": "Caesar Salad", "description": "Romaine, croutons, parmesan, caesar dressing", "price": "8.99", "currency": "USD", "available": True},
    {"name": "Spicy Chicken Wings", "description": "6 pieces, tossed in buffalo sauce", "price": "9.99", "currency": "USD", "available": True},
    {"name": "Chocolate Brownie", "description": "Warm fudge brownie with vanilla ice cream", "price": "5.99", "currency": "USD", "available": True},
    {"name": "Fresh Lemonade", "description": "Freshly squeezed, lightly sweetened", "price": "3.50", "currency": "USD", "available": True},
    {"name": "Iced Caramel Macchiato", "description": "Espresso, milk, caramel syrup, ice", "price": "4.50", "currency": "USD", "available": True}
]

for item in items:
    res = requests.post(f"{API}/menu/restaurants/{restaurant_id}/items", headers=owner_headers, json=item)
    if res.status_code == 201:
        print(f"✅ Added: {item['name']}")
    else:
        print(f"❌ Failed: {item['name']} - {res.text}")

print("\n🎉 DATABASE SEEDED SUCCESSFULLY! 🎉")
