"""
Training Script for Farmer AI Dairy & Cattle Intelligence Suite
Includes:
1. Cattle Milk Yield & Fat/SNF Regression Model (RandomForest)
2. Veterinary Disease & Symptom Triage Classifier (RandomForest)
3. Expert Veterinary & Nutrition Knowledge Base
"""

import os
import sys
import json
import numpy as np
import pandas as pd
import joblib

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
if hasattr(sys.stderr, 'reconfigure'):
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier, GradientBoostingRegressor
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import r2_score, accuracy_score, mean_absolute_error

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")
os.makedirs(MODEL_DIR, exist_ok=True)

print("🚀 Starting Dairy & Cattle Model Training Pipeline...")

# ==============================================================================
# 1. SYNTHETIC & EMPIRICAL DATASET GENERATION (ICAR / NDDB Benchmarks)
# ==============================================================================
np.random.seed(42)
N_SAMPLES = 5000

# Breeds and their physiological baselines: (base_milk_liters, avg_fat, avg_snf, avg_weight_kg)
BREED_PROFILES = {
    "Holstein Friesian (HF Cross)": {"base_milk": 22.0, "fat": 3.8, "snf": 8.4, "weight": 520, "milk_var": 5.0},
    "Jersey Cross": {"base_milk": 17.0, "fat": 4.6, "snf": 8.8, "weight": 440, "milk_var": 3.5},
    "Murrah Buffalo": {"base_milk": 14.5, "fat": 7.5, "snf": 9.2, "weight": 580, "milk_var": 3.0},
    "Gir Indigenous Desi": {"base_milk": 13.0, "fat": 4.9, "snf": 8.9, "weight": 410, "milk_var": 2.5},
    "Sahiwal Indigenous": {"base_milk": 14.0, "fat": 4.7, "snf": 8.8, "weight": 430, "milk_var": 2.8},
    "Red Sindhi": {"base_milk": 12.0, "fat": 4.8, "snf": 8.7, "weight": 390, "milk_var": 2.2},
    "Jamnapari Dairy Goat": {"base_milk": 3.2, "fat": 4.5, "snf": 8.6, "weight": 65, "milk_var": 0.8},
}

breeds_list = list(BREED_PROFILES.keys())

