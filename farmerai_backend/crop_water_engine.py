"""
AI Crop Water Requirement & Multi-Symptom Pathology Engine.
Calculates dynamic plant water requirements combining computer vision pathology,
soil moisture telemetry, crop phenology stage, and microclimate parameters.
"""

from typing import Dict, Any, Optional

# Multi-class pathology categorization mappings
NUTRIENT_DEFICIENCY_KEYWORDS = [
    "deficiency", "chlorosis", "nitrogen", "potassium", "phosphorus",
    "zinc", "iron", "magnesium", "calcium", "blossom end rot", "scorch", "purpling"
]

WATER_STRESS_KEYWORDS = [
    "water-stress", "drought", "wilting", "leaf curl", "spider mites",
    "tip burn", "desiccation", "leaf roll", "turgor loss", "sunscald"
]

# Baseline crop water metrics: (optimal_min_moisture%, optimal_max_moisture%, peak_stage_multiplier)
CROP_WATER_SPECS = {
    "paddy": {"min_sm": 60.0, "max_sm": 90.0, "kc_flower": 1.25, "method": "Controlled shallow ponding / AWD"},
    "rice": {"min_sm": 60.0, "max_sm": 90.0, "kc_flower": 1.25, "method": "Alternate Wetting and Drying (AWD)"},
    "tomato": {"min_sm": 55.0, "max_sm": 75.0, "kc_flower": 1.15, "method": "Root-zone drip irrigation (avoid wetting leaves)"},
    "potato": {"min_sm": 60.0, "max_sm": 80.0, "kc_flower": 1.15, "method": "Furrow / Drip irrigation at tuber bulking"},
    "corn": {"min_sm": 50.0, "max_sm": 70.0, "kc_flower": 1.20, "method": "Furrow irrigation (critical during silking)"},
    "maize": {"min_sm": 50.0, "max_sm": 70.0, "kc_flower": 1.20, "method": "Furrow irrigation (critical during silking)"},
    "cotton": {"min_sm": 45.0, "max_sm": 65.0, "kc_flower": 1.10, "method": "Alternate furrow drip (avoid excess standing water)"},
    "wheat": {"min_sm": 50.0, "max_sm": 70.0, "kc_flower": 1.15, "method": "Border strip irrigation at CRI & flowering"},
    "chilli": {"min_sm": 50.0, "max_sm": 70.0, "kc_flower": 1.10, "method": "Micro-drip irrigation at morning"},
    "pepper": {"min_sm": 50.0, "max_sm": 70.0, "kc_flower": 1.10, "method": "Micro-drip irrigation"},
    "grape": {"min_sm": 45.0, "max_sm": 65.0, "kc_flower": 0.85, "method": "Precision drip beneath vine trellis"},
    "apple": {"min_sm": 55.0, "max_sm": 75.0, "kc_flower": 1.05, "method": "Basin / micro-sprinkler at orchard floor"}
}

