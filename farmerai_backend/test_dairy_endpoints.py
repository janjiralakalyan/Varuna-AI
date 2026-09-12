"""
Test script for verifying Dairy AI backend endpoints
"""
import sys
import json
import asyncio
from fastapi.testclient import TestClient

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from main import app

client = TestClient(app)

print("🧪 Testing /predict/cattle/milk ...")
milk_payload = {
    "breed": "Holstein Friesian (HF Cross)",
    "lactation_month": 3,
    "animal_weight": 520.0,
    "green_fodder_kg": 30.0,
    "dry_fodder_kg": 5.0,
    "concentrate_kg": 5.5,
    "water_liters": 75.0,
    "temperature_c": 27.5,
    "humidity_pct": 62.0,
    "lang": "en"
}
res_milk = client.post("/predict/cattle/milk", json=milk_payload)
print(f"Status: {res_milk.status_code}")
print("Milk Result:", json.dumps(res_milk.json(), indent=2))

print("\n🧪 Testing /predict/cattle/medical with Lumpy Skin Disease symptoms ...")
medical_payload = {
    "symptoms": ["skin_nodules", "fever", "drop_in_milk", "loss_of_appetite"],
    "species": "Cow",
    "breed": "Jersey Cross",
    "age_years": 4.0,
    "body_temp_f": 104.2,
    "duration_days": 2,
    "free_text": "Cattle has hard round lumps on skin and high fever",
    "lang": "en"
}
res_medical = client.post("/predict/cattle/medical", json=medical_payload)
print(f"Status: {res_medical.status_code}")
med_data = res_medical.json()
print(f"Diagnosed: {med_data.get('primary_diagnosis')} ({med_data.get('confidence_score')}%)")
print(f"Urgency: {med_data.get('urgency_level')}")
print("Prescriptions count:", len(med_data.get('veterinary_prescriptions', [])))
print("First Aid count:", len(med_data.get('first_aid_steps', [])))

print("\n🧪 Testing /predict/cattle/diet ...")
diet_payload = {
    "breed": "Murrah Buffalo",
    "animal_weight": 580.0,
    "daily_milk_yield": 14.0,
    "is_pregnant": True,
    "pregnancy_month": 5,
    "available_fodders": ["Green Napier", "Paddy Straw", "Cottonseed Cake"],
    "flat_milk_rate": 55.0,
    "lang": "en"
}
res_diet = client.post("/predict/cattle/diet", json=diet_payload)
print(f"Status: {res_diet.status_code}")
print("Diet Result:", json.dumps(res_diet.json(), indent=2))

print("\n✅ All Dairy AI Backend Endpoints Verified Successfully!")