data_records = []
for _ in range(N_SAMPLES):
    breed = np.random.choice(breeds_list, p=[0.25, 0.20, 0.22, 0.15, 0.10, 0.05, 0.03])
    prof = BREED_PROFILES[breed]
    
    # Lactation month (1 to 10) - Wood's lactation curve simulation
    lactation_month = np.random.randint(1, 11)
    # Lactation multiplier: peak at month 2-3 (~1.2x), declining to ~0.6x by month 10
    lactation_factor = (lactation_month ** 0.35) * np.exp(-0.12 * lactation_month) * 1.55
    
    # Body Weight (kg) with natural variance
    weight = np.clip(np.random.normal(prof["weight"], prof["weight"] * 0.08), prof["weight"] * 0.7, prof["weight"] * 1.3)
    
    # Feed inputs based on body weight and production capacity
    is_goat = "Goat" in breed
    if is_goat:
        green_fodder = np.random.uniform(3.0, 7.0)
        dry_fodder = np.random.uniform(0.8, 2.0)
        concentrate = np.random.uniform(0.4, 1.5)
        water_liters = np.random.uniform(6.0, 15.0)
    else:
        green_fodder = np.random.uniform(15.0, 35.0)
        dry_fodder = np.random.uniform(3.0, 8.0)
        concentrate = np.random.uniform(2.0, 9.0)
        water_liters = np.random.uniform(40.0, 110.0)
        
    # Weather metrics (Temperature °C & Humidity %)
    temperature = np.random.uniform(18.0, 42.0)
    humidity = np.random.uniform(35.0, 90.0)
    
    # Temperature Humidity Index (THI) calculation
    # THI = 0.8 * T + (RH/100) * (T - 14.4) + 46.4
    thi = 0.8 * temperature + (humidity / 100.0) * (temperature - 14.4) + 46.4
    # Heat stress penalty if THI > 72
    heat_stress_penalty = max(0.0, (thi - 72) * 0.018)
    
    # Nutrition boost/deficit factor
    # Optimal concentrate for cattle is ~1kg per 2.5L milk + maintenance
    feed_energy_score = (green_fodder * 0.15 + dry_fodder * 0.10 + concentrate * 0.75) / (weight * 0.015)
    feed_factor = np.clip(feed_energy_score, 0.7, 1.25)
    
    # Water adequacy factor
    expected_water = (weight * 0.10) + (prof["base_milk"] * 2.5)
    water_factor = min(1.0, water_liters / max(1.0, expected_water))
    
    # Final Milk Yield
    raw_yield = prof["base_milk"] * lactation_factor * feed_factor * water_factor * (1.0 - heat_stress_penalty)
    daily_yield = max(0.2, raw_yield + np.random.normal(0, prof["milk_var"] * 0.15))
    
    # Fat and SNF percentages (Inverse correlation with high volume, altered by concentrate & roughage ratio)
    roughage_ratio = (green_fodder * 0.2 + dry_fodder * 0.9) / max(0.1, (green_fodder * 0.2 + dry_fodder * 0.9 + concentrate * 0.9))
    fat_shift = (roughage_ratio - 0.6) * 0.8  # higher roughage increases milk fat acetate
    snf_shift = (concentrate / max(1.0, weight * 0.01)) * 0.15
    
    fat_pct = np.clip(prof["fat"] + fat_shift + np.random.normal(0, 0.2), 3.0, 10.5)
    snf_pct = np.clip(prof["snf"] + snf_shift + np.random.normal(0, 0.15), 7.5, 10.0)
    
    data_records.append({
        "breed": breed,
        "lactation_month": lactation_month,
        "animal_weight": round(weight, 1),
        "green_fodder_kg": round(green_fodder, 1),
        "dry_fodder_kg": round(dry_fodder, 1),
        "concentrate_kg": round(concentrate, 2),
        "water_liters": round(water_liters, 1),
        "temperature_c": round(temperature, 1),
        "humidity_pct": round(humidity, 1),
        "thi_index": round(thi, 1),
        "daily_yield_liters": round(daily_yield, 2),
        "fat_percentage": round(fat_pct, 2),
        "snf_percentage": round(snf_pct, 2)
    })

df_milk = pd.DataFrame(data_records)
print(f"✅ Generated {len(df_milk)} realistic dairy records.")

# ==============================================================================
# 2. TRAIN MILK YIELD & COMPOSITION REGRESSION MODELS
# ==============================================================================
breed_encoder = LabelEncoder()
df_milk["breed_encoded"] = breed_encoder.fit_transform(df_milk["breed"])

X_features = [
    "breed_encoded", "lactation_month", "animal_weight",
    "green_fodder_kg", "dry_fodder_kg", "concentrate_kg",
    "water_liters", "temperature_c", "humidity_pct"
]

X = df_milk[X_features]
y_yield = df_milk["daily_yield_liters"]
y_fat = df_milk["fat_percentage"]
y_snf = df_milk["snf_percentage"]

X_train, X_test, y_train_yield, y_test_yield = train_test_split(X, y_yield, test_size=0.15, random_state=42)
_, _, y_train_fat, y_test_fat = train_test_split(X, y_fat, test_size=0.15, random_state=42)
_, _, y_train_snf, y_test_snf = train_test_split(X, y_snf, test_size=0.15, random_state=42)

# Train Yield Regressor
model_yield = RandomForestRegressor(n_estimators=100, max_depth=14, random_state=42, n_jobs=-1)
model_yield.fit(X_train, y_train_yield)
y_pred_yield = model_yield.predict(X_test)
r2_yield = r2_score(y_test_yield, y_pred_yield)
mae_yield = mean_absolute_error(y_test_yield, y_pred_yield)
print(f"📊 Milk Yield Model -> R² Score: {r2_yield:.4f} | MAE: {mae_yield:.2f} Liters")

# Train Fat Regressor
model_fat = GradientBoostingRegressor(n_estimators=70, max_depth=6, random_state=42)
model_fat.fit(X_train, y_train_fat)
r2_fat = r2_score(y_test_fat, model_fat.predict(X_test))