# 🌾 COMPREHENSIVE AGRONOMIC CROP WATER & PHENOLOGY KNOWLEDGE BASE
CROP_WATER_SPECS_DETAILED = {
    "paddy": {
        "crop_display": "Paddy (Rice)",
        "min_mm": 1100,
        "max_mm": 1450,
        "avg_mm": 1250,
        "water_need_text": "1100 - 1450 mm",
        "category": "Very High",
        "critical_stages": "Panicle initiation, Tillering, Flowering, Milk stage",
        "critical_stages_te": "పిలకల దశ, పూత దశ, గింజ పాలుపోసుకునే సమయం",
        "critical_stages_hi": "कल्ले फूटने का समय, फूल आना और दाना भराव अवस्था",
        "irrigation_method": "Alternate Wetting and Drying (AWD) / Controlled shallow ponding",
        "irrigation_method_te": "ఆల్టర్నేట్ వెట్టింగ్ అండ్ డ్రైయింగ్ (AWD) / నియంత్రిత నిలిచిన నీరు",
        "irrigation_method_hi": "वैकल्पिक गीला और सूखा (AWD) या नियंत्रित उथली सिंचाई",
        "soil_affinity": "Clay, clay loam, heavy black soils with strong water retention",
        "drought_tolerance": "Low"
    },
    "rice": {
        "crop_display": "Rice",
        "min_mm": 1100,
        "max_mm": 1450,
        "avg_mm": 1250,
        "water_need_text": "1100 - 1450 mm",
        "category": "Very High",
        "critical_stages": "Panicle initiation, Tillering, Flowering",
        "critical_stages_te": "పిలకల దశ, పూత దశ, గింజ పాలుపోసుకునే సమయం",
        "critical_stages_hi": "कल्ले फूटने का समय, फूल आना और दाना भराव अवस्था",
        "irrigation_method": "Alternate Wetting and Drying (AWD) / Controlled shallow ponding",
        "irrigation_method_te": "ఆల్టర్నేట్ వెట్టింగ్ అండ్ డ్రైయింగ్ (AWD) / నియంత్రిత నిలిచిన నీరు",
        "irrigation_method_hi": "वैकल्पिक गीला और सूखा (AWD) या नियंत्रित उथली सिंचाई",
        "soil_affinity": "Clay and heavy black soils",
        "drought_tolerance": "Low"
    },
    "cotton": {
        "crop_display": "Cotton",
        "min_mm": 650,
        "max_mm": 750,
        "avg_mm": 700,
        "water_need_text": "650 - 750 mm",
        "category": "Moderate to High",
        "critical_stages": "Squaring, Flowering, Boll formation and development",
        "critical_stages_te": "మొగ్గ తొడిగే దశ, పూత దశ, కాయ తయారయ్యే సమయం",
        "critical_stages_hi": "कलियां बनना, फूल आना और गूलर (बॉल) का विकास",
        "irrigation_method": "Alternate furrow irrigation or root-zone Drip system",
        "irrigation_method_te": "ఒకటి విడిచి ఒకటి సాళ్ళు లేదా డ్రిప్ బిందు సేద్యం",
        "irrigation_method_hi": "एकान्तर नाली या ड्रिप बूंद-बूंद सिंचाई",
        "soil_affinity": "Deep black soils, fertile clay loams",
        "drought_tolerance": "Moderate"
    },
    "maize": {
        "crop_display": "Maize (Corn)",
        "min_mm": 500,
        "max_mm": 650,
        "avg_mm": 575,
        "water_need_text": "500 - 650 mm",
        "category": "Moderate",
        "critical_stages": "Knee-high, Tasseling, Silking, Grain development",
        "critical_stages_te": "మోకాలు ఎత్తు దశ, పూత (టాసలింగ్), కండె గింజ కట్టే సమయం",
        "critical_stages_hi": "घुटने तक ऊंचाई, मंजरी (सिल्किंग) और दाना भराव",
        "irrigation_method": "Furrow irrigation or Rain-gun sprinkler",
        "irrigation_method_te": "కాలువ పారుదల లేదా స్ప్రింక్లర్ పద్ధతి",
        "irrigation_method_hi": "नाली सिंचाई या फव्वारा सिंचाई",
        "soil_affinity": "Well-drained loam, alluvial, and medium black soils",
        "drought_tolerance": "Moderate"
    },
    "corn": {
        "crop_display": "Corn (Maize)",
        "min_mm": 500,
        "max_mm": 650,
        "avg_mm": 575,
        "water_need_text": "500 - 650 mm",
        "category": "Moderate",
        "critical_stages": "Knee-high, Tasseling, Silking, Grain development",
        "critical_stages_te": "మోకాలు ఎత్తు దశ, పూత (టాసలింగ్), కండె గింజ కట్టే సమయం",
        "critical_stages_hi": "घुटने तक ऊंचाई, मंजरी (सिल्किंग) और दाना भराव",
        "irrigation_method": "Furrow irrigation or Rain-gun sprinkler",
        "irrigation_method_te": "కాలువ పారుదల లేదా స్ప్రింక్లర్ పద్ధతి",
        "irrigation_method_hi": "नाली सिंचाई या फव्वारा सिंचाई",
        "soil_affinity": "Well-drained loam, alluvial, and medium black soils",
        "drought_tolerance": "Moderate"
    },
    "groundnut": {
        "crop_display": "Groundnut",
        "min_mm": 450,
        "max_mm": 550,
        "avg_mm": 500,
        "water_need_text": "450 - 550 mm",
        "category": "Low to Moderate",
        "critical_stages": "Flowering, Peg penetration, Pod development",
        "critical_stages_te": "పూత దశ, ఊడలు దిగే సమయం, కాయ తయారీ దశ",
        "critical_stages_hi": "फूल आना, सूइयां बनना (पेगिंग) और फली विकास",
        "irrigation_method": "Sprinkler or light furrow (prevent waterlogging)",
        "irrigation_method_te": "స్ప్రింక్లర్ లేదా తేలికపాటి తడులు (నీరు నిల్వ ఉండరాదు)",
        "irrigation_method_hi": "फव्वारा सिंचाई या हल्की नाली सिंचाई",
        "soil_affinity": "Red sandy loam, loose textured well-drained soils",
        "drought_tolerance": "High"
    },
    "chilli": {
        "crop_display": "Chilli",
        "min_mm": 600,
        "max_mm": 700,
        "avg_mm": 650,
        "water_need_text": "600 - 700 mm",
        "category": "Moderate",
        "critical_stages": "Flowering, Fruit set, Fruit development",
        "critical_stages_te": "పూత దశ, కాయ పిందె కట్టే దశ, కాయ ఎదుగుదల",
        "critical_stages_hi": "फूल आना, फल लगना और मिर्च का विकास काल",
        "irrigation_method": "Precision Drip irrigation with fertigation",
        "irrigation_method_te": "బిందు సేద్యం (డ్రిప్) ద్వారా నీరు మరియు ఎరువుల నిర్వహణ",
        "irrigation_method_hi": "ड्रिप सिंचाई और उर्वरक प्रबंधन",
        "soil_affinity": "Well-drained black soils or sandy loams with good aeration",
        "drought_tolerance": "Moderate"
    },
    "sugarcane": {
        "crop_display": "Sugarcane",
        "min_mm": 1500,
        "max_mm": 2200,
        "avg_mm": 1850,
        "water_need_text": "1500 - 2200 mm",
        "category": "Very High",
        "critical_stages": "Formative phase, Tillering, Grand growth period",
        "critical_stages_te": "మొలక దశ, పిలకలు తొడిగే సమయం, ప్రధాన ఎదుగుదల దశ",
        "critical_stages_hi": "अंकुरण, कल्ले फूटना और मुख्य विकास काल",
        "irrigation_method": "Sub-surface Drip or Trash mulched furrow",
        "irrigation_method_te": "భూగర్భ డ్రిప్ లేదా మల్చింగ్ కాలువ పారుదల",
        "irrigation_method_hi": "ड्रिप सिंचाई या पलवार युक्त नाली सिंचाई",
        "soil_affinity": "Deep, fertile, clay loam soils with high organic matter",
        "drought_tolerance": "Low"
    },
    "wheat": {
        "crop_display": "Wheat",
        "min_mm": 450,
        "max_mm": 600,
        "avg_mm": 525,
        "water_need_text": "450 - 600 mm",
        "category": "Moderate",
        "critical_stages": "Crown Root Initiation (CRI), Tillering, Flowering",
        "critical_stages_te": "శిఖర వేర్ల దశ (CRI), పిలకలు మరియు పూత దశ",
        "critical_stages_hi": "ताज जड़ निकलने की अवस्था (CRI), कल्ले फूटना और फूल आना",
        "irrigation_method": "Border strip or Check basin irrigation",
        "irrigation_method_te": "సరిహద్దు కాలువల పద్ధతి లేదా మడుల సేద్యం",
        "irrigation_method_hi": "क्यारी विधि या सीमा पट्टी सिंचाई",
        "soil_affinity": "Alluvial, clay loam, and well-aerated silt loam",
        "drought_tolerance": "Moderate"
    },
    "tomato": {
        "crop_display": "Tomato",
        "min_mm": 600,
        "max_mm": 800,
        "avg_mm": 700,
        "water_need_text": "600 - 800 mm",
        "category": "Moderate",
        "critical_stages": "Flowering, Fruit set, Fruit enlargement",
        "critical_stages_te": "పూత, కాయ పిందె దశ, కాయ పరిమాణం పెరిగే సమయం",
        "critical_stages_hi": "फूल आना, फल का बैठना और फल वृद्धि काल",
        "irrigation_method": "Drip irrigation with plastic mulch",
        "irrigation_method_te": "ప్లాస్టిక్ మల్చింగ్ తో కూడిన డ్రిప్ సేద్యం",
        "irrigation_method_hi": "मल्चिंग युक्त ड्रिप सिंचाई",
        "soil_affinity": "Sandy loam to clay loam rich in organic matter",
        "drought_tolerance": "Low"
    },
    "watermelon": {
        "crop_display": "Watermelon",
        "min_mm": 400,
        "max_mm": 500,
        "avg_mm": 450,
        "water_need_text": "400 - 500 mm",
        "category": "Low to Moderate",
        "critical_stages": "Early vine growth, Flowering, Fruit sizing",
        "critical_stages_te": "తీగ సాగే దశ, పూత, కాయ బరువు పెరిగే సమయం",
        "critical_stages_hi": "बेल फैलने की अवस्था, फूल आना और फल विकास",
        "irrigation_method": "Drip irrigation with fertigation",
        "irrigation_method_te": "డ్రిప్ బిందు సేద్యం",
        "irrigation_method_hi": "ड्रिप सिंचाई",
        "soil_affinity": "Sandy loam, river basin alluvium with excellent drainage",
        "drought_tolerance": "Moderate"
    },
    "soybean": {
        "crop_display": "Soybean",
        "min_mm": 450,
        "max_mm": 550,
        "avg_mm": 500,
        "water_need_text": "450 - 550 mm",
        "category": "Moderate",
        "critical_stages": "Flowering, Pod initiation, Seed filling",
        "critical_stages_te": "పూత దశ, కాయ ఏర్పడే దశ, విత్తనం నిండే దశ",
        "critical_stages_hi": "फूल आना, फली निर्माण और बीज भराव",
        "irrigation_method": "Broad Bed and Furrow (BBF) or Sprinkler",
        "irrigation_method_te": "వెడల్పు బోదె సాళ్ళు (BBF) లేదా స్ప్రింక్లర్",
        "irrigation_method_hi": "चौड़ी क्यारी एवं नाली (BBF) या फव्वारा",
        "soil_affinity": "Medium to deep black soils with good drainage",
        "drought_tolerance": "Moderate"
    },
    "red gram": {
        "crop_display": "Red Gram (Pigeon Pea)",
        "min_mm": 350,
        "max_mm": 450,
        "avg_mm": 400,
        "water_need_text": "350 - 450 mm",
        "category": "Low (Drought Hardy)",
        "critical_stages": "Flower bud initiation, Pod development",
        "critical_stages_te": "మొగ్గ దశ, కాయ ఎదుగుదల సమయం",
        "critical_stages_hi": "कली खिलने का समय और फली विकास",
        "irrigation_method": "Protective life-saving irrigation via furrow",
        "irrigation_method_te": "రక్షక తడి (జీవన రక్షక నీరు) కాలువ ద్వారా",
        "irrigation_method_hi": "जीवन रक्षक सुरक्षात्मक नाली सिंचाई",
        "soil_affinity": "Well-drained red or black soils with deep root penetration",
        "drought_tolerance": "Very High"
    }
}

