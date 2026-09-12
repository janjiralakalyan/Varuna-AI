import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_screen.dart';
import '../services/ai_service.dart';

class DairyLivestockScreen extends StatefulWidget {
  const DairyLivestockScreen({super.key});

  @override
  State<DairyLivestockScreen> createState() => _DairyLivestockScreenState();
}

class _DairyLivestockScreenState extends State<DairyLivestockScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  // Search & Filters
  String _searchQuery = '';
  String _selectedHerdFilter = 'All';

  // ----------------------------------------------------
  // ML AI ENGINES & VET STATE
  // ----------------------------------------------------
  bool _isPredictingMilk = false;
  Map<String, dynamic>? _mlMilkResult;
  int _lactationMonth = 3;
  double _dailyGreenFodder = 28.0;
  double _dailyDryFodder = 5.0;
  double _dailyConcentrate = 4.5;
  double _dailyWater = 70.0;

  // Vet AI Triage State
  bool _isDiagnosingVet = false;
  final Set<String> _selectedSymptomTags = {};
  double _cattleBodyTemp = 101.8;
  final TextEditingController _symptomTextController = TextEditingController();

  // Smart Diet AI State
  bool _isCalculatingDiet = false;
  Map<String, dynamic>? _smartDietResult;

  // ----------------------------------------------------
  // MILK LOGGER STATE
  // ----------------------------------------------------
  double _morningMilk = 14.5;
  double _eveningMilk = 12.0;
  double _fatPercentage = 4.2;
  double _snfPercentage = 8.5;
  double _baseRatePerFat = 9.5; // ₹ per fat unit
  double _flatRatePerLiter = 46.0;
  bool _useFatFormula = true;
  final List<Map<String, dynamic>> _milkHistory = [
    {
      'date': 'Today (14 Aug)',
      'morning': 14.5,
      'evening': 12.0,
      'total': 26.5,
      'fat': 4.2,
      'snf': 8.5,
      'revenue': 1219.0,
      'shift': 'Both Shifts Complete'
    },
    {
      'date': '13 Aug',
      'morning': 15.0,
      'evening': 11.5,
      'total': 26.5,
      'fat': 4.1,
      'snf': 8.4,
      'revenue': 1192.5,
      'shift': 'Both Shifts Complete'
    },
    {
      'date': '12 Aug',
      'morning': 14.0,
      'evening': 12.5,
      'total': 26.5,
      'fat': 4.3,
      'snf': 8.6,
      'revenue': 1245.5,
      'shift': 'Both Shifts Complete'
    },
    {
      'date': '11 Aug',
      'morning': 13.8,
      'evening': 11.8,
      'total': 25.6,
      'fat': 4.0,
      'snf': 8.3,
      'revenue': 1152.0,
      'shift': 'Both Shifts Complete'
    },
    {
      'date': '10 Aug',
      'morning': 15.2,
      'evening': 12.2,
      'total': 27.4,
      'fat': 4.2,
      'snf': 8.5,
      'revenue': 1260.4,
      'shift': 'Both Shifts Complete'
    },
    {
      'date': '09 Aug',
      'morning': 14.6,
      'evening': 11.9,
      'total': 26.5,
      'fat': 4.1,
      'snf': 8.4,
      'revenue': 1192.5,
      'shift': 'Both Shifts Complete'
    },
    {
      'date': '08 Aug',
      'morning': 14.2,
      'evening': 12.1,
      'total': 26.3,
      'fat': 4.2,
      'snf': 8.5,
      'revenue': 1209.8,
      'shift': 'Both Shifts Complete'
    },
  ];

  // ----------------------------------------------------
  // FEED & RATION STATE
  // ----------------------------------------------------
  String _selectedBreedCategory = 'Crossbred Cow (HF/Jersey)';
  double _animalWeight = 460.0; // kg
  double _dailyMilkYield = 16.0; // Liters
  bool _isPregnant = false;
  final int _pregnancyMonth = 0;

  // Feed Customizations
  final double _greenFodderCostPerKg = 1.50;
  final double _dryStrawCostPerKg = 4.00;
  final double _concentrateCostPerKg = 24.00;
  final double _mineralMixCostPerKg = 90.00;

  // ----------------------------------------------------
  // HERD DATA LIST
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _herdData = [
    {
      'id': 'TAG-IN-8492',
      'name': 'Gauri',
      'species': 'Cow',
      'breed': 'Holstein Friesian (HF Cross)',
      'ageYears': 4.5,
      'status': 'Lactating',
      'lactationStage': 'Early (Month 3)',
      'currentYield': '18.5 L/day',
      'avgFat': '4.1%',
      'inseminationDate': '12 May 2026',
      'expectedCalving': '18 Feb 2027',
      'vaccinationStatus': 'Up to date (FMD, HS)',
      'nextBooster': 'Brucellosis in 22 days',
      'healthScore': 94,
      'color': const Color(0xFF1565C0),
      'notes': 'High producer, responsive to bypass fat supplements.',
    },
    {
      'id': 'TAG-IN-9021',
      'name': 'Lakshmi',
      'species': 'Buffalo',
      'breed': 'Murrah Buffalo (Grade A)',
      'ageYears': 6.0,
      'status': 'Pregnant & Milking',
      'lactationStage': 'Mid (Month 6)',
      'currentYield': '12.0 L/day',
      'avgFat': '7.4%',
      'inseminationDate': '05 Feb 2026',
      'expectedCalving': '12 Dec 2026',
      'vaccinationStatus': 'Due for Anthrax',
      'nextBooster': 'Anthrax booster in 10 days',
      'healthScore': 88,
      'color': const Color(0xFF0D47A1),
      'notes': 'Requires high dry matter and calcium booster pre-calving.',
    },
    {
      'id': 'TAG-IN-3310',
      'name': 'Radha',
      'species': 'Cow',
      'breed': 'Gir Indigenous Desi Cow',
      'ageYears': 3.8,
      'status': 'Lactating',
      'lactationStage': 'Peak (Month 2)',
      'currentYield': '14.2 L/day',
      'avgFat': '4.8% (A2 Milk)',
      'inseminationDate': 'Not bred yet',
      'expectedCalving': '--',
      'vaccinationStatus': 'Up to date',
      'nextBooster': 'Deworming in 15 days',
      'healthScore': 98,
      'color': const Color(0xFF00796B),
      'notes': 'Certified A2 cow, excellent natural immunity.',
    },
    {
      'id': 'TAG-IN-4421',
      'name': 'Nandi (Sire)',
      'species': 'Bull',
      'breed': 'Pedigree Sahiwal Breeding Bull',
      'ageYears': 5.2,
      'status': 'Breeding Bull',
      'lactationStage': 'N/A',
      'currentYield': 'N/A',
      'avgFat': 'N/A',
      'inseminationDate': 'Active Sire',
      'expectedCalving': '--',
      'vaccinationStatus': 'Fully Vaccinated',
      'nextBooster': 'FMD Booster in 45 days',
      'healthScore': 96,
      'color': const Color(0xFF4527A0),
      'notes': 'High genetic value for indigenous dairy improvement.',
    },
    {
      'id': 'TAG-IN-5519',
      'name': 'Champa',
      'species': 'Cow',
      'breed': 'Jersey Cross',
      'ageYears': 2.8,
      'status': 'Dry / Gestating',
      'lactationStage': 'Dry Period (Month 8)',
      'currentYield': '0.0 L (Resting)',
      'avgFat': '--',
      'inseminationDate': '10 Nov 2025',
      'expectedCalving': '18 Aug 2026',
      'vaccinationStatus': 'Pre-calving shots complete',
      'nextBooster': 'Colostrum check at calving',
      'healthScore': 91,
      'color': const Color(0xFFC2185B),
      'notes': 'Due for calving in 4 days! Steaming up feed active.',
    },
    {
      'id': 'TAG-IN-7723',
      'name': 'Heera',
      'species': 'Goat',
      'breed': 'Jamnapari Dairy Goat',
      'ageYears': 2.0,
      'status': 'Lactating',
      'lactationStage': 'Early (Month 1)',
      'currentYield': '3.2 L/day',
      'avgFat': '4.4%',
      'inseminationDate': '01 Jan 2026',
      'expectedCalving': '--',
      'vaccinationStatus': 'PPR Vaccinated',
      'nextBooster': 'ET in 30 days',
      'healthScore': 95,
      'color': const Color(0xFF5D4037),
      'notes': 'Twinned recently, high appetite and vitality.',
    },
  ];

  // ----------------------------------------------------
  // VETERINARY ENCYCLOPEDIA & SYMPTOM CHECKER
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _diseaseEncyclopedia = [
    {
      'name': 'Lumpy Skin Disease (LSD)',
      'agent': 'Capripoxvirus (Poxviridae)',
      'species': 'Cattle & Buffaloes',
      'severity': 'High (Contagious Vector-Borne)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Goat Pox Vaccine (Uttarkashi Strain) + Melo-Plus Bolus',
      'medicineDosage':
          '3 ml subcutaneous vaccination in unaffected herd; 2 Melo-Plus (Meloxicam 100mg + Paracetamol 1500mg) boluses twice daily for fever & pain.',
      'medType': 'Heterologous Live Vaccine & NSAID Bolus',
      'medicineWarning': 'Schedule H Drug: Vaccinate only healthy animals. Isolate affected cattle immediately to stop fly/tick vector transmission.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600&auto=format&fit=crop&q=80',
      'organicName': 'NDDB Ethno-Veterinary Oral Bolus & Neem-Turmeric Skin Ointment',
      'organicIngredients': 'Oral: Betel leaves (10) + Black Pepper (10g) + Salt (10g) ground with Jaggery (50g). Topical: Neem Oil (100ml) + Pure Turmeric (20g) + Garlic (10 cloves).',
      'organicDosage': 'Feed fresh herbal paste ball 3 times daily for 5 days. Apply neem-turmeric balm over burst nodules twice daily.',
      'organicBenefits': 'Scientifically validated by NDDB & TANUVAS: >92% clinical recovery without antibiotic resistance or milk withholding loss.',
      'symptoms': [
        'Hard nodules (2-5 cm) all over skin, neck, and udder',
        'High body temperature (>104°F) for 2-3 days',
        'Sharp drop in milk production & loss of appetite',
        'Watery eye and nasal discharge, swollen lymph nodes',
        'Edema in brisket and legs leading to lameness'
      ],
      'firstAid': [
        'Immediate isolation of affected animals to prevent vector spread (mosquitoes/ticks).',
        'Topical application of pure neem oil + turmeric paste on ruptured nodules.',
        'Oral administration of herbal immunity booster (Jaggery, black pepper, turmeric, cumin).',
        'Antipyretic (Paracetamol/Meloxicam) via veterinary prescription for fever control.',
        'Vaccinate remaining non-infected herd with Goat Pox Vaccine (Heterologous protection).'
      ],
      'prevention': 'Vector control using neem smoke/sprays, strict farm biosecurity.',
      'badgeColor': Colors.red.shade700,
    },
    {
      'name': 'Bovine Mastitis (Clinical / Subclinical)',
      'agent': 'Staphylococcus aureus / Streptococcus uberis',
      'species': 'Dairy Cows & Buffaloes',
      'severity': 'Critical Economic Loss',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1527153857715-3908f2ae5e81?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Pendistrin-SH / Ceftiofur Intramammary Infusion + 0.5% Iodine Teat Dip',
      'medicineDosage':
          '1 syringe infused into affected quarter after complete milk stripping every 12 hours for 3 days; dip teats in 0.5% Povidone Iodine post-milking.',
      'medType': 'Intramammary Antibiotic & Post-Milking Teat Barrier Dip',
      'medicineWarning': 'Milk Withholding: Never mix milk from treated quarters into bulk milk tank during treatment + 72 hours post-infusion.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&auto=format&fit=crop&q=80',
      'organicName': 'NDDB/TANUVAS Ethno-Veterinary Udder Healing Balm',
      'organicIngredients': 'Fresh Aloe Vera leaf pulp (250g) + Pure Turmeric powder (50g) + Slaked Lime / Chuna paste (15g).',
      'organicDosage': 'Grind into smooth paste. Add water to make lotion. Wash udder, strip milk completely, and apply paste over entire infected quarter 3-5 times daily for 5 days.',
      'organicBenefits': 'Massive reduction in Somatic Cell Count (SCC), cools acute inflammation, dissolves fibrin clots with zero antibiotic milk residue.',
      'symptoms': [
        'Swollen, hot, hard, or painful udder quarter',
        'Clotted, discolored, watery, or blood-tinged milk',
        'Cow resists milking or kicks when udder is touched',
        'Elevated somatic cell count (California Mastitis Test positive)',
        'Systemic fever and toxemia in acute environmental mastitis'
      ],
      'firstAid': [
        'Strip affected quarter completely every 2 hours into a disinfectant container.',
        'Apply cold water or ice compresses to reduce udder heat and acute swelling.',
        'Intramammary antibiotic infusion strictly following vet guidance & aseptic cleaning.',
        'Never mix infected milk into the bulk storage tank.',
        'Provide Vitamin E and Selenium boluses to boost mammary tissue repair.'
      ],
      'prevention': 'Post-milking teat dipping in 0.5% Iodine solution; clean dry bedding.',
      'badgeColor': Colors.deepOrange.shade700,
    },
    {
      'name': 'Foot & Mouth Disease (FMD)',
      'agent': 'Aphthovirus (Picornaviridae)',
      'species': 'Cattle, Buffalo, Sheep, Goats, Pigs',
      'severity': 'Extremely High (Quarantine)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1546445317-29f4545e9d53?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Potassium Permanganate (KMNO4 1%) + Boroglycerine + FMD-CP Vaccine',
      'medicineDosage':
          'Wash mouth sores with 1% KMNO4 solution twice daily; apply Boroglycerine paint; 2 ml bi-annual oil adjuvant vaccine under national program.',
      'medType': 'Antiseptic Wash, Oral Soother & Oil-Adjuvant Vaccine',
      'medicineWarning': 'Highly contagious airborne/contact virus: Quarantine entire barn and disinfect floor with 4% Washing Soda (Sodium carbonate).',
      'organicPhoto':
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Ayurvedic Mouth Wash & Foot Cleft Antiseptic Dressing',
      'organicIngredients': 'Mouth: Fitkari (Alum 10g) in 1L warm water + Honey-Turmeric paint; Foot: Sesame/Neem oil (100ml) + Camphor (10g) + Crushed Garlic.',
      'organicDosage': 'Wash mouth sores with alum water, then smear honey-turmeric paste. Clean foot sores with salt water and dress with camphor-neem oil.',
      'organicBenefits': 'Restores appetite in 24 hours, eliminates maggot wound risk in interdigital clefts, and accelerates epithelial regeneration.',
      'symptoms': [
        'Vesicles and blisters on tongue, dental pad, gums, and lips',
        'Excessive ropy salivation and characteristic smacking of lips',
        'Blisters in interdigital space of hooves causing severe lameness',
        'Teat lesions leading to secondary bacterial mastitis',
        'Severe shivering, high fever, and abortion in gestating animals'
      ],
      'firstAid': [
        'Wash mouth lesions with 1% Potassium Permanganate (KMNO4) or 2% Sodium Bicarbonate.',
        'Apply Boroglycerine on oral sores to facilitate soft feeding with gruel/congee.',
        'Wash feet with 4% Sodium Carbonate or 10% Zinc Sulphate solution to heal foot rot.',
        'Keep animal on soft dry sand; provide easily digestible liquid diet.',
        'Inject broad-spectrum antibiotics to curb secondary bacterial complications.'
      ],
      'prevention': 'Bi-annual polyvalent FMD vaccination (FMD-CP programme).',
      'badgeColor': Colors.purple.shade700,
    },
    {
      'name': 'Haemorrhagic Septicaemia (HS - Gal Ghotu)',
      'agent': 'Pasteurella multocida',
      'species': 'Particularly severe in Buffaloes & Young Cattle',
      'severity': 'Emergency (High Mortality)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1500595046743-cd271d694d30?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Sulphadimidine 33.3% / Oxytetracycline LA + HS Alum Vaccine',
      'medicineDosage':
          '100-150 ml Sulphadimidine slow IV by vet immediately; 5 ml alum vaccine pre-monsoon in May.',
      'medType': 'Emergency Antibacterial Injection & Inactivated Vaccine',
      'medicineWarning': 'EMERGENCY: Must be treated within first 6-12 hours of high fever (>106°F) or asphyxiation may occur.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Emergency Supportive Throat Swelling & Pulmonary Decoction',
      'organicIngredients': 'Ginger (100g) + Black Pepper (25g) + Tulsi (50g) + Asafoetida/Hing (10g) + Jaggery (250g).',
      'organicDosage': 'Boil in 1L water. Administer 250ml warm drench every 6 hours alongside emergency veterinary antibiotic injection (Sulphadimidine).',
      'organicBenefits': 'Relieves acute tracheal spasm and respiratory suffocation while emergency veterinary antibiotics take effect.',
      'symptoms': [
        'Sudden onset of high fever (106°F - 107°F) with extreme depression',
        'Hot, painful swelling under the throat, dewlap, and neck',
        'Stridor, severe respiratory distress, frothy tongue protrusion',
        'Death often occurs within 12 to 24 hours if untreated'
      ],
      'firstAid': [
        'Immediate veterinary intervention required within hours of initial fever.',
        'Early administration of high-dose Sulfonamides or Oxytetracycline/Ceftiofur.',
        'Anti-inflammatory drugs to mitigate neck edema and asphyxiation.',
        'Keep animal sheltered away from monsoon rainwater and chilly winds.'
      ],
      'prevention': 'Pre-monsoon annual HS vaccination in May/June without fail.',
      'badgeColor': Colors.red.shade900,
    },
    {
      'name': 'Rumen Bloat / Tympany (Afara)',
      'agent': 'Dietary (Frothy Bloat / Free Gas)',
      'species': 'All Ruminants (Cattle, Buffaloes, Goats)',
      'severity': 'Immediate Distress (Suffocation Risk)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1533743983669-94fa5c4338ec?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Tympol / Bloatosil (Poloxalene 25g) + Pure Mustard Oil Drench',
      'medicineDosage':
          '100 ml Tympol emulsified in 500 ml edible mustard oil given slowly via drenching bottle.',
      'medType': 'Anti-Frothing Defoamer & Digestive Carminative',
      'medicineWarning': 'Drench slowly over tongue. If animal is gasping or lying flat, call vet immediately for trocharisation.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1588681664899-f142ff2dc9b1?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Carminative Anti-Froth Rumen Emulsion (Mustard Oil & Asafoetida)',
      'organicIngredients': 'Pure Mustard / Linseed Oil (500 ml) + Asafoetida / Hing (15g) + Ginger juice (50 ml) + Black Rock Salt (30g) + Oil of Turpentine (20 ml).',
      'organicDosage': 'Shake vigorously into emulsion. Drench slowly over the tongue while holding head level (do NOT tilt head back excessively).',
      'organicBenefits': 'Breaks stable legume foam bubbles instantly in the rumen, relieves left flank gas pressure within 20 minutes.',
      'symptoms': [
        'Severe distension of left paralumbar fossa (left flank ballooning)',
        'Labored mouth breathing, grunting, tongue out',
        'Restlessness, kicking at the belly, frequent urination/defecation',
        'Animal suddenly recumbent due to diaphragm pressure on lungs'
      ],
      'firstAid': [
        'Keep animal standing with front legs elevated on a slope or mound.',
        'Drench with 500 ml edible vegetable/mustard oil + 20-30 ml Oil of Turpentine.',
        'Pass a stomach tube to release free gas trapped in dorsal rumen.',
        'Administer anti-bloat poloxalene drench to break stable legume froth.',
        'In critical suffocating emergency: perform trocharisation at left flank by vet.'
      ],
      'prevention': 'Never feed wet legume pasture (Berseem/Lucerne) on empty stomach.',
      'badgeColor': Colors.amber.shade900,
    },
    {
      'name': 'Hypocalcemia (Milk Fever) & Mineral Deficiencies',
      'agent': 'Metabolic (Acute Blood Calcium & Phosphorus Drop)',
      'species': 'High-Yielding Dairy Cows & Buffaloes (Post-Calving)',
      'severity': 'Urgent Recumbency (Downer Cow)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Mifex / Calci-Must (Calcium Borogluconate 25%) + Agrimin Forte Pack',
      'medicineDosage':
          '450 ml Mifex warm slow IV/SC under vet supervision; 50-100g Agrimin Forte daily in daily feed concentrate.',
      'medType': 'Macro-Mineral Infusion & Chelated Ruminant Fertilizer Mix',
      'medicineWarning': 'CRITICAL: Never give oral liquids to an unconscious downer cow as liquid will enter lungs and cause death.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1509358271058-acd22cc93898?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Bio-Available Mineral Fertilizer & High-Energy Jaggery Drench',
      'organicIngredients': 'Dicalcium Phosphate (DCP 100g) + Pure Jaggery (500g) + Organic Moringa Leaf powder (100g) + Slaked Lime Water supernatant.',
      'organicDosage': 'Post-calving recovery: Mix in warm water twice daily for 5 days. For downer cow emergency: IV calcium injection by vet is mandatory.',
      'organicBenefits': 'Restores blood calcium-phosphorus homeostasis, boosts smooth muscle tone of rumen and uterus, prevents prolapse.',
      'symptoms': [
        'Cow sits down with head turned into the flank (S-shaped neck curve)',
        'Cold ears, muzzle, and extremities with subnormal body temperature',
        'Complete cessation of rumen movement and dry muzzle',
        'Muscle trembling followed by paralysis within 48h of calving'
      ],
      'firstAid': [
        'Never drench liquid medicine orally to a downer cow to avoid aspiration pneumonia.',
        'Keep cow propped in sternal recumbency using straw bales.',
        'Administer 450 ml Calcium Borogluconate (Mifex) warm IV slowly.',
        'Provide soft bedding and massage legs to maintain blood circulation.'
      ],
      'prevention':
          'Feed low-calcium diet before calving; supplement anionic salts & Vitamin D3.',
      'badgeColor': Colors.teal.shade800,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _symptomTextController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // 🥛 ML PREDICTION & AI VET ACTIONS
  // ----------------------------------------------------
  Future<void> _runMlMilkPrediction() async {
    setState(() => _isPredictingMilk = true);
    try {
      final res = await AIService.predictCattleMilk(
        breed: _selectedBreedCategory,
        lactationMonth: _lactationMonth,
        weight: _animalWeight,
        greenFodderKg: _dailyGreenFodder,
        dryFodderKg: _dailyDryFodder,
        concentrateKg: _dailyConcentrate,
        waterLiters: _dailyWater,
      );
      if (mounted) {
        setState(() {
          _mlMilkResult = res;
          _isPredictingMilk = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPredictingMilk = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Milk Prediction error: $e')),
        );
      }
    }
  }

  Future<void> _runVetDiagnosticTriage() async {
    setState(() => _isDiagnosingVet = true);
    try {
      final res = await AIService.diagnoseCattleMedical(
        symptoms: _selectedSymptomTags.toList(),
        species: _selectedBreedCategory.contains('Buffalo')
            ? 'Buffalo'
            : (_selectedBreedCategory.contains('Goat') ? 'Goat' : 'Cow'),
        breed: _selectedBreedCategory,
        ageYears: 4.0,
        bodyTempF: _cattleBodyTemp,
        durationDays: 2,
        freeText: _symptomTextController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isDiagnosingVet = false;
        });
        _showVetResultBottomSheet(res);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDiagnosingVet = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veterinary Triage error: $e')),
        );
      }
    }
  }

  Future<void> _runSmartDietOptimization() async {
    setState(() => _isCalculatingDiet = true);
    try {
      final res = await AIService.calculateCattleDiet(
        breed: _selectedBreedCategory,
        animalWeight: _animalWeight,
        dailyMilkYield: _dailyMilkYield,
        isPregnant: _isPregnant,
        pregnancyMonth: _pregnancyMonth,
        flatMilkRate: _flatRatePerLiter,
      );
      if (mounted) {
        setState(() {
          _smartDietResult = res;
          _isCalculatingDiet = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ ICAR Scientific Diet Plan updated successfully!'),
            backgroundColor: Color(0xFF00796B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculatingDiet = false);
      }
    }
  }

  void _showVetResultBottomSheet(Map<String, dynamic> res) {
    final diagnosis = res['primary_diagnosis'] ?? 'Healthy / Normal';
    final confidence = res['confidence_score'] ?? 90.0;
    final urgency = res['urgency_level'] ?? 'Consult veterinarian.';
    final severity = res['severity'] ?? 'Moderate';
    final firstAid = List<String>.from(res['first_aid_steps'] ?? []);
    final prescriptions = List<String>.from(res['veterinary_prescriptions'] ?? []);
    final ayurvedic = List<String>.from(res['ayurvedic_ethnoveterinary'] ?? []);
    final dietChanges = List<String>.from(res['recommended_diet_changes'] ?? []);
    final disclaimer = res['disclaimer'] ?? 'Preliminary field triage.';

    final bool isEmergency = severity.toString().toLowerCase().contains('emergency') ||
        severity.toString().toLowerCase().contains('high');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isEmergency
                              ? [const Color(0xFFB71C1C), const Color(0xFFD32F2F)]
                              : [const Color(0xFF00796B), const Color(0xFF004D40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'AI Clinical Confidence: $confidence%',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isEmergency ? Colors.amberAccent : Colors.greenAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  severity.toString(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            diagnosis.toString(),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            urgency.toString(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // First Aid Steps
                    if (firstAid.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Immediate Emergency First-Aid Actions',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...firstAid.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(step, style: const TextStyle(fontSize: 13, height: 1.3))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Veterinary Prescriptions & Dosages
                    if (prescriptions.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.medication_rounded, color: Color(0xFF1565C0), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Veterinary Medical Prescriptions & Dosage',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...prescriptions.map((rx) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            color: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF1565C0), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rx, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900))),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Ayurvedic / Ethnoveterinary
                    if (ayurvedic.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ayurvedic & Ethnoveterinary Remedies',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...ayurvedic.map((ayur) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            color: Colors.green.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.spa_rounded, color: Color(0xFF2E7D32), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(ayur, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade900))),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Recommended Diet Modifications during Sickness
                    if (dietChanges.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.restaurant_rounded, color: Color(0xFF00838F), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Recommended Food & Diet During Recovery',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...dietChanges.map((diet) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_right_rounded, color: Color(0xFF00838F), size: 20),
                                const SizedBox(width: 4),
                                Expanded(child: Text(diet, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        disclaimer,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 14),

                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Acknowledge & Close Triage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CALCULATOR LOGIC
  // ----------------------------------------------------
  double get _todayTotalMilk => _morningMilk + _eveningMilk;

  double get _calculatedDailyRevenue {
    if (_useFatFormula) {
      // Standard Cooperative SNF & Fat formula: Price = (Fat * FatRate) + (SNF * SNF_Rate)
      final fatPrice = _fatPercentage * _baseRatePerFat;
      final snfPrice = _snfPercentage * 2.8;
      return _todayTotalMilk * (fatPrice + snfPrice) / 10.0;
    } else {
      return _todayTotalMilk * _flatRatePerLiter;
    }
  }

  Map<String, dynamic> _calculateScientificRation() {
    // Standard ICAR / NRC Ruminant Nutrition Equations
    double dmiCoeff = 0.030; // 3% of body weight for dry matter
    if (_selectedBreedCategory.contains('Buffalo')) {
      dmiCoeff = 0.032;
    } else if (_selectedBreedCategory.contains('Indigenous')) {
      dmiCoeff = 0.026;
    } else if (_selectedBreedCategory.contains('Goat')) {
      dmiCoeff = 0.040;
    }

    final maintenanceDm = _animalWeight * dmiCoeff;
    final lactationDm = _dailyMilkYield * 0.35;
    final pregnancyDm = _isPregnant ? (_pregnancyMonth > 6 ? 1.5 : 0.5) : 0.0;

    final totalDmRequired = maintenanceDm + lactationDm + pregnancyDm;

    // Fodder dry-matter allocation: 60% Roughage (2/3 Green, 1/3 Dry), 40% Concentrate
    final roughageDm = totalDmRequired * 0.62;
    final concentrateDm = totalDmRequired * 0.38;

    final greenFodderFresh = (roughageDm * 0.65) / 0.20; // 20% DM in fresh green
    final dryFodderStraw = (roughageDm * 0.35) / 0.90; // 90% DM in dry straw
    final concentrateFresh = concentrateDm / 0.90; // 90% DM in feed mash
    final mineralMixGrams = (_animalWeight * 0.20) + (_dailyMilkYield * 4.0);
    final waterReqLiters = (_animalWeight * 0.10) + (_dailyMilkYield * 3.5);

    final dailyFeedCost = (greenFodderFresh * _greenFodderCostPerKg) +
        (dryFodderStraw * _dryStrawCostPerKg) +
        (concentrateFresh * _concentrateCostPerKg) +
        ((mineralMixGrams / 1000.0) * _mineralMixCostPerKg);

    final milkRevenue = _dailyMilkYield * _flatRatePerLiter;
    final dailyNetProfit = milkRevenue - dailyFeedCost;
    final feedCostRatio =
        milkRevenue > 0 ? (dailyFeedCost / milkRevenue) * 100 : 0.0;

    return {
      'totalDm': totalDmRequired.toStringAsFixed(2),
      'greenFodder': greenFodderFresh.toStringAsFixed(1),
      'dryStraw': dryFodderStraw.toStringAsFixed(1),
      'concentrate': concentrateFresh.toStringAsFixed(2),
      'mineralMix': mineralMixGrams.toStringAsFixed(0),
      'water': waterReqLiters.toStringAsFixed(0),
      'dailyFeedCost': dailyFeedCost.toStringAsFixed(1),
      'milkRevenue': milkRevenue.toStringAsFixed(1),
      'dailyNetProfit': dailyNetProfit.toStringAsFixed(1),
      'feedCostRatio': feedCostRatio.toStringAsFixed(1),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 270.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF1565C0),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  tooltip: 'Scan Animal Tag',
                  onPressed: _showRfidScannerMock,
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Export Dairy Report',
                  onPressed: _showExportDialog,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Dynamic Gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1565C0),
                            Color(0xFF0D47A1),
                            Color(0xFF004D40),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Wave simulation painter
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _DairyHeroWavePainter(
                            progress: _waveController.value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded,
                                          color: Colors.greenAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'NDDB / ICAR Smart Standards',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Mandi Fat: ₹ ${_baseRatePerFat.toStringAsFixed(1)} / Unit',
                                  style: GoogleFonts.outfit(
                                    color: Colors.amber.shade200,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Dairy & Livestock Intelligence',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Precision Herd, Milk & Veterinary Management',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quick Stat Pills
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildHeroStatPill(
                                    icon: Icons.pets_rounded,
                                    label: 'Herd Size',
                                    value: '${_herdData.length} Heads',
                                    color: Colors.blueAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.local_drink_rounded,
                                    label: "Today's Milk",
                                    value:
                                        '${_todayTotalMilk.toStringAsFixed(1)} L',
                                    color: Colors.cyanAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.monetization_on_rounded,
                                    label: 'Est. Revenue',
                                    value:
                                        '₹ ${_calculatedDailyRevenue.toStringAsFixed(0)}',
                                    color: Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.favorite_rounded,
                                    label: 'Avg Health',
                                    value: '93.6%',
                                    color: Colors.greenAccent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.badge_rounded), text: 'Herd Registry'),
                  Tab(icon: Icon(Icons.water_drop_rounded), text: 'Milk & Fat Hub'),
                  Tab(icon: Icon(Icons.restaurant_rounded), text: 'Ration Balancer'),
                  Tab(icon: Icon(Icons.medical_services_rounded), text: 'Vet AI Triage'),
                  Tab(icon: Icon(Icons.event_note_rounded), text: 'Breeding Cycle'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildHerdRegistryTab(),
            _buildMilkFatHubTab(),
            _buildScientificRationTab(),
            _buildVeterinaryTriageTab(),
            _buildBreedingCalendarTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _showAddAnimalBottomSheet,
              backgroundColor: const Color(0xFF1565C0),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Register Cattle',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          } else if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _saveDailyMilkRecord,
              backgroundColor: const Color(0xFF00796B),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                'Commit Milk Log',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          } else if (_tabController.index == 3) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIAssistantScreen(),
                  ),
                );
              },
              backgroundColor: Colors.red.shade700,
              icon: const Icon(Icons.emergency_rounded, color: Colors.white),
              label: Text(
                'Emergency AI Vet',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeroStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: HERD REGISTRY & ANIMAL PROFILE SYSTEM
  // =========================================================================
  Widget _buildHerdRegistryTab() {
    final filteredList = _herdData.where((animal) {
      final matchesSearch = animal['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          animal['id']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          animal['breed']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      if (_selectedHerdFilter == 'All') return matchesSearch;
      if (_selectedHerdFilter == 'Lactating') {
        return matchesSearch && animal['status'].toString().contains('Lactating');
      }
      if (_selectedHerdFilter == 'Pregnant') {
        return matchesSearch && animal['status'].toString().contains('Pregnant');
      }
      if (_selectedHerdFilter == 'Desi/Indigenous') {
        return matchesSearch &&
            (animal['breed'].toString().contains('Gir') ||
                animal['breed'].toString().contains('Sahiwal'));
      }
      if (_selectedHerdFilter == 'Buffalo') {
        return matchesSearch && animal['species'] == 'Buffalo';
      }
      return matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Search & Tag Filter Header
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by Tag ID, Name or Breed...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF1565C0)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Lactating',
                      'Pregnant',
                      'Desi/Indigenous',
                      'Buffalo'
                    ].map((filter) {
                      final isSelected = _selectedHerdFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedHerdFilter = filter);
                          },
                          selectedColor: const Color(0xFF1565C0),
                          labelStyle: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live Health & Milk Distribution Gauge
        _buildHerdOverviewGauge(),

        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Animal Records (${filteredList.length})',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
              ),
            ),
            TextButton.icon(
              onPressed: _showBatchVaccinationDialog,
              icon: const Icon(Icons.vaccines_rounded, size: 16),
              label: const Text('Batch Vaccination'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...filteredList.map((animal) => _buildEnhancedAnimalCard(animal)),
      ],
    );
  }

  Widget _buildHerdOverviewGauge() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D47A1).withValues(alpha: 0.9),
            const Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Herd Productivity & Health Matrix',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Active herd milking efficiency: 83.3%',
                    style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco, size: 12, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Bio-Secure',
                      style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom segmented capacity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: 65,
                  child: Container(
                    height: 12,
                    color: Colors.greenAccent,
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Container(
                    height: 12,
                    color: Colors.amberAccent,
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Container(
                    height: 12,
                    color: Colors.purpleAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendDot(Colors.greenAccent, 'Lactating (4)'),
              _buildLegendDot(Colors.amberAccent, 'Pregnant/Dry (1)'),
              _buildLegendDot(Colors.purpleAccent, 'Sire/Bull (1)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedAnimalCard(Map<String, dynamic> animal) {
    final healthScore = animal['healthScore'] as int;
    final color = animal['color'] as Color;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showAnimalDetailsModal(animal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Icon(
                          animal['species'] == 'Buffalo'
                              ? Icons.shield_rounded
                              : animal['species'] == 'Goat'
                                  ? Icons.pest_control_rodent_rounded
                                  : Icons.pets_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                animal['name'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  animal['id'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${animal['breed']} • ${animal['ageYears']} yrs',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: healthScore >= 90
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: healthScore >= 90
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Text(
                          '$healthScore% Vigor',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: healthScore >= 90
                                ? Colors.green.shade800
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animal['currentYield'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bubble_chart_rounded,
                          size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'Status: ${animal['status']}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.pie_chart_outline,
                          size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        'Fat: ${animal['avgFat']}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_information_outlined,
                        size: 14, color: Colors.deepOrange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Next Event: ${animal['nextBooster']}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: SMART MILK & FAT QUALITY HUB
  // =========================================================================
  Widget _buildMilkFatHubTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Real-Time Production & Pricing Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00796B),
                Color(0xFF004D40),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF004D40).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Bulk Milk Yield & Revenue",
                    style: GoogleFonts.outfit(
                      color: Colors.teal.shade100,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Shift 1 + Shift 2',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _todayTotalMilk.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Liters',
                      style: GoogleFonts.outfit(
                        color: Colors.teal.shade100,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹ ${_calculatedDailyRevenue.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Total Shift Valuation',
                        style: TextStyle(
                            color: Colors.teal.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMilkHeroMetric(
                        'Morning', '${_morningMilk.toStringAsFixed(1)} L'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildMilkHeroMetric(
                        'Evening', '${_eveningMilk.toStringAsFixed(1)} L'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildMilkHeroMetric(
                        'Fat %', '${_fatPercentage.toStringAsFixed(1)}%'),
                    Container(width: 1, height: 24, color: Colors.white24),
                    _buildMilkHeroMetric(
                        'SNF %', '${_snfPercentage.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Shift Entry & Dials
        Text(
          'Daily Milk & Quality Log Entry',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Morning Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Morning Shift Volume',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_morningMilk.toStringAsFixed(1)} Liters',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00796B),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _morningMilk,
                  min: 0.0,
                  max: 100.0,
                  divisions: 200,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (val) => setState(() => _morningMilk = val),
                ),
                const SizedBox(height: 12),

                // Evening Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.nightlight_rounded,
                            color: Colors.indigo, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Evening Shift Volume',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_eveningMilk.toStringAsFixed(1)} Liters',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00796B),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _eveningMilk,
                  min: 0.0,
                  max: 100.0,
                  divisions: 200,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (val) => setState(() => _eveningMilk = val),
                ),
                const Divider(height: 24),

                // Fat & SNF Dials
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fat Content: ${_fatPercentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Slider(
                            value: _fatPercentage,
                            min: 2.5,
                            max: 10.0,
                            divisions: 75,
                            activeColor: Colors.amber.shade700,
                            onChanged: (v) =>
                                setState(() => _fatPercentage = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SNF Content: ${_snfPercentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Slider(
                            value: _snfPercentage,
                            min: 6.0,
                            max: 11.0,
                            divisions: 50,
                            activeColor: Colors.teal.shade700,
                            onChanged: (v) =>
                                setState(() => _snfPercentage = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Pricing Calculation Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cooperative Fat/SNF Formula',
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: _useFatFormula,
                      activeThumbColor: const Color(0xFF00796B),
                      onChanged: (val) =>
                          setState(() => _useFatFormula = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 🧠 AI ML MILK YIELD & QUALITY FORECASTER
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1565C0),
                Color(0xFF00796B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI ML Milk Yield & Quality Forecaster',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'RandomForest Model (R²: 0.91) • ICAR Benchmarks',
                            style: TextStyle(color: Colors.blue.shade100, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Controls for simulation
              Text(
                'Lactation Month: Month $_lactationMonth',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _lactationMonth.toDouble(),
                min: 1.0,
                max: 10.0,
                divisions: 9,
                activeColor: Colors.amberAccent,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _lactationMonth = v.toInt()),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Green Fodder: ${_dailyGreenFodder.toStringAsFixed(0)} kg',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Concentrate: ${_dailyConcentrate.toStringAsFixed(1)} kg',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Slider(
                value: _dailyGreenFodder,
                min: 10.0,
                max: 45.0,
                divisions: 35,
                activeColor: Colors.greenAccent,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _dailyGreenFodder = v),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dry Straw: ${_dailyDryFodder.toStringAsFixed(0)} kg',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Water: ${_dailyWater.toStringAsFixed(0)} Liters',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              Slider(
                value: _dailyConcentrate,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: Colors.cyanAccent,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _dailyConcentrate = v),
              ),

              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: _isPredictingMilk ? null : _runMlMilkPrediction,
                icon: _isPredictingMilk
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bolt_rounded, color: Colors.amber),
                label: Text(
                  _isPredictingMilk ? 'Running ML Inference...' : 'Calculate ML Production & Heat Stress',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D47A1),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (_mlMilkResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Predicted Daily Milk', style: TextStyle(color: Colors.teal.shade100, fontSize: 11)),
                              Text(
                                '${_mlMilkResult!['predicted_daily_yield_liters']} L',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Fat & SNF Profile', style: TextStyle(color: Colors.teal.shade100, fontSize: 11)),
                              Text(
                                '${_mlMilkResult!['predicted_fat_pct']}% Fat • ${_mlMilkResult!['predicted_snf_pct']}% SNF',
                                style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'THI Heat Index: ${_mlMilkResult!['thi_index']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            Text(
                              '${_mlMilkResult!['heat_stress_status']}',
                              style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💡 ${_mlMilkResult!['lactation_advice']}',
                        style: TextStyle(color: Colors.teal.shade50, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 7-Day Trend Chart
        Text(
          '7-Day Yield & Fat Trajectory',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                SizedBox(
                  height: 140,
                  child: CustomPaint(
                    painter: _MilkWeeklyChartPainter(history: _milkHistory),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: const Color(0xFF00796B),
                        ),
                        const SizedBox(width: 4),
                        const Text('Milk (Liters)',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        const Text('Fat Rate Index',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Historical Milk Slips
        Text(
          'Recent Daily Slips',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),
        ..._milkHistory.take(4).map((record) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  child: const Icon(Icons.receipt_rounded,
                      color: Color(0xFF00796B)),
                ),
                title: Text(
                  '${record['date']} • ${record['total']} Liters',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  'Fat: ${record['fat']}% | SNF: ${record['snf']}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Text(
                  '₹ ${record['revenue']}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildMilkHeroMetric(String label, String val) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: SCIENTIFIC FEED & RATION BALANCER (NRC/ICAR)
  // =========================================================================
  Widget _buildScientificRationTab() {
    final ration = _calculateScientificRation();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Nutritional Balance Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1565C0),
                Color(0xFF00838F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ICAR Ruminant Nutritional Rationing Engine',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ration['totalDm']} kg DM',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Total Dry Matter Required / Day',
                        style: TextStyle(
                            color: Colors.blue.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('Daily Feed Cost',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10)),
                        Text('₹ ${ration['dailyFeedCost']}',
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Feed vs Milk Profit Ratio Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Feed Cost Ratio: ${ration['feedCostRatio']}% of Revenue',
                      style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Net Margin: ₹ ${ration['dailyNetProfit']} / day',
                      style: GoogleFonts.outfit(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Animal Parameters Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal Parameters & Production Goals',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),

                // Breed Selector
                DropdownButtonFormField<String>(
                  value: _selectedBreedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Cattle Breed / Animal Category',
                    prefixIcon: const Icon(Icons.pets, color: Color(0xFF1565C0)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Crossbred Cow (HF/Jersey)',
                      child: Text('Crossbred Cow (HF/Jersey)'),
                    ),
                    DropdownMenuItem(
                      value: 'Dairy Buffalo (Murrah/Nili-Ravi)',
                      child: Text('Dairy Buffalo (Murrah/Nili-Ravi)'),
                    ),
                    DropdownMenuItem(
                      value: 'Indigenous Desi Cow (Gir/Sahiwal/Kankrej)',
                      child: Text('Indigenous Desi Cow (Gir/Sahiwal)'),
                    ),
                    DropdownMenuItem(
                      value: 'Dairy Goat (Jamnapari/Beetal)',
                      child: Text('Dairy Goat (Jamnapari/Beetal)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBreedCategory = val);
                  },
                ),
                const SizedBox(height: 14),

                // Weight Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Live Body Weight',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    Text('${_animalWeight.toInt()} kg',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1565C0))),
                  ],
                ),
                Slider(
                  value: _animalWeight,
                  min: 50.0,
                  max: 800.0,
                  divisions: 75,
                  activeColor: const Color(0xFF1565C0),
                  onChanged: (val) => setState(() => _animalWeight = val),
                ),
                const SizedBox(height: 6),

                // Daily Milk Yield Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target Milk Yield / Day',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    Text('${_dailyMilkYield.toStringAsFixed(1)} Liters',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00796B))),
                  ],
                ),
                Slider(
                  value: _dailyMilkYield,
                  min: 0.0,
                  max: 40.0,
                  divisions: 80,
                  activeColor: const Color(0xFF00796B),
                  onChanged: (val) => setState(() => _dailyMilkYield = val),
                ),
                const SizedBox(height: 8),

                // Gestating checkbox
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Animal is in Gestation / Pregnant',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  value: _isPregnant,
                  activeColor: const Color(0xFF1565C0),
                  onChanged: (val) => setState(() => _isPregnant = val ?? false),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _isCalculatingDiet ? null : _runSmartDietOptimization,
                  icon: _isCalculatingDiet
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent),
                  label: Text(
                    _isCalculatingDiet ? 'Optimizing Ration...' : 'Formulate ICAR Balanced Diet with AI',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Diet Formulation Breakdown
        Text(
          'Scientifically Balanced Daily Diet Plan',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        _buildDietCard(
          title: '🌿 Fresh Green Fodder',
          quantity: '${_smartDietResult?['recommended_daily_feed']?['green_fodder_kg'] ?? ration['greenFodder']} kg / day',
          examples: 'Hybrid Napier, Maize, Sorghum, Berseem, Lucerne',
          icon: Icons.grass_rounded,
          color: Colors.green.shade700,
        ),
        _buildDietCard(
          title: '🌾 Dry Fodder / Straw',
          quantity: '${_smartDietResult?['recommended_daily_feed']?['dry_straw_kg'] ?? ration['dryStraw']} kg / day',
          examples: 'Chopped Wheat Straw, Paddy Straw, Kadbi',
          icon: Icons.eco_rounded,
          color: Colors.amber.shade800,
        ),
        _buildDietCard(
          title: '🥣 Balanced Concentrate Mash',
          quantity: '${_smartDietResult?['recommended_daily_feed']?['concentrate_kg'] ?? ration['concentrate']} kg / day',
          examples: 'Grain (Maize/Barley 35%), Oil Cake (Mustard/Cotton 32%), Bran (30%)',
          icon: Icons.grain_rounded,
          color: Colors.indigo.shade700,
        ),
        _buildDietCard(
          title: '🧂 Mineral Mixture & Salt',
          quantity: '${_smartDietResult?['recommended_daily_feed']?['mineral_mixture_grams'] ?? ration['mineralMix']} grams / day',
          examples: 'Chelated trace minerals, Dicalcium Phosphate (DCP), Common Salt',
          icon: Icons.science_rounded,
          color: Colors.teal.shade700,
        ),
        _buildDietCard(
          title: '💧 Clean Fresh Drinking Water',
          quantity: '${_smartDietResult?['recommended_daily_feed']?['water_requirement_liters'] ?? ration['water']} Liters / day',
          examples: 'Ad libitum clean drinking water across 4 shifts',
          icon: Icons.water_drop_rounded,
          color: Colors.blue.shade700,
        ),

        if (_smartDietResult != null && _smartDietResult!['feeding_schedule'] != null) ...[
          const SizedBox(height: 20),
          Text(
            '⏰ 4-Shift Daily Feeding Schedule',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 10),
          ...List<Map<String, dynamic>>.from(_smartDietResult!['feeding_schedule']).map((sched) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: Color(0xFF1565C0), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            sched['time'] ?? '',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF1565C0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List<String>.from(sched['items'] ?? []).map((item) => Padding(
                            padding: const EdgeInsets.only(left: 24, bottom: 3),
                            child: Text('• $item', style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildDietCard({
    required String title,
    required String quantity,
    required String examples,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quantity,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    examples,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 4: VETERINARY AI TRIAGE & DISEASE ENCYCLOPEDIA
  // =========================================================================
  Widget _buildVeterinaryTriageTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // AI Symptom Triage Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade900,
                Colors.red.shade700,
                const Color(0xFF1565C0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseController,
                    child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Veterinary AI Medical Doctor',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Instant Clinical Triage, Prescriptions & First-Aid',
                          style: TextStyle(color: Colors.red.shade100, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Body Temperature Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Animal Body Temperature', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _cattleBodyTemp > 103.0 ? Colors.redAccent : Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_cattleBodyTemp.toStringAsFixed(1)} °F ${_cattleBodyTemp > 103.0 ? '(High Fever)' : '(Normal)'}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _cattleBodyTemp,
                min: 98.0,
                max: 108.0,
                divisions: 50,
                activeColor: _cattleBodyTemp > 103.0 ? Colors.amberAccent : Colors.white,
                inactiveColor: Colors.white24,
                onChanged: (v) => setState(() => _cattleBodyTemp = v),
              ),

              // Symptom Selector Chips
              Text('Select Observed Symptoms:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildSymptomChip('skin_nodules', 'Hard Skin Nodules / Lumps'),
                  _buildSymptomChip('swollen_hot_udder', 'Swollen Udder / Clots'),
                  _buildSymptomChip('mouth_hoof_blisters', 'Mouth & Hoof Sores'),
                  _buildSymptomChip('salivation_drooling', 'Frothy Salivation'),
                  _buildSymptomChip('swollen_throat_dewlap', 'Swollen Throat / Neck'),
                  _buildSymptomChip('left_flank_bloat', 'Left Flank Bloat'),
                  _buildSymptomChip('recumbency_downer_cow', 'Downer Cow (Inability to Stand)'),
                  _buildSymptomChip('sweet_acetone_breath', 'Sweet Acetone Breath'),
                  _buildSymptomChip('tick_infestation_pale_eye', 'Tick Fever / Pale Eyes'),
                  _buildSymptomChip('drop_in_milk', 'Sudden Drop in Milk'),
                  _buildSymptomChip('loss_of_appetite', 'Loss of Appetite'),
                ],
              ),
              const SizedBox(height: 12),

              // Custom Free Text Note
              TextField(
                controller: _symptomTextController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Additional notes (e.g. 3 days sick, shivering, discharge)...',
                  hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white12,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDiagnosingVet ? null : _runVetDiagnosticTriage,
                      icon: _isDiagnosingVet
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.medical_services_rounded, color: Colors.red),
                      label: Text(
                        _isDiagnosingVet ? 'Analyzing...' : 'Run AI Medical Triage',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade900,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                      );
                    },
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    tooltip: 'AI Chat Assistant',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Visual Symptom Checklist
        Text(
          'Visual Body Symptom Selector',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.88,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildBodyMarkerCard('Mouth & Saliva', 'Blisters/Drooling',
                Icons.face_retouching_natural_rounded),
            _buildBodyMarkerCard('Udder & Milk', 'Swelling/Clots',
                Icons.water_drop_rounded),
            _buildBodyMarkerCard('Skin & Coat', 'Lumps/Alopecia',
                Icons.lens_blur_rounded),
            _buildBodyMarkerCard('Hoofs & Legs', 'Lameness/Wounds',
                Icons.run_circle_outlined),
            _buildBodyMarkerCard('Digestion/Belly', 'Bloat/Diarrhea',
                Icons.bubble_chart_rounded),
            _buildBodyMarkerCard('Breathing/Fever', 'Shivering/Panting',
                Icons.thermostat_rounded),
          ],
        ),
        const SizedBox(height: 22),

        // Disease Encyclopedia Cards
        Text(
          'Livestock Disease Encyclopedia (${_diseaseEncyclopedia.length})',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ..._diseaseEncyclopedia.map((d) => _buildDiseaseEncyclopediaCard(d)),
      ],
    );
  }

  Widget _buildSymptomChip(String key, String label) {
    final isSelected = _selectedSymptomTags.contains(key);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.red.shade900 : Colors.white,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.white,
      backgroundColor: Colors.white24,
      checkmarkColor: Colors.red.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.white : Colors.white30),
      ),
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedSymptomTags.add(key);
          } else {
            _selectedSymptomTags.remove(key);
          }
        });
      },
    );
  }

  Widget _buildBodyMarkerCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analyzing symptoms for: $title ($subtitle)...'),
              backgroundColor: const Color(0xFF1565C0),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF1565C0), size: 24),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseEncyclopediaCard(Map<String, dynamic> d) {
    final symptoms = d['symptoms'] as List<String>;
    final firstAid = d['firstAid'] as List<String>;
    final badgeColor = d['badgeColor'] as Color;
    final diseasePhoto = d['diseasePhoto'] as String?;
    final medicinePhoto = d['medicinePhoto'] as String?;
    final medicineName = d['medicineName'] as String? ?? 'Prescribed Veterinary Remedy';
    final medicineDosage = d['medicineDosage'] as String? ?? 'Administer under registered veterinarian supervision.';
    final medType = d['medType'] as String? ?? 'Veterinary Formulation';
    final medicineWarning = d['medicineWarning'] as String? ?? 'Schedule H Drug: Administer under veterinary supervision.';
    final organicPhoto = d['organicPhoto'] as String?;
    final organicName = d['organicName'] as String? ?? 'NDDB Ethno-Veterinary Formulation';
    final organicIngredients = d['organicIngredients'] as String? ?? 'Natural herbal ingredients.';
    final organicDosage = d['organicDosage'] as String? ?? 'Administer orally or topically.';
    final organicBenefits = d['organicBenefits'] as String? ?? 'Zero milk withdrawal time, natural healing.';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.12),
          radius: 22,
          child: Icon(Icons.medical_services_outlined, color: badgeColor, size: 22),
        ),
        title: Text(
          d['name'] as String,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'Target: ${d['species']} • ${d['agent']}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                d['severity'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 16),

          // -----------------------------------------------------------------
          // 3-PHOTO VISUAL IDENTIFICATION: Disease Symptoms, Vet Drug, Organic Remedy
          // -----------------------------------------------------------------
          Text(
            '📸 Visual Identification & Remedy Packaging (Tap to Enlarge):',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Disease Symptom Photo Card
                SizedBox(
                  width: 135,
                  child: _buildDairyPhotoTile(
                    title: 'Clinical Signs',
                    tag: '🔍 Symptoms',
                    tagColor: Colors.red.shade700,
                    imageUrl: diseasePhoto,
                    icon: Icons.pets_rounded,
                    onTap: () => _showDairyPhotoDetailDialog(
                      context,
                      title: '${d['name']} - Symptoms',
                      imageUrl: diseasePhoto ?? '',
                      tag: 'Livestock Clinical Symptoms',
                      description: 'Observed clinical symptoms in herd: ${symptoms.join(". ")}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Allopathic / Vet Medicine Photo Card
                SizedBox(
                  width: 145,
                  child: _buildDairyPhotoTile(
                    title: 'Vet Medicine / Pack',
                    tag: '💊 Chemical/Drug',
                    tagColor: const Color(0xFF1565C0),
                    imageUrl: medicinePhoto,
                    icon: Icons.medication_rounded,
                    onTap: () => _showDairyPhotoDetailDialog(
                      context,
                      title: medicineName,
                      imageUrl: medicinePhoto ?? '',
                      tag: medType,
                      description: 'Prescribed Regimen: $medicineDosage\n\n⚠️ Caution: $medicineWarning',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 3. Organic & Ayurvedic Remedy Photo Card
                SizedBox(
                  width: 145,
                  child: _buildDairyPhotoTile(
                    title: 'Organic / Bio Remedy',
                    tag: '🌿 NDDB Ethno-Vet',
                    tagColor: Colors.green.shade800,
                    imageUrl: organicPhoto,
                    icon: Icons.eco_rounded,
                    onTap: () => _showDairyPhotoDetailDialog(
                      context,
                      title: organicName,
                      imageUrl: organicPhoto ?? '',
                      tag: 'ICAR-NDDB Ethno-Veterinary',
                      description: 'Ingredients: $organicIngredients\n\nApplication: $organicDosage\n\nBenefits: $organicBenefits',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // -----------------------------------------------------------------
          // OPTION A: ALLOPATHIC VETERINARY PRESCRIPTION & DOSAGE
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF1565C0), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        medicineName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: const Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        medType,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '🧪 Certified Dosage: $medicineDosage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚠️ $medicineWarning',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // -----------------------------------------------------------------
          // OPTION B: CERTIFIED ORGANIC & ETHNO-VETERINARY REMEDY
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        organicName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🌿 NDDB Organic',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '🌱 Ingredients: $organicIngredients',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '🥣 Preparation & Application: $organicDosage',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '✨ Benefit: $organicBenefits',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  'Key Recognizable Symptoms:',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...symptoms.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.healing_rounded, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Immediate First-Aid Protocols:',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...firstAid.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                            fontSize: 12, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prevention: ${d['prevention']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDairyPhotoTile({
    required String title,
    required String tag,
    required Color tagColor,
    required String? imageUrl,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 115,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDairyPhotoFallback(icon, title),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              )
            else
              _buildDairyPhotoFallback(icon, title),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDairyPhotoFallback(IconData icon, String title) {
    return Container(
      color: Colors.blueGrey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.blueGrey.shade700),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  void _showDairyPhotoDetailDialog(
    BuildContext context, {
    required String title,
    required String imageUrl,
    required String tag,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.black87,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: Colors.white70, size: 48),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.medical_information_rounded,
                              color: Colors.white70, size: 48),
                        ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    label: const Text('Understood / Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 5: BREEDING & INSEMINATION CALENDAR
  // =========================================================================
  Widget _buildBreedingCalendarTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Breeding Radar Hero
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4527A0),
                Color(0xFF1565C0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artificial Insemination (AI) & Heat Radar',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gestation: 283 Days (Cow) • 310 Days (Buffalo)',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBreedingPill('Inseminated', '2 Animals'),
                  _buildBreedingPill('Calving in 7d', '1 Animal (Champa)'),
                  _buildBreedingPill('Estrus Heat due', 'Radha (Day 18)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Reproductive Stages & Expected Calving',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ..._herdData.where((a) => a['inseminationDate'] != 'N/A').map((a) {
          final isCloseCalving = a['expectedCalving'].toString().contains('Aug');
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${a['name']} (${a['id']})',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCloseCalving
                              ? Colors.red.shade50
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCloseCalving
                                ? Colors.red.shade300
                                : Colors.purple.shade200,
                          ),
                        ),
                        child: Text(
                          isCloseCalving ? '🚨 Calving Alert' : a['status'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCloseCalving
                                ? Colors.red.shade900
                                : Colors.purple.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Insemination Date: ${a['inseminationDate']}'),
                  Text('Expected Calving Date: ${a['expectedCalving']}'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: isCloseCalving ? 0.95 : 0.45,
                    backgroundColor: Colors.grey.shade200,
                    color: isCloseCalving ? Colors.red : Colors.purple,
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBreedingPill(String top, String bottom) {
    return Column(
      children: [
        Text(top,
            style: TextStyle(color: Colors.purple.shade100, fontSize: 11)),
        const SizedBox(height: 2),
        Text(bottom,
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // =========================================================================
  // MODALS & DIALOGS
  // =========================================================================
  void _showAddAnimalBottomSheet() {
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    String species = 'Cow';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Register New Cattle / Animal',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: species,
                  decoration: const InputDecoration(labelText: 'Species'),
                  items: const [
                    DropdownMenuItem(value: 'Cow', child: Text('Cow')),
                    DropdownMenuItem(value: 'Buffalo', child: Text('Buffalo')),
                    DropdownMenuItem(value: 'Goat', child: Text('Goat')),
                    DropdownMenuItem(value: 'Sheep', child: Text('Sheep')),
                    DropdownMenuItem(value: 'Bull', child: Text('Bull / Sire')),
                  ],
                  onChanged: (v) => setModalState(() => species = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Animal Nickname / Identifier'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ear Tag ID (e.g. TAG-IN-9812)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Breed (e.g. HF Cross / Murrah)'),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() {
                        _herdData.add({
                          'id': tagCtrl.text.isEmpty
                              ? 'TAG-IN-${math.Random().nextInt(9000) + 1000}'
                              : tagCtrl.text,
                          'name': nameCtrl.text,
                          'species': species,
                          'breed': breedCtrl.text.isEmpty
                              ? 'HF Crossbred'
                              : breedCtrl.text,
                          'ageYears': 3.0,
                          'status': 'Lactating',
                          'lactationStage': 'Early',
                          'currentYield': '14.0 L/day',
                          'avgFat': '4.2%',
                          'inseminationDate': 'Not bred yet',
                          'expectedCalving': '--',
                          'vaccinationStatus': 'Pending Initial Shots',
                          'nextBooster': 'FMD in 14 days',
                          'healthScore': 95,
                          'color': const Color(0xFF1565C0),
                          'notes': 'Newly registered animal in herd.',
                        });
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ ${nameCtrl.text} added to herd!'),
                          backgroundColor: const Color(0xFF1565C0),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Complete Registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAnimalDetailsModal(Map<String, dynamic> animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${animal['name']} • ${animal['id']}',
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              dense: true,
              leading: const Icon(Icons.pets, color: Color(0xFF1565C0)),
              title: Text('Breed & Age: ${animal['breed']} (${animal['ageYears']} Years)'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.water_drop, color: Colors.teal),
              title: Text('Milk Yield: ${animal['currentYield']} (Avg Fat: ${animal['avgFat']})'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.medical_information, color: Colors.red),
              title: Text('Vaccination: ${animal['vaccinationStatus']}'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.notes, color: Colors.grey),
              title: Text('Special Notes: ${animal['notes']}'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _tabController.animateTo(2); // Jump to ration tab
              },
              icon: const Icon(Icons.restaurant),
              label: Text('Formulate Feed Ration for ${animal['name']}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDailyMilkRecord() {
    setState(() {
      _milkHistory.insert(0, {
        'date': 'Today (Logged)',
        'morning': _morningMilk,
        'evening': _eveningMilk,
        'total': _todayTotalMilk,
        'fat': _fatPercentage,
        'snf': _snfPercentage,
        'revenue': _calculatedDailyRevenue,
        'shift': 'Both Shifts Complete'
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ Daily Milk (${_todayTotalMilk.toStringAsFixed(1)} L) committed to cloud!'),
        backgroundColor: const Color(0xFF00796B),
      ),
    );
  }

  void _showRfidScannerMock() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📡 RFID Scanner active • Listening for NFC ear tags...'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  void _showExportDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 PDF Dairy Herd & Milk Audit report generated!'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _showBatchVaccinationDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💉 Batch FMD/HS booster scheduled for entire herd!'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

// =========================================================================
// CUSTOM ANIMATED WAVE PAINTER
// =========================================================================
class _DairyHeroWavePainter extends CustomPainter {
  final double progress;

  _DairyHeroWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.7 +
            math.sin((i / size.width * 2 * math.pi) + (progress * 2 * math.pi)) *
                15,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DairyHeroWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =========================================================================
// CUSTOM 7-DAY MILK TREND CHART PAINTER
// =========================================================================
class _MilkWeeklyChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;

  _MilkWeeklyChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF00796B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00796B).withValues(alpha: 0.3),
          const Color(0xFF00796B).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final pathLine = Path();
    final pathFill = Path();

    final stepX = size.width / (history.length - 1);
    final maxMilk = 35.0;

    for (int i = 0; i < history.length; i++) {
      final val = (history[i]['total'] as num).toDouble();
      final x = i * stepX;
      final y = size.height - (val / maxMilk * size.height * 0.85);

      if (i == 0) {
        pathLine.moveTo(x, y);
        pathFill.moveTo(x, y);
      } else {
        pathLine.lineTo(x, y);
        pathFill.lineTo(x, y);
      }

      // Draw node dot
      final dotPaint = Paint()..color = const Color(0xFF004D40);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    pathFill.lineTo(size.width, size.height);
    pathFill.lineTo(0, size.height);
    pathFill.close();

    canvas.drawPath(pathFill, paintFill);
    canvas.drawPath(pathLine, paintLine);
  }

  @override
  bool shouldRepaint(covariant _MilkWeeklyChartPainter oldDelegate) => true;
}