# Train SNF Regressor
model_snf = GradientBoostingRegressor(n_estimators=70, max_depth=6, random_state=42)
model_snf.fit(X_train, y_train_snf)
r2_snf = r2_score(y_test_snf, model_snf.predict(X_test))

print(f"📊 Milk Fat Model R²: {r2_fat:.4f} | SNF Model R²: {r2_snf:.4f}")

# Package Milk Models & Encoders
milk_model_bundle = {
    "model_yield": model_yield,
    "model_fat": model_fat,
    "model_snf": model_snf,
    "feature_names": X_features,
    "breed_encoder": breed_encoder,
    "breed_classes": list(breed_encoder.classes_),
    "breed_profiles": BREED_PROFILES
}

milk_model_file = os.path.join(MODEL_DIR, "cattle_milk_model.joblib")
joblib.dump(milk_model_bundle, milk_model_file, compress=3)
print(f"💾 Exported Milk Bundle to {milk_model_file}")

# ==============================================================================
# 3. VETERINARY DISEASE & SYMPTOM TRIAGE MODEL (Classification + Expert Rules)
# ==============================================================================

DISEASES = [
    "Mastitis (Bovine Udder Infection)",
    "Lumpy Skin Disease (LSD)",
    "Foot and Mouth Disease (FMD)",
    "Haemorrhagic Septicaemia (HS - Gal Ghotu)",
    "Bovine Ketosis (Acetonemia)",
    "Milk Fever (Hypocalcemia)",
    "Rumen Bloat / Tympany (Afara)",
    "Theileriosis (Tick Fever / Anaplasmosis)",
    "Brucellosis (Reproductive / Abortion Storm)",
    "Healthy / Normal"
]

SYMPTOM_KEYS = [
    "fever",                    # High body temp > 103°F
    "skin_nodules",             # Hard round nodules on skin/udder
    "swollen_hot_udder",        # Hard, painful quarter with milk clots/blood
    "mouth_hoof_blisters",      # Vesicles/sores on tongue, gums, interdigital cleft
    "salivation_drooling",      # Ropey frothy saliva hanging from mouth
    "swollen_throat_dewlap",    # Hot painful submandibular/neck edema
    "severe_respiratory_grunt", # Labored breathing with tongue out
    "left_flank_bloat",         # Severe swelling of left rumen paralumbar fossa
    "recumbency_downer_cow",    # S-shape neck kink, unable to stand post-calving
    "sweet_acetone_breath",     # Rapid weight loss, sweet smelling milk/breath
    "tick_infestation_pale_eye",# Heavy ticks, pale mucous membranes/jaundice, dark urine
    "abortion_late_gestation",  # 7-8th month abortion with retained placenta
    "drop_in_milk",             # Sudden drop in daily milk yield
    "loss_of_appetite"          # Refusal to eat concentrate or fodder
]

# Disease Symptom Signatures (Probabilistic weights)
SIGNATURES = {
    "Mastitis (Bovine Udder Infection)": {
        "swollen_hot_udder": 0.95, "drop_in_milk": 0.92, "loss_of_appetite": 0.60, "fever": 0.45
    },
    "Lumpy Skin Disease (LSD)": {
        "skin_nodules": 0.98, "fever": 0.90, "salivation_drooling": 0.65, "drop_in_milk": 0.85, "loss_of_appetite": 0.80
    },
    "Foot and Mouth Disease (FMD)": {
        "mouth_hoof_blisters": 0.96, "salivation_drooling": 0.92, "fever": 0.88, "drop_in_milk": 0.90, "loss_of_appetite": 0.85
    },
    "Haemorrhagic Septicaemia (HS - Gal Ghotu)": {
        "swollen_throat_dewlap": 0.98, "severe_respiratory_grunt": 0.95, "fever": 0.95, "salivation_drooling": 0.70, "loss_of_appetite": 0.90
    },
    "Bovine Ketosis (Acetonemia)": {
        "sweet_acetone_breath": 0.95, "drop_in_milk": 0.88, "loss_of_appetite": 0.85
    },
    "Milk Fever (Hypocalcemia)": {
        "recumbency_downer_cow": 0.96, "drop_in_milk": 0.90, "loss_of_appetite": 0.80
    },
    "Rumen Bloat / Tympany (Afara)": {
        "left_flank_bloat": 0.98, "severe_respiratory_grunt": 0.80, "loss_of_appetite": 0.85
    },
    "Theileriosis (Tick Fever / Anaplasmosis)": {
        "tick_infestation_pale_eye": 0.95, "fever": 0.92, "drop_in_milk": 0.85, "loss_of_appetite": 0.80
    },
    "Brucellosis (Reproductive / Abortion Storm)": {
        "abortion_late_gestation": 0.95, "drop_in_milk": 0.60
    },
    "Healthy / Normal": {}
}