def get_crop_water_spec_detailed(crop_name: str) -> Dict[str, Any]:
    """Finds matching crop water specifications or provides balanced default."""
    c_lower = crop_name.lower().strip()
    for k, spec in CROP_WATER_SPECS_DETAILED.items():
        if k in c_lower or c_lower in k:
            return spec
    # Balanced default for other field crops
    return {
        "crop_display": crop_name.title(),
        "min_mm": 500,
        "max_mm": 650,
        "avg_mm": 575,
        "water_need_text": "500 - 650 mm",
        "category": "Moderate",
        "critical_stages": "Flowering and Grain / Fruit Filling",
        "critical_stages_te": "పూత దశ మరియు కాయ లేదా గింజ నిండే సమయం",
        "critical_stages_hi": "फूल आने और दाना या फल भराव की अवस्था",
        "irrigation_method": "Drip or furrow irrigation",
        "irrigation_method_te": "బిందు సేద్యం (డ్రిప్) లేదా కాలువ పారుదల",
        "irrigation_method_hi": "ड्रिप या नाली सिंचाई",
        "soil_affinity": "Well-drained loam or alluvial soil",
        "drought_tolerance": "Moderate"
    }

def analyze_crop_rainfall_water_balance(
    crop_name: str,
    soil: str,
    season: str,
    rainfall_level: str,
    rainfall_mm: Optional[float] = None,
    lang: str = "en"
) -> Dict[str, Any]:
    """
    Analyzes crop water needs against seasonal rainfall telemetry.
    Calculates coverage %, deficit/surplus mm, and actionable water advice.
    """
    spec = get_crop_water_spec_detailed(crop_name)
    crop_avg = spec["avg_mm"]
    crop_min = spec["min_mm"]
    crop_max = spec["max_mm"]

    # Determine seasonal rainfall estimate
    rf_lvl = (rainfall_level or "Medium").lower()
    if rainfall_mm is not None and rainfall_mm > 0:
        est_rf = float(rainfall_mm)
    elif "low" in rf_lvl:
        est_rf = 400.0
    elif "high" in rf_lvl:
        est_rf = 1200.0
    else:
        est_rf = 750.0

    coverage_pct = round((est_rf / crop_avg) * 100.0, 1)
    diff_mm = round(est_rf - crop_avg, 1)

    # Localized status & guidance
    if coverage_pct >= 95.0:
        balance_key = "surplus"
        status_text = {
            "en": "Adequate Rainfall / Surplus",
            "te": "సమృద్ధిగా వర్షపాతం / మిగులు",
            "hi": "पर्याप्त वर्षा / अधिशेष"
        }.get(lang, "Adequate Rainfall / Surplus")

        advice_text = {
            "en": f"Rainfall ({est_rf:.0f} mm) covers {coverage_pct:.0f}% of {crop_name}'s water needs. Focus on field drainage channels to prevent waterlogging during heavy monsoon spells.",
            "te": f"వర్షపాతం ({est_rf:.0f} మి.మీ) {crop_name} నీటి అవసరాలలో {coverage_pct:.0f}% తీరుస్తుంది. వర్షాలు అధికమైనప్పుడు నీరు నిల్వ ఉండకుండా మురుగు కాలువలు సిద్ధం చేసుకోండి.",
            "hi": f"वर्षा ({est_rf:.0f} मिमी) {crop_name} की {coverage_pct:.0f}% पानी की आवश्यकता पूरी करती है। भारी बारिश में जलभराव से बचने के लिए जल निकासी नाली बनाएं।"
        }.get(lang, f"Rainfall covers {coverage_pct:.0f}% of crop needs.")

    elif coverage_pct >= 65.0:
        balance_key = "moderate_deficit"
        status_text = {
            "en": "Partially Rainfed (Supplemental Needed)",
            "te": "పాక్షిక వర్షాధారం (అదనపు తడులు అవసరం)",
            "hi": "आंशिक वर्षा आधारित (पूरक सिंचाई आवश्यक)"
        }.get(lang, "Partially Rainfed (Supplemental Needed)")

        deficit_val = abs(diff_mm)
        advice_text = {
            "en": f"Rainfall covers {coverage_pct:.0f}% of water needs. Supplemental irrigation of ~{deficit_val:.0f} mm is required during critical stages ({spec['critical_stages']}).",
            "te": f"వర్షపాతం {coverage_pct:.0f}% నీటి అవసరాలను తీరుస్తుంది. కీలక దశల్లో ({spec.get('critical_stages_te', spec['critical_stages'])}) దాదాపు {deficit_val:.0f} మి.మీ అదనపు తడులు అందించాలి.",
            "hi": f"वर्षा से {coverage_pct:.0f}% पानी मिलता है। महत्वपूर्ण अवस्थाओं ({spec.get('critical_stages_hi', spec['critical_stages'])}) में लगभग {deficit_val:.0f} मिमी पूरक सिंचाई की आवश्यकता होगी।"
        }.get(lang, f"Supplemental irrigation required.")

    else:
        balance_key = "severe_deficit"
        status_text = {
            "en": "High Deficit (Full Irrigation Dependent)",
            "te": "తీవ్ర నీటి లోటు (పూర్తి సాగునీటి ఆధారం)",
            "hi": "अधिक जल कमी (पूर्ण सिंचाई पर निर्भर)"
        }.get(lang, "High Deficit (Full Irrigation Dependent)")

        deficit_val = abs(diff_mm)
        advice_text = {
            "en": f"Rainfall ({est_rf:.0f} mm) covers only {coverage_pct:.0f}% of {crop_name}'s water requirements ({crop_min}-{crop_max} mm). Requires dependable borewell or canal drip irrigation with ~{deficit_val:.0f} mm applied water.",
            "te": f"వర్షపాతం ({est_rf:.0f} మి.మీ) {crop_name} నీటి అవసరాలలో {coverage_pct:.0f}% మాత్రమే తీరుస్తుంది. బోర్వెల్ లేదా కాలువ ద్వారా దాదాపు {deficit_val:.0f} మి.మీ సాగునీరు అందించగలగాలి.",
            "hi": f"वर्षा ({est_rf:.0f} मिमी) {crop_name} की केवल {coverage_pct:.0f}% पानी आवश्यकता को पूरा करती है। बोरवेल या नहर से लगभग {deficit_val:.0f} मिमी सिंचाई की व्यवस्था जरूरी है।"
        }.get(lang, f"Full irrigation required.")

    crit_stage_display = spec.get(f"critical_stages_{lang}", spec["critical_stages"])
    irrig_method_display = spec.get(f"irrigation_method_{lang}", spec["irrigation_method"])

    # Fallback explanation explaining soil, season, rainfall suitability
    fallback_explanation = {
        "en": (
            f"{crop_name} is exceptionally well matched for {soil} soil during {season}. "
            f"Its total water requirement is {spec['water_need_text']}, categorized as {spec['category']} demand. "
            f"With current rainfall ({est_rf:.0f} mm), {coverage_pct:.0f}% of crop hydration is fulfilled by precipitation. "
            f"The soil texture in your field retains the ideal moisture buffer. "
            f"Irrigation strategy: Apply water using {spec['irrigation_method']} especially during {spec['critical_stages']}."
        ),
        "te": (
            f"{season} కాలంలో {soil} నేలకు {crop_name} అత్యంత అనుకూలమైన పంట. "
            f"ఈ పంట మొత్తం నీటి అవసరం {spec['water_need_text']} ({spec['category']} స్థాయి). "
            f"ప్రస్తుత వర్షపాతం ({est_rf:.0f} మి.మీ) ద్వారా {coverage_pct:.0f}% నీటి అవసరం తీరుతుంది. "
            f"మీ నేల స్వభావం వేర్లకు అనుకూల తేమను నిలుపుకుంటుంది. "
            f"సాగునీటి విధానం: {irrig_method_display} ద్వారా ముఖ్యంగా {crit_stage_display} సమయాల్లో సమయానికి నీరు అందించండి."
        ),
        "hi": (
            f"{season} मौसम में {soil} मिट्टी के लिए {crop_name} एक उत्कृष्ट फसल है। "
            f"इसकी कुल जल आवश्यकता {spec['water_need_text']} ({spec['category']} मांग) है। "
            f"वर्तमान वर्षा ({est_rf:.0f} मिमी) से {coverage_pct:.0f}% पानी की पूर्ति प्राकृतिक रूप से हो जाती है। "
            f"आपकी मिट्टी की बनावट नमी को सोखने और बनाए रखने में सक्षम है। "
            f"सिंचाई सलाह: {irrig_method_display} अपनाएं और विशेष रूप से {crit_stage_display} पर समय पर सिंचाई करें।"
        )
    }.get(lang, f"{crop_name} matches your farm parameters.")

    return {
        "crop_name": crop_name,
        "water_requirement": {
            "range_mm": spec["water_need_text"],
            "min_mm": crop_min,
            "max_mm": crop_max,
            "avg_mm": crop_avg,
            "category": spec["category"],
            "critical_stages": crit_stage_display,
            "irrigation_method": irrig_method_display,
            "soil_affinity": spec["soil_affinity"],
            "drought_tolerance": spec["drought_tolerance"]
        },
        "rainfall_analysis": {
            "estimated_rainfall_mm": est_rf,
            "rainfall_level": rainfall_level,
            "coverage_pct": coverage_pct,
            "deficit_or_surplus_mm": diff_mm,
            "balance_status": balance_key,
            "status_title": status_text,
            "advice": advice_text
        },
        "default_suitability_explanation": fallback_explanation
    }

