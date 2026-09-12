import sys
import os
import io
from PIL import Image

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

print("🧪 1. Testing /detect-disease for Pattern Match & Dataset Exemplar Images...")
img = Image.new("RGB", (224, 224), color=(34, 139, 34))
img_byte_arr = io.BytesIO()
img.save(img_byte_arr, format="JPEG")
img_bytes = img_byte_arr.getvalue()

res1 = client.post("/detect-disease", files={"file": ("leaf.jpg", img_bytes, "image/jpeg")}, data={"lang": "en"})
print(f"Status Code: {res1.status_code}")
j1 = res1.json()
print(f"Disease: {j1.get('disease')}")
print(f"Dataset: {j1.get('dataset_name')}")
print(f"Patterns ({len(j1.get('matched_patterns', []))}): {j1.get('matched_patterns')}")
print(f"Exemplar Samples ({len(j1.get('dataset_reference_samples', []))}):")
for s in j1.get('dataset_reference_samples', []):
    print(f"  - {s.get('title')} -> {s.get('hallmark')}")

assert res1.status_code == 200
assert len(j1.get("dataset_reference_samples", [])) >= 2

print("\n🍎 2. Testing /classify-fruit for Ripeness Patterns & Dataset Exemplars...")
img_fruit = Image.new("RGB", (100, 100), color=(220, 20, 60))
f_bytes = io.BytesIO()
img_fruit.save(f_bytes, format="JPEG")

res2 = client.post("/classify-fruit", files={"file": ("fruit.jpg", f_bytes.getvalue(), "image/jpeg")}, data={"lang": "en"})
print(f"Status Code: {res2.status_code}")
j2 = res2.json()
print(f"Fruit: {j2.get('fruit')}")
print(f"Dataset: {j2.get('dataset_name')}")
print(f"Patterns ({len(j2.get('matched_patterns', []))}): {j2.get('matched_patterns')}")
print(f"Exemplar Samples ({len(j2.get('dataset_reference_samples', []))}):")
for s in j2.get('dataset_reference_samples', []):
    print(f"  - {s.get('title')} -> {s.get('hallmark')}")

assert res2.status_code == 200
assert len(j2.get("dataset_reference_samples", [])) >= 2

print("\n🌿 3. Testing /detect-weed for Botanical Patterns & Dataset Exemplars...")
img_weed = Image.new("RGB", (224, 224), color=(50, 150, 50))
w_bytes = io.BytesIO()
img_weed.save(w_bytes, format="JPEG")

res3 = client.post("/detect-weed", files={"file": ("weed.jpg", w_bytes.getvalue(), "image/jpeg")}, data={"lang": "en"})
print(f"Status Code: {res3.status_code}")
j3 = res3.json()
print(f"Weed: {j3.get('weed')}")
print(f"Robotic Decision: {j3.get('spray_decision')}")
print(f"Dataset: {j3.get('dataset_name')}")
print(f"Patterns ({len(j3.get('matched_patterns', []))}): {j3.get('matched_patterns')}")
print(f"Exemplar Samples ({len(j3.get('dataset_reference_samples', []))}):")
for s in j3.get('dataset_reference_samples', []):
    print(f"  - {s.get('title')} -> {s.get('hallmark')}")

assert res3.status_code == 200
assert len(j3.get("dataset_reference_samples", [])) >= 2

print("\n✅ All Vision AI Pattern Matching & Dataset Exemplar Generators Verified!")