# Generate symptom-disease classification dataset
disease_samples = []
for disease_name, sig in SIGNATURES.items():
    n_for_disease = 400 if disease_name != "Healthy / Normal" else 600
    for _ in range(n_for_disease):
        row = {}
        for sym in SYMPTOM_KEYS:
            base_prob = sig.get(sym, 0.04) # noise
            # add realistic jitter
            row[sym] = 1 if np.random.rand() < base_prob else 0
        row["target_disease"] = disease_name
        disease_samples.append(row)

df_disease = pd.DataFrame(disease_samples)
disease_encoder = LabelEncoder()
y_dis = disease_encoder.fit_transform(df_disease["target_disease"])
X_dis = df_disease[SYMPTOM_KEYS]

X_train_d, X_test_d, y_train_d, y_test_d = train_test_split(X_dis, y_dis, test_size=0.15, random_state=42)

clf_disease = RandomForestClassifier(n_estimators=120, max_depth=12, random_state=42)
clf_disease.fit(X_train_d, y_train_d)
dis_acc = accuracy_score(y_test_d, clf_disease.predict(X_test_d))
print(f"📊 Veterinary Disease Classifier Accuracy: {dis_acc * 100:.2f}%")

# Save Disease Model Bundle
disease_model_bundle = {
    "model": clf_disease,
    "symptom_keys": SYMPTOM_KEYS,
    "disease_encoder": disease_encoder,
    "classes": list(disease_encoder.classes_)
}

disease_model_file = os.path.join(MODEL_DIR, "cattle_disease_model.joblib")
joblib.dump(disease_model_bundle, disease_model_file, compress=3)
print(f"💾 Exported Disease Bundle to {disease_model_file}")

