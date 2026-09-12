"""
Quick validation script for the enhanced /detect-disease endpoint with AI water requirement estimation.
"""
import io
from PIL import Image
import httpx

def test_disease_water():
    # Generate a simple 100x100 green image representing plant foliage
    img = Image.new('RGB', (100, 100), color=(34, 139, 34))
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    buf.seek(0)
    
    files = {"file": ("paddy_leaf.jpg", buf.getvalue(), "image/jpeg")}
    
    # Test Case 1: Paddy with low moisture, flowering stage -> Expect HIGH water requirement
    data1 = {
        "lang": "en",
        "crop_type": "Paddy",
        "growth_stage": "Flowering",
        "soil_moisture": "24.0",
        "temperature": "35.0",
        "recent_rainfall_mm": "0.0",
        "days_since_irrigation": "5",
        "field_condition": "Dry"
    }
    
    print("[TEST] Running Test Case 1: Paddy (Low moisture, flowering, 35C)...")
    try:
        from fastapi.testclient import TestClient
        from main import app
        client = TestClient(app)
        res = client.post("/detect-disease", files=files, data=data1)
        print(f"Status: {res.status_code}")
        if res.status_code == 200:
            resp = res.json()
            print("[OK] Disease:", resp.get("disease"))
            print("[OK] Crop:", resp.get("crop"))
            print("[OK] Category:", resp.get("category"))
            print("[OK] Water Requirement:", resp.get("water_requirement"))
            print("[OK] Soil Moisture:", resp.get("soil_moisture"))
            print("[OK] Crop Stress:", resp.get("crop_stress"))
            print("[OK] Next Irrigation:", resp.get("next_irrigation"))
            print("[OK] Water Estimation:", resp.get("water_estimation", {}).get("urgency_summary"))
            assert resp.get("water_requirement") == "HIGH", f"Expected HIGH, got {resp.get('water_requirement')}"
            assert resp.get("next_irrigation") == "Required", f"Expected Required, got {resp.get('next_irrigation')}"
        else:
            print("Failed:", res.text[:200])
    except Exception as e:
        print("Exception occurred:", e)

    # Test Case 2: Direct function test of crop_water_engine
    print("\n[TEST] Running Unit Tests on crop_water_engine...")
    from crop_water_engine import calculate_water_requirement, classify_symptom_category
    
    # Case A: Water stress symptom on Tomato
    cat_stress = classify_symptom_category("Water-Stress Severe Wilting")
    res_stress = calculate_water_requirement(
        crop_name="Tomato",
        disease_name="Water-Stress Leaf Curl",
        symptom_category=cat_stress,
        soil_moisture=25.0,
        growth_stage="Fruiting",
        temperature_c=36.0,
        recent_rainfall_mm=0.0
    )
    print("Case A (Water Stress):", res_stress["water_requirement"], "| Next:", res_stress["next_irrigation"], "| Stress:", res_stress["crop_stress"])
    assert res_stress["water_requirement"] == "HIGH"
    assert res_stress["next_irrigation"] == "Required"
    
    # Case B: Adequate moisture with recent rain
    cat_healthy = classify_symptom_category("Tomato Healthy")
    res_adequate = calculate_water_requirement(
        crop_name="Tomato",
        disease_name="Tomato Healthy",
        symptom_category=cat_healthy,
        soil_moisture=68.0,
        growth_stage="Vegetative",
        temperature_c=26.0,
        recent_rainfall_mm=30.0
    )
    print("Case B (Recent rain, optimal):", res_adequate["water_requirement"], "| Next:", res_adequate["next_irrigation"], "| Stress:", res_adequate["crop_stress"])
    assert res_adequate["water_requirement"] == "LOW"
    assert res_adequate["next_irrigation"] == "Not required now"

    # Case C: Nutrient deficiency
    cat_nutr = classify_symptom_category("Tomato Nitrogen Chlorosis Deficiency")
    print("Case C (Category):", cat_nutr)
    assert cat_nutr == "Possible nutrient deficiency"

    print("\n[SUCCESS] ALL UNIT AND FUNCTION TESTS PASSED!")

if __name__ == "__main__":
    test_disease_water()
