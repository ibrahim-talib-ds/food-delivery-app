import requests
import subprocess

API = "http://127.0.0.1:8001"

def register(phone, name, role):
    r = requests.post(f"{API}/auth/register", json={
        "phone": phone, "password": "1542004ibrahim", 
        "full_name": name, "role": role
    })
    print(f"{'✅' if r.status_code in [200, 201] else 'ℹ️'} {name}: {r.status_code}")

# 1. Create the new Owner
register("+255692034384", "New Owner Ibrahim", "restaurant_owner")

# 2. Ensure Rider exists & is available
register("+255692034383", "Ibrahim Rider", "rider")

# 3. Login rider and create profile / go online
rider = requests.post(f"{API}/auth/login", json={"phone": "+255692034383", "password": "1542004ibrahim"}).json()
if "access_token" in rider:
    headers = {"Authorization": f"Bearer {rider['access_token']}"}
    requests.post(f"{API}/riders/me", headers=headers, json={"vehicle_type": "motorcycle"})
    requests.patch(f"{API}/riders/me", headers=headers, json={"current_status": "available"})
    print("✅ Rider profile created & set to Available")

print("\n🎉 DONE! You can now login with all accounts.")