def classify_symptom_category(disease_name: str, raw_label: str = "") -> str:
    """
    Identifies the primary diagnostic category:
    1. Healthy
    2. Disease detected
    3. Possible nutrient deficiency
    4. Possible water-stress symptoms
    """
    full = f"{disease_name} {raw_label}".lower()
    
    if "healthy" in full:
        return "Healthy"
    
    # Check water stress markers
    for kw in WATER_STRESS_KEYWORDS:
        if kw in full:
            return "Possible water-stress symptoms"
            
    # Check nutrient deficiency markers
    for kw in NUTRIENT_DEFICIENCY_KEYWORDS:
        if kw in full:
            return "Possible nutrient deficiency"
            
    return "Disease detected"


def calculate_water_requirement(
    crop_name: str,
    disease_name: str,
    symptom_category: str,
    soil_moisture: Optional[float] = None,
    growth_stage: Optional[str] = None,
    temperature_c: Optional[float] = None,
    recent_rainfall_mm: Optional[float] = None,
    days_since_irrigation: Optional[int] = None,
    field_condition: Optional[str] = None,
    lang: str = "en"
) -> Dict[str, Any]:
    """
    Combines computer vision pathology with soil moisture, crop stage, and weather
    to determine precise water requirement and irrigation urgency.
    """
    crop_key = crop_name.lower().strip()
    spec = None
    for k, s in CROP_WATER_SPECS.items():
        if k in crop_key:
            spec = s
            break
    if not spec:
        spec = {"min_sm": 50.0, "max_sm": 70.0, "kc_flower": 1.10, "method": "Drip or furrow irrigation"}

    # Defaults if telemetry is omitted
    sm = float(soil_moisture) if soil_moisture is not None else 32.0 # Default: typical farmer query state
    stage = (growth_stage or "Flowering / Reproductive").lower()
    temp = float(temperature_c) if temperature_c is not None else 30.0
    rain = float(recent_rainfall_mm) if recent_rainfall_mm is not None else 0.0
    days_irrig = int(days_since_irrigation) if days_since_irrigation is not None else 4
    cond = (field_condition or "Normal").lower()

    # Determine Soil Moisture Level
    if sm < spec["min_sm"] * 0.7:
        sm_status = f"Low ({sm:.0f}%)"
        sm_code = "low"
    elif sm <= spec["max_sm"]:
        sm_status = f"Adequate ({sm:.0f}%)"
        sm_code = "adequate"
    else:
        sm_status = f"High / Saturated ({sm:.0f}%)"
        sm_code = "high"

    # Multi-factor Stress and Water Requirement Computation
    stress_points = 0
    
    # 1. Soil moisture deficit
    if sm_code == "low":
        stress_points += 40
    elif sm_code == "adequate":
        stress_points += 5
    else:
        stress_points += 15 # Over-saturation stress

    # 2. Temperature & Evapotranspiration
    if temp >= 34.0:
        stress_points += 20
    elif temp >= 28.0:
        stress_points += 10

    # 3. Growth stage sensitivity (Flowering & Grain-filling are most sensitive)
    is_flowering = any(st in stage for st in ["flower", "reproduct", "bloom", "tassel", "panicle", "grain", "fruit"])
    if is_flowering:
        stress_points += 25

    # 4. Recent rainfall
    if rain > 20.0:
        stress_points = max(0, stress_points - 35)
    elif rain > 5.0:
        stress_points = max(0, stress_points - 15)

    # 5. Visual Leaf Pathology Interaction
    dis_lower = disease_name.lower()
    foliar_fungal = any(fn in dis_lower for fn in ["late blight", "early blight", "leaf mold", "mildew", "rust", "leaf spot"])
    root_rot = any(rn in dis_lower for rn in ["root rot", "wilt", "damping", "collar rot"])
    
    if symptom_category == "Possible water-stress symptoms":
        stress_points += 30
    elif foliar_fungal:
        # Fungal foliar: do not overwater or wet canopy!
        stress_points = min(stress_points, 55)
    elif root_rot:
        # Root rot: excess water is toxic
        stress_points = min(stress_points, 25)

    # Classification of Stress Level
    if stress_points >= 65:
        crop_stress = "High"
    elif stress_points >= 35:
        crop_stress = "Moderate"
    elif stress_points >= 15:
        crop_stress = "Low"
    else:
        crop_stress = "None (Optimal)"

    # Final Water Requirement Output & Next Irrigation
    if rain >= 25.0 or sm >= spec["max_sm"]:
        water_req = "LOW"
        next_irrig = "Not required now"
        urgency = "Adequate soil moisture from recent rain; pause irrigation to prevent root hypoxia."
        rec_depth = "0 mm"
    elif sm_code == "low" or stress_points >= 50:
        water_req = "HIGH"
        next_irrig = "Required"
        urgency = "Immediate irrigation required within 24 hours to prevent permanent wilting."
        rec_depth = "30 - 40 mm (or 2-3 inches canal depth)" if "paddy" in crop_key else "25 - 30 mm (45-60 mins drip)"
    elif sm_code == "adequate" and is_flowering and temp > 30.0:
        water_req = "MEDIUM"
        next_irrig = "Scheduled in 2 Days"
        urgency = "Moderate demand. Monitor root zone moisture during peak flowering evapotranspiration."
        rec_depth = "15 - 20 mm (30 mins drip)"
    else:
        water_req = "LOW"
        next_irrig = "Not required now"
        urgency = "Soil moisture is currently in the comfort zone. Routine check in 3-4 days."
        rec_depth = "0 - 10 mm maintenance"

    # Specific Pathological Interaction Guidance
    if foliar_fungal:
        patho_synergy = f"⚠️ Critical Pathological Alert: {disease_name} thrives in high foliage humidity. Apply irrigation strictly at soil/root level using {spec['method']}. NEVER overhead spray leaves."
    elif root_rot:
        patho_synergy = f"⚠️ Root Aeration Warning: {disease_name} is aggravated by saturated waterlogged soil. Ensure good drainage before adding any water."
    elif symptom_category == "Possible nutrient deficiency":
        patho_synergy = f"💡 Fertigation Opportunity: Leaf displays {disease_name}. Optimal soil moisture ({sm:.0f}%) is required for root nutrient transport. Combine next irrigation with balanced water-soluble fertilizer."
    elif symptom_category == "Possible water-stress symptoms":
        patho_synergy = f"💧 Hydration Recovery: Severe foliar dehydration and turgor loss detected. Water early morning or evening to minimize evaporative loss and restore leaf turgidity."
    else:
        patho_synergy = f"✅ Optimum Canopy: Healthy foliar structure observed. Maintain standard {crop_name} irrigation cycle ({spec['method']})."

    actionable_steps = [
        f"Apply irrigation via: {spec['method']}.",
        "Water during early morning (6-8 AM) or evening (5-7 PM) to minimize heat-induced evaporation.",
        f"Target root zone soil moisture between {spec['min_sm']:.0f}% and {spec['max_sm']:.0f}% for {crop_name}."
    ]

    return {
        "water_requirement": water_req,
        "soil_moisture": sm_status,
        "soil_moisture_pct": round(sm, 1),
        "crop_stress": crop_stress,
        "next_irrigation": next_irrig,
        "urgency_summary": urgency,
        "recommended_volume": rec_depth,
        "pathology_water_interaction": patho_synergy,
        "irrigation_method": spec["method"],
        "actionable_steps": actionable_steps,
        "context_inputs": {
            "crop_type": crop_name,
            "growth_stage": stage.capitalize(),
            "temperature_c": temp,
            "recent_rainfall_mm": rain,
            "days_since_irrigation": days_irrig,
            "field_condition": cond.capitalize()
        }
    }