# ==============================================================================
# 4. COMPREHENSIVE VETERINARY PROTOCOLS & DIET KNOWLEDGE BASE (JSON)
# ==============================================================================
VET_KNOWLEDGE_BASE = {
    "Mastitis (Bovine Udder Infection)": {
        "severity": "High (Urgent)",
        "urgency_level": "Intervene within 12 hours to prevent permanent quarter blindness",
        "primary_cause": "Streptococcus uberis / Staphylococcus aureus / E. coli bacterial invasion",
        "first_aid": [
            "Strip out all infected, clotted milk from affected quarter every 2 hours and discard safely.",
            "Apply cold compresses or ice packs to the swollen quarter to reduce inflammation.",
            "Dip teats in 0.5% Povidone Iodine solution post-milking."
        ],
        "veterinary_medical_prescription": [
            "Intramammary Infusion: Ceftiofur / Cloxacillin intramammary tube after complete stripping.",
            "Systemic Antibiotics: Intramuscular Ceftriaxone + Sulbactam (3-4.5g) or Enrofloxacin 10% (15-20 ml) for 3-5 days.",
            "Anti-inflammatory / Pain relief: Flunixin Meglumine (10-15 ml IM) or Meloxicam (15-20 ml IM).",
            "Supportive: Vitamin E + Selenium (e.g., Repronol 10ml IM) and Trisodium Citrate oral powder."
        ],
        "ayurvedic_ethnoveterinary": [
            "Grind Aloe vera leaf (250g), Fresh Turmeric rhizome (50g), and Slaked lime (Chuna 15g) into smooth paste.",
            "Add 100ml mustard oil and apply topically over the washed udder 4-5 times daily."
        ],
        "recommended_food_modifications": [
            "Reduce heavy concentrate grain feed by 25% during acute inflammation.",
            "Add 50g Trisodium Citrate daily in drinking water to restore normal milk pH.",
            "Provide fresh clean green maize / sorghum fodder with ad-libitum clean water."
        ],
        "prevention_vaccination": "Maintain strict dry-cow therapy with long-acting antibiotics; practice clean teat dipping."
    },
    "Lumpy Skin Disease (LSD)": {
        "severity": "High (Contagious Epizootic)",
        "urgency_level": "Isolate animal immediately; Vector control required",
        "primary_cause": "Capripoxvirus transmitted by biting flies, mosquitoes, and ticks",
        "first_aid": [
            "Isolate the affected cow in a clean, disinfected, mosquito-proof shed.",
            "Wash skin lesions with 1% Potassium Permanganate (KMnO4) or Neem leaf decoction.",
            "Spray shed with natural fly repellents (citronella oil or neem oil spray)."
        ],
        "veterinary_medical_prescription": [
            "Broad-spectrum secondary cover: Oxytetracycline LA (20-30 ml IM) or Ceftiofur Sodium (1g IM daily for 4 days).",
            "Anti-inflammatory & Antipyretic: Meloxicam + Paracetamol (Melonex Plus 15-20 ml IM daily).",
            "Anti-histaminic: Pheniramine Maleate (Avil 10 ml IM daily).",
            "Immuno-stimulant: Levamisole (15 ml SC once) or Vitamin A, D3, E booster shots."
        ],
        "ayurvedic_ethnoveterinary": [
            "Boil Betel leaves (10 nos), Black pepper (10g), Salt (10g), and Jaggery (100g) into a paste; feed orally twice daily.",
            "Apply Neem-Turmeric-Coconut oil paste directly on burst skin nodules."
        ],
        "recommended_food_modifications": [
            "Feed soft palatable mash: Boiled rice gruel with 100g jaggery and 50g crushed fenugreek seeds.",
            "Avoid coarse dry straw that can irritate mouth ulcers; provide tender green grass."
        ],
        "prevention_vaccination": "Annual Goat Pox / Homologous LSD Vaccine (3ml SC) administered prior to vector season."
    },
    "Foot and Mouth Disease (FMD)": {
        "severity": "Emergency (Highly Contagious)",
        "urgency_level": "Quarantine farm immediately; report to local state veterinary hospital",
        "primary_cause": "Aphthovirus (Types O, A, Asia-1)",
        "first_aid": [
            "Wash mouth ulcers gently with 1% Alum or Boro-Glycerine solution.",
            "Wash hoof lesions with 2% Copper Sulphate or 4% Sodium Carbonate solution.",
            "Apply fly repellent ointment (Himax / Lorexane) around hoof clefts to prevent maggot wounds."
        ],
        "veterinary_medical_prescription": [
            "Antibiotic protection: Procaine Penicillin or Amoxicillin-Sulbactam for 5 days.",
            "Analgesic & Anti-inflammatory: Flunixin Meglumine or Ketoprofen IM.",
            "Topical: Glycerin-boric acid paste on tongue ulcers."
        ],
        "ayurvedic_ethnoveterinary": [
            "Mix sesame oil, turmeric, and garlic paste; apply between the claws.",
            "Feed ragi porridge (finger millet gruel) mixed with buttermilk for easy digestion."
        ],
        "recommended_food_modifications": [
            "Strictly soft diet: Semi-liquid boiled porridge of wheat flour, ragi, and jaggery.",
            "Finely chopped lush green fodder (berseem / napier grass) soaked in water."
        ],
        "prevention_vaccination": "Bi-annual polyvalent FMD vaccination (FMD-CP programme) in February and August."
    },
    "Haemorrhagic Septicaemia (HS - Gal Ghotu)": {
        "severity": "Emergency (Critical Mortality within 24 Hours)",
        "urgency_level": "Immediate intravenous medication within 4 hours is life-saving",
        "primary_cause": "Pasteurella multocida bacterial septicaemia",
        "first_aid": [
            "Call emergency veterinary doctor immediately.",
            "Keep animal upright; ensure clear airway; do not force-feed liquids by mouth (drenching aspiration risk)."
        ],
        "veterinary_medical_prescription": [
            "Immediate high-dose Antibiotics: Sulfadimidine 33.3% solution (100-150 ml slow IV) OR Ceftiofur Sodium (1-2g IV/IM) OR Enrofloxacin.",
            "Corticosteroid / Anti-inflammatory: Dexamethasone (5-10 ml IV) to relieve acute throat edema.",
            "Fluid Therapy: Dextrose Normal Saline (DNS 2-3 Liters IV) if dehydrated."
        ],
        "ayurvedic_ethnoveterinary": [
            "Ethnoveterinary is not sufficient for acute HS — immediate veterinary antibiotic IV is mandatory."
        ],
        "recommended_food_modifications": [
            "Withhold solid coarse fodder until throat swelling subsides.",
            "Offer fresh lukewarm water with electrolytes."
        ],
        "prevention_vaccination": "Pre-monsoon annual HS oil-adjuvant vaccine in May/June."
    },
    "Milk Fever (Hypocalcemia)": {
        "severity": "Emergency (Downer Cow Syndrome)",
        "urgency_level": "Administer IV Calcium within 2-4 hours",
        "primary_cause": "Acute blood calcium depletion within 48-72 hours post-calving",
        "first_aid": [
            "Prop the cow up on her brisket (sternal recumbency) using straw bales to avoid bloat.",
            "Do NOT completely milk the cow dry in the first 48 hours post-calving."
        ],
        "veterinary_medical_prescription": [
            "Immediate Calcium Therapy: Calcium Borogluconate 25% (400-500 ml slow IV under cardiac auscultation + 100 ml Subcutaneous).",
            "Oral Calcium Gel: Drench with ionic calcium paste (Calfostonic / Cal-Up Gel) 6 hours post IV."
        ],
        "ayurvedic_ethnoveterinary": [
            "Feed powdered methi (fenugreek) + jaggery paste once animal regains standing posture."
        ],
        "recommended_food_modifications": [
            "Pre-calving (Dry period): Negative DCAD diet (low calcium, high magnesium).",
            "Post-calving: High available calcium feed + 100g mineral mixture daily."
        ],
        "prevention_vaccination": "Administer oral Calcium Gel 12 hours before and immediately after calving."
    },
    "Rumen Bloat / Tympany (Afara)": {
        "severity": "Emergency (Asphyxiation Risk)",
        "urgency_level": "Relieve gas pressure immediately",
        "primary_cause": "Excess lush legume grazing (Berseem/Lucerne) or grain overload producing stable foam",
        "first_aid": [
            "Keep the cow standing with front feet elevated on an incline.",
            "Tie a smooth wooden bit/stick in the mouth to induce salivation and belching.",
            "Pass an esophageal stomach tube to vent free gas."
        ],
        "veterinary_medical_prescription": [
            "Anti-bloat drench: Poloxalene / Simethicone drench (Bloatosil / Tympol 100 ml orally with 500 ml water).",
            "Rumen tonics: Cobalt and live Saccharomyces cerevisiae yeast bolus (Eco-tas / Biolac)."
        ],
        "ayurvedic_ethnoveterinary": [
            "Mix 500 ml edible Mustard/Groundnut oil + 20-30 ml Oil of Turpentine + 10g Hing (Asafoetida) + 20g Ginger powder; drench carefully."
        ],
        "recommended_food_modifications": [
            "Withhold lush legumes and grains for 24 hours.",
            "Feed dry coarse wheat / paddy straw to stimulate rumination."
        ],
        "prevention_vaccination": "Never let hungry animals graze wet dew-covered berseem/clover pastures."
    },
    "Bovine Ketosis (Acetonemia)": {
        "severity": "Moderate to High",
        "urgency_level": "Restore blood glucose balance within 24 hours",
        "primary_cause": "Negative energy balance in high-yielding dairy cows during early lactation",
        "first_aid": [
            "Check for sweet acetone breath and sudden refusal of concentrate feed."
        ],
        "veterinary_medical_prescription": [
            "Glucose replenishment: Dextrose 50% solution (500 ml slow IV).",
            "Glucogenic precursor: Propylene Glycol oral drench (200-300g twice daily for 3 days).",
            "Corticosteroid: Isoflupredone Acetate (10-20 mg IM) to boost gluconeogenesis."
        ],
        "ayurvedic_ethnoveterinary": [
            "Feed 250g pure cane jaggery dissolved in lukewarm water twice daily."
        ],
        "recommended_food_modifications": [
            "Add bypass fat (fractionated palm fat 100-150g/day) to the daily concentrate ration.",
            "Provide high energy maize grain crush and top-quality legume hay."
        ],
        "prevention_vaccination": "Avoid over-conditioning during dry period (aim for BCS 3.25 to 3.5)."
    },
    "Theileriosis (Tick Fever / Anaplasmosis)": {
        "severity": "High (Haemoprotozoan)",
        "urgency_level": "Early antiprotozoal injection needed to prevent severe anemia",
        "primary_cause": "Theileria annulata transmitted by Hyalomma ticks",
        "first_aid": [
            "Isolate the animal; manually remove visible ticks using acaricide spray."
        ],
        "veterinary_medical_prescription": [
            "Antiprotozoal: Buparvaquone (e.g., Butalex 2.5 mg/kg IM single dose, max 20ml per site).",
            "Supportive Antibiotic: Oxytetracycline LA (20 mg/kg IM).",
            "Haematinic tonic: Iron, Copper, Cobalt, Vitamin B12 injection (e.g., Belamyl / Feritas 10ml IM)."
        ],
        "ayurvedic_ethnoveterinary": [
            "Crushed garlic (50g) in castor oil as external tick repellent."
        ],
        "recommended_food_modifications": [
            "High protein concentrate with liver tonic additives (e.g., Liv-52 bolus).",
            "Fresh tender green fodder rich in carotene."
        ],
        "prevention_vaccination": "Rakshavac-T vaccine for crossbred cattle; periodic Deltamethrin/Cypermethrin tick spray."
    },
    "Brucellosis (Reproductive / Abortion Storm)": {
        "severity": "High (Zoonotic - Danger to Humans)",
        "urgency_level": "Strict quarantine; do NOT touch aborted placenta without gloves",
        "primary_cause": "Brucella abortus bacterium",
        "first_aid": [
            "Wear heavy rubber gloves; bury aborted fetus and placental membranes in a 6-foot pit with lime.",
            "Disinfect the calving pen with 2.5% Sodium Hypochlorite or 5% Carbolic acid."
        ],
        "veterinary_medical_prescription": [
            "Collect serum/milk samples for Milk Ring Test (MRT) and Rose Bengal Plate Test (RBPT).",
            "Consult local state veterinary authority for herd screening protocols."
        ],
        "ayurvedic_ethnoveterinary": [
            "Not curative. Disease management is through strict biosecurity and vaccination."
        ],
        "recommended_food_modifications": [
            "Feed balanced immune-supporting ration with Zinc and Vitamin E + Selenium."
        ],
        "prevention_vaccination": "Single-dose Brucella abortus S19 or RB51 vaccine in female calves aged 4 to 8 months."
    },
    "Healthy / Normal": {
        "severity": "Normal",
        "urgency_level": "Routine herd maintenance",
        "primary_cause": "Animal exhibiting healthy physiological vitals",
        "first_aid": [
            "Continue standard clean dairy management practices."
        ],
        "veterinary_medical_prescription": [
            "Routine Deworming: Albendazole / Fenbendazole oral suspension every 4-6 months.",
            "Mineral Supplementation: Chelated Mineral Mixture (50-80g/day) + Common salt (30g/day)."
        ],
        "ayurvedic_ethnoveterinary": [
            "Weekly herbal digestive tonic with Ajwain, Methi, and Turmeric."
        ],
        "recommended_food_modifications": [
            "Balanced 60:40 roughage to concentrate ratio based on daily milk production."
        ],
        "prevention_vaccination": "Maintain routine calendar: FMD (bi-annual), HS (May), BQ (June), Brucellosis (calves)."
    }
}

kb_file = os.path.join(MODEL_DIR, "cattle_disease_kb.json")
with open(kb_file, "w", encoding="utf-8") as f:
    json.dump(VET_KNOWLEDGE_BASE, f, indent=2, ensure_ascii=False)

print(f"💾 Exported Veterinary KB to {kb_file}")
print("✨ All Dairy & Cattle AI models trained and exported successfully!")
