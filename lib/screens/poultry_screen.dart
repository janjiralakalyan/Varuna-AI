import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_screen.dart';

class PoultryScreen extends StatefulWidget {
  const PoultryScreen({super.key});

  @override
  State<PoultryScreen> createState() => _PoultryScreenState();
}

class _PoultryScreenState extends State<PoultryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  // Search & Filters
  String _searchQuery = '';
  String _selectedBatchFilter = 'All';

  // ----------------------------------------------------
  // FCR & FEED COST CALCULATOR STATE
  // ----------------------------------------------------
  double _feedConsumedKg = 3450.0;
  double _totalLiveWeightKg = 2150.0;
  int _birdCount = 1200;
  double _feedCostPerKg = 39.50;
  double _chickCostPerBird = 36.00;
  double _medicineCostPerBird = 14.00;
  double _liveBirdSellingRate = 112.00; // ₹ per kg live weight

  // ----------------------------------------------------
  // EGG PRODUCTION TRACKER STATE
  // ----------------------------------------------------
  int _activeLayersCount = 950;
  int _dailyEggsCollected = 874;
  int _damagedEggs = 8;
  double _trayMandiRate = 185.0; // ₹ per tray of 30 eggs

  final List<Map<String, dynamic>> _eggHistory = [
    {'day': 'Today (14 Aug)', 'eggs': 874, 'damaged': 8, 'rate': 92.0, 'rev': 5390.0},
    {'day': '13 Aug', 'eggs': 880, 'damaged': 6, 'rate': 92.6, 'rev': 5430.0},
    {'day': '12 Aug', 'eggs': 865, 'damaged': 10, 'rate': 91.0, 'rev': 5335.0},
    {'day': '11 Aug', 'eggs': 870, 'damaged': 7, 'rate': 91.5, 'rev': 5368.0},
    {'day': '10 Aug', 'eggs': 855, 'damaged': 12, 'rate': 90.0, 'rev': 5275.0},
    {'day': '09 Aug', 'eggs': 860, 'damaged': 9, 'rate': 90.5, 'rev': 5308.0},
    {'day': '08 Aug', 'eggs': 850, 'damaged': 8, 'rate': 89.4, 'rev': 5245.0},
  ];

  // ----------------------------------------------------
  // BATCH DATA LIST
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _batches = [
    {
      'id': 'BATCH-B24-08',
      'name': 'Broiler Shed 1 (East Wing)',
      'type': 'Commercial Broiler',
      'breed': 'Cobb 500 Fast Growth',
      'initialCount': 1250,
      'currentCount': 1228,
      'mortalityCount': 22,
      'mortalityRate': '1.76%',
      'ageDays': 32,
      'currentAvgWeight': '1.92 kg',
      'targetWeight': '2.10 kg at Day 36',
      'fcr': 1.58,
      'stage': 'Finisher Pellets',
      'vaccine': 'Day 28 Lasota Booster Complete',
      'color': const Color(0xFFD84315),
      'status': 'Harvesting in 4 Days',
    },
    {
      'id': 'BATCH-L23-11',
      'name': 'Layer House A (Cage System)',
      'type': 'Commercial Layer',
      'breed': 'BV 300 White Leghorn',
      'initialCount': 1000,
      'currentCount': 978,
      'mortalityCount': 22,
      'mortalityRate': '2.2%',
      'ageDays': 148,
      'currentAvgWeight': '1.65 kg',
      'targetWeight': 'Peak Laying (92% Lay)',
      'fcr': 2.10,
      'stage': 'Phase-1 Layer Mash',
      'vaccine': 'Coryza & ND-IB Inactivated given',
      'color': const Color(0xFFE65100),
      'status': 'Active Laying Phase',
    },
    {
      'id': 'BATCH-CR-02',
      'name': 'Free-Range Desi Farm',
      'type': 'Indigenous Country Chicken',
      'breed': 'Kadaknath & Aseel Cross',
      'initialCount': 350,
      'currentCount': 344,
      'mortalityCount': 6,
      'mortalityRate': '1.71%',
      'ageDays': 65,
      'currentAvgWeight': '1.25 kg',
      'targetWeight': '1.50 kg Premium Live',
      'fcr': 2.45,
      'stage': 'Organic Grain & Forage',
      'vaccine': 'Marek & Ranikhet done',
      'color': const Color(0xFFBF360C),
      'status': 'Organic Premium Retail',
    },
    {
      'id': 'BATCH-B24-09',
      'name': 'Broiler Shed 2 (New Flock)',
      'type': 'Commercial Broiler',
      'breed': 'Ross 308 Heavy Breed',
      'initialCount': 1500,
      'currentCount': 1492,
      'mortalityCount': 8,
      'mortalityRate': '0.53%',
      'ageDays': 8,
      'currentAvgWeight': '0.22 kg',
      'targetWeight': 'Starter Stage Growth',
      'fcr': 1.12,
      'stage': 'Starter Crumbles',
      'vaccine': 'Day 7 Gumboro IBD Due Tomorrow',
      'color': const Color(0xFFFF6F00),
      'status': 'Brooding Week 2',
    },
  ];

  // ----------------------------------------------------
  // POULTRY DISEASE ENCYCLOPEDIA & REMEDY GALLERY
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _poultryDiseases = [
    {
      'name': 'Newcastle Disease (Ranikhet - ND)',
      'agent': 'Avian Paramyxovirus Serotype 1',
      'severity': 'Critical (Catastrophic Mortality)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'ND LaSota Live Vaccine & Vimeral Immuno-Tonic',
      'medicineDosage':
          '1000-dose live vaccine vial reconstituted in 15-20L chilled skimmed milk water (morning drink within 2h); 10 ml Vimeral (Vit A, D3, E, B12) / 100 birds.',
      'medType': 'Live Viral Vaccine & Liquid Vitamin Booster',
      'medicineWarning': 'Schedule H / Biological: Administer only to healthy flocks; store vaccine vial at 2°C–8°C.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Herbal Immuno-Booster Decoction (Turmeric, Ginger & Holy Basil)',
      'organicIngredients': 'Fresh Raw Turmeric (Curcumin 200g) + Ginger (100g) + Tulsi Leaves (100g) + Black Pepper (20g) + Jaggery (500g).',
      'organicDosage': 'Boil ingredients in 5 Liters water for 20 minutes. Filter and mix 20 ml of decoction per 1 Liter drinking water for 5 consecutive days.',
      'organicBenefits': 'Natural antiviral, anti-inflammatory, and strong humoral immune stimulant with 0% chemical residues.',
      'symptoms': [
        'Gasping for air, coughing, and sneezing with rales',
        'Twisting of head and neck (Torticollis / Stargazing)',
        'Bright greenish watery diarrhea',
        'Complete cessation of egg production with shell-less eggs',
        'Sudden high mortality up to 90% in unvaccinated flocks'
      ],
      'firstAid': [
        'Immediate emergency vaccination with ND LaSota via drinking water if early.',
        'Immunity booster: Vitamin E + Selenium + Vitamin C in drinking water.',
        'Broad-spectrum antibiotics to control secondary E. coli complications.',
        'Strict isolation of the entire shed; burn or deeply bury carcasses.'
      ],
      'prevention':
          'Day 7 F1/LaSota eye-drop, Day 21 LaSota water, Day 14 weeks killed vaccine.',
      'badgeColor': Colors.red.shade800,
    },
    {
      'name': 'Infectious Bursal Disease (Gumboro - IBD)',
      'agent': 'Avibirnavirus (Birnaviridae)',
      'severity': 'High (Severe Immunosuppression)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'IBD Intermediate Plus Vaccine + Electral-Vet Kidney Flusher',
      'medicineDosage':
          'Intermediate Plus vaccine at Day 12-14 in water; 5g Electral-Vet (Potassium citrate + Sodium salts) / Liter water for 4 consecutive days.',
      'medType': 'Live Intermediate Vaccine & Electrolyte Kidney Flusher',
      'medicineWarning': 'Reduce crude protein in feed to 16% during outbreak to prevent fatal uric acid deposition in kidneys.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Natural Kidney Flusher & Electrolyte Hydration Drench',
      'organicIngredients': 'Coriander Seed decoction (250g) + Pure Jaggery (1 kg) + Rock Salt (50g) + Fresh Lemon Juice (100ml) per 1000 birds.',
      'organicDosage': 'Mix boiled coriander extract and jaggery in morning water (10-15 Liters) for 3-5 days to clear tubular nephrosis.',
      'organicBenefits': 'Flushes kidney urates safely, restores mineral electrolyte balance, and prevents visceral gout.',
      'symptoms': [
        'Severe vent picking, ruffled feathers, and depression',
        'Whitish-yellow watery diarrhea with soiled vent feathers',
        'Severe trembling, dehydration, and subnormal body temperature',
        'Swollen, gelatinous Bursa of Fabricius with hemorrhages'
      ],
      'firstAid': [
        'Provide Electrolytes + Glucose + Vitamin C in water to combat dehydration.',
        'Liver tonic + Kidney flusher (Potassium Citrate drench) for 3-5 days.',
        'Reduce protein content in feed slightly to relieve kidney strain.',
        'Avoid chilling; maintain comfortable warm brooding temperature.'
      ],
      'prevention':
          'Day 12-14 Intermediate Plus IBD vaccine in drinking water with skimmed milk.',
      'badgeColor': Colors.deepOrange.shade800,
    },
    {
      'name': 'Coccidiosis (Bloody Enteritis)',
      'agent': 'Eimeria tenella / Eimeria necatrix (Protozoa)',
      'severity': 'High (Wet Litter Acute Hazard)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1589923188900-85dae523342b?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Toltrazuril 2.5% (Baycox) / Amprolium 20% + Vitamin K3',
      'medicineDosage':
          'Toltrazuril 2.5%: 1 ml / Liter drinking water for 2 consecutive days (24h/day continuous) OR Amprolium 20%: 1.25g / Liter water for 5-7 days.',
      'medType': 'Anticoccidial Solution & Hemostatic Anti-Bleeding Remedy',
      'medicineWarning': 'Withdrawal period: 8 days for broiler meat. Add Vitamin K3 (20mg/L) to prevent intestinal hemorrhages.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Oregano Oil, Garlic & Apple Cider Vinegar Coccidiostat',
      'organicIngredients': 'Organic Apple Cider Vinegar (ACV with Mother) + Crushed Garlic extract + Oregano essential oil (Carvacrol 60%).',
      'organicDosage': '5 ml Apple Cider Vinegar + 2 ml pure Garlic extract per Liter drinking water for 5 days. Spread dry slaked lime on wet litter patches.',
      'organicBenefits': 'Natural gut acidifier (pH < 4.5) destroys Eimeria oocyst sporulation and repairs intestinal villi mucosa.',
      'symptoms': [
        'Bloody droppings / frank red blood in feces',
        'Huddled posture, pale combs and wattles from anemia',
        'Sharp decline in feed intake with high thirst',
        'Severe cecal core enlargement with clotted blood'
      ],
      'firstAid': [
        'Immediate treatment with Amprolium (20%) or Toltrazuril (Baycox) in water.',
        'Vitamin K3 supplement in water to arrest intestinal hemorrhages.',
        'Remove wet caked litter immediately; spread dry lime powder and fresh husk.',
        'Ensure drinker bell height is adjusted to prevent water spillage.'
      ],
      'prevention': 'Coccidiostats in starter feed; maintain litter moisture < 25%.',
      'badgeColor': Colors.amber.shade900,
    },
    {
      'name': 'Chronic Respiratory Disease (CRD / Mycoplasma)',
      'agent': 'Mycoplasma gallisepticum + Secondary E. coli',
      'severity': 'Medium-High (Growth Stunting & Tracheitis)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1563281577-a7be47e20db9?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Tylosin Tartrate (Tylodox) / Enrofloxacin 10% Oral + Respo-Clear',
      'medicineDosage':
          'Tylosin Tartrate: 0.5g to 1g per Liter drinking water for 3-5 days. For acute co-infections: Enrofloxacin 10% at 1 ml / Liter for 4 days.',
      'medType': 'Macrolide / Fluoroquinolone Antibacterial & Mucolytic',
      'medicineWarning': 'Schedule H Prescription Drug: Strictly adhere to recommended course duration to avoid bacterial resistance.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Eucalyptus, Menthol & Ginger Respiratory Steam & Drench',
      'organicIngredients': 'Eucalyptus Oil (Nilgiri 50ml) + Camphor (10g) + Crushed Ginger (100g) + Peppermint extract (20ml).',
      'organicDosage': 'Aerosol fogging in closed shed (10 ml oil mix in 5L boiling water) at dusk; 2 ml ginger-mint extract / Liter drinking water.',
      'organicBenefits': 'Instantly clears mucus plugs from trachea, opens bronchial passages, and alleviates snicking sounds naturally.',
      'symptoms': [
        'Facial swelling, foamy eye discharge, and conjunctivitis',
        'Persistent snicking, tracheal rales, and open-mouth breathing',
        'Sharp FCR worsening and failure to gain daily target weight',
        'Cheesy air sacculitis and pericarditis on post-mortem'
      ],
      'firstAid': [
        'Administer Tylosin Tartrate or Tilmicosin / Enrofloxacin in water for 4 days.',
        'Mucolytic agents (Bromhexine) to liquefy tracheal mucus plugs.',
        'Fogging with eucalyptus/menthol disinfectant spray in the shed.',
        'Increase side curtain ventilation to clear toxic ammonia gas fumes.'
      ],
      'prevention': 'Mycoplasma-free chicks; maintain ammonia levels < 15 ppm.',
      'badgeColor': Colors.purple.shade800,
    },
    {
      'name': 'Fowl Pox (Avian Diphtheria)',
      'agent': 'Avipoxvirus (Poxviridae)',
      'severity': 'Moderate to High (Loss of Appetite)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1598463844078-a3d001974782?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Fowl Pox Live Vaccine (Wing-Web) & Povidone Iodine 5%',
      'medicineDosage':
          'Single wing-web puncture with double-needle applicator at 6-8 weeks age. Paint external dry scabs with 5% Povidone Iodine ointment twice daily.',
      'medType': 'Live Attenuated Tissue-Culture Vaccine & Topical Antiseptic Paint',
      'medicineWarning': 'Never peel comb/eyelid scabs forcefully as it causes massive hemorrhages and secondary bacterial infection.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1588681664899-f142ff2dc9b1?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Neem Oil & Pure Turmeric Healing Antiseptic Paste',
      'organicIngredients': 'Cold-Pressed Pure Neem Oil (100 ml) + Organic Turmeric Powder (50g) + Pure Honey (20g).',
      'organicDosage': 'Gently apply warm neem-turmeric paste over comb, wattle, and eyelid lesions twice daily using sterile cotton swab.',
      'organicBenefits': 'Potent natural antiviral, antifungal, and healing agent that dries scabs safely without leaving scar tissue.',
      'symptoms': [
        'Wart-like nodular eruptions on comb, wattles, eyelids, and unfeathered skin',
        'Yellowish cheesy diphtheritic patches inside mouth and throat',
        'Difficulty swallowing and breathing; severe drop in feed consumption',
        'Eyelids swollen shut from scab formation'
      ],
      'firstAid': [
        'Gently paint external scabs with Povidone Iodine or Boroglycerine; never peel scabs forcefully.',
        'Add broad-spectrum antibiotic to drinking water to prevent secondary infection.',
        'Add Vitamin A + C supplements to enhance epithelial regeneration.',
        'Isolate severely affected birds with throat lesions.'
      ],
      'prevention':
          'Fowl pox wing-web vaccination at 6 to 8 weeks of age before mosquito season.',
      'badgeColor': Colors.teal.shade800,
    },
    {
      'name': 'Colibacillosis & Damp Litter Infection',
      'agent': 'Escherichia coli (APEC strains)',
      'severity': 'High (Systemic Septicemia & Airsacculitis)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Virkon-S Biosecurity Sanitizer + Colistin Sulphate Powder',
      'medicineDosage':
          'Virkon-S 1:200 mist spray over birds and shed floor; Colistin Sulphate 1g per 5 Liters drinking water for 3 consecutive days.',
      'medType': 'Broad-Spectrum Biosecurity Disinfectant & Intestinal Polypeptide',
      'medicineWarning': 'Litter moisture must be kept under 20% by turning and adding dry rice husk to stop ammonia generation.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1509358271058-acd22cc93898?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Hydrated Slaked Lime & Dry Neem Leaf Litter Conditioner',
      'organicIngredients': 'Dry Slaked Lime Powder (Calcium Hydroxide 100g/m²) + Crushed Dry Neem Leaves (50g/m²) + Zeolite powder.',
      'organicDosage': 'Rake top wet litter cakes, dust slaked lime and neem leaves evenly on floor bed, then top with 2 inches fresh dry wood shavings/paddy husk.',
      'organicBenefits': 'Absorbs floor moisture instantly, destroys E. coli bacteria & fly maggots, and eliminates toxic ammonia fumes.',
      'symptoms': [
        'Huddled chicks around brooding hover with pasted vents',
        'Fibrinous pericarditis and perihepatitis (white film over liver & heart)',
        'Yellowish watery diarrhea with pungent ammonia odor in shed',
        'Enlarged infected yolk sacs (omphalitis) in young chicks'
      ],
      'firstAid': [
        'Water acidification with organic acids (Citric acid 1g/L) to lower gut pH.',
        'Administer Colistin Sulphate or Neomycin in drinking water.',
        'Rake and remove wet litter cakes; dust floor with dry slaked lime.',
        'Sanitize overhead drinker tanks with chlorine or hydrogen peroxide.'
      ],
      'prevention':
          'Maintain drinker height, clean water sanitization, and litter moisture < 20%.',
      'badgeColor': Colors.brown.shade800,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // COMPUTED CALCULATIONS
  // ----------------------------------------------------
  double get _calculatedFCR =>
      _totalLiveWeightKg > 0 ? (_feedConsumedKg / _totalLiveWeightKg) : 0.0;

  double get _avgWeightPerBird =>
      _birdCount > 0 ? (_totalLiveWeightKg / _birdCount) : 0.0;

  double get _feedCostPerBird =>
      _birdCount > 0 ? ((_feedConsumedKg / _birdCount) * _feedCostPerKg) : 0.0;

  double get _totalCostPerBird =>
      _feedCostPerBird + _chickCostPerBird + _medicineCostPerBird;

  double get _revenuePerBird => _avgWeightPerBird * _liveBirdSellingRate;

  double get _profitPerBird => _revenuePerBird - _totalCostPerBird;

  double get _totalBatchProfit => _profitPerBird * _birdCount;

  double get _eggLayingRate => _activeLayersCount > 0
      ? ((_dailyEggsCollected / _activeLayersCount) * 100.0)
      : 0.0;

  int get _packedTraysCount => (_dailyEggsCollected / 30).floor();

  double get _dailyEggRevenue => (_dailyEggsCollected / 30.0) * _trayMandiRate;

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
              backgroundColor: const Color(0xFFD84315),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                  tooltip: 'Flock Analytics',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  tooltip: 'Export Batch Report',
                  onPressed: _showExportToast,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFD84315),
                            Color(0xFFBF360C),
                            Color(0xFF4E342E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                                      const Icon(Icons.egg_rounded,
                                          color: Colors.amberAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Commercial Aviary Intelligence',
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
                                  'Mandi Live Bird: ₹ ${_liveBirdSellingRate.toStringAsFixed(0)}/kg',
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
                              'Poultry & Layer Management',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Precision FCR, Layer Output & Brooding Radar',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quick Stat Bar
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildHeroStatPill(
                                    icon: Icons.pets_rounded,
                                    label: 'Flock Size',
                                    value: '4,042 Birds',
                                    color: Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.calculate_rounded,
                                    label: 'Avg FCR',
                                    value: _calculatedFCR.toStringAsFixed(2),
                                    color: Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.egg_outlined,
                                    label: "Today's Lay",
                                    value:
                                        '${_eggLayingRate.toStringAsFixed(1)}%',
                                    color: Colors.cyanAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.monetization_on_rounded,
                                    label: 'Est. Net Batch',
                                    value:
                                        '₹ ${_totalBatchProfit.toStringAsFixed(0)}',
                                    color: Colors.lightGreenAccent,
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
                  Tab(icon: Icon(Icons.hub_rounded), text: 'Flock Batches'),
                  Tab(icon: Icon(Icons.calculate_rounded), text: 'FCR & Profitability'),
                  Tab(icon: Icon(Icons.egg_rounded), text: 'Egg Laying Tracker'),
                  Tab(icon: Icon(Icons.thermostat_rounded), text: 'Brooding & Climate'),
                  Tab(icon: Icon(Icons.medical_services_rounded), text: 'Avian Vet Hub'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBatchesTab(),
            _buildFcrCalculatorTab(),
            _buildEggTrackerTab(),
            _buildBroodingClimateTab(),
            _buildAvianVetTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _showNewBatchModal,
              backgroundColor: const Color(0xFFD84315),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'New Batch',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          } else if (_tabController.index == 2) {
            return FloatingActionButton.extended(
              onPressed: _saveEggRecord,
              backgroundColor: const Color(0xFFE65100),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                'Save Egg Log',
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
  // TAB 1: FLOCK BATCHES & LIFECYCLE REGISTRY
  // =========================================================================
  Widget _buildBatchesTab() {
    final filteredBatches = _batches.where((b) {
      final matchesSearch = b['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          b['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b['breed'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      if (_selectedBatchFilter == 'All') return matchesSearch;
      if (_selectedBatchFilter == 'Broiler') {
        return matchesSearch && b['type'] == 'Commercial Broiler';
      }
      if (_selectedBatchFilter == 'Layer') {
        return matchesSearch && b['type'] == 'Commercial Layer';
      }
      if (_selectedBatchFilter == 'Desi/Country') {
        return matchesSearch && b['type'].toString().contains('Country');
      }
      return matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Search & Filter
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
                    hintText: 'Search batch ID, breed or shed...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFFD84315)),
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
                      'Broiler',
                      'Layer',
                      'Desi/Country',
                    ].map((filter) {
                      final isSelected = _selectedBatchFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedBatchFilter = filter);
                          },
                          selectedColor: const Color(0xFFD84315),
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

        Text(
          'Active Poultry Batches (${filteredBatches.length})',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ...filteredBatches.map((b) => _buildBatchDetailCard(b)),
      ],
    );
  }

  Widget _buildBatchDetailCard(Map<String, dynamic> b) {
    final color = b['color'] as Color;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      ),
                      child: Icon(Icons.egg_rounded, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['name'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '${b['id']} • ${b['breed']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    'Day ${b['ageDays']}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Live Birds: ${b['currentCount']} / ${b['initialCount']}',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  'Mortality: ${b['mortalityRate']} (${b['mortalityCount']} lost)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Avg Weight: ${b['currentAvgWeight']}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD84315),
                  ),
                ),
                Text(
                  'FCR: ${b['fcr']}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vaccines_outlined,
                      size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Protocol: ${b['vaccine']}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade800),
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
  // TAB 2: PRECISION FCR & PROFITABILITY CALCULATOR
  // =========================================================================
  Widget _buildFcrCalculatorTab() {
    final isFcrOptimal = _calculatedFCR <= 1.62;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // FCR Hero Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFcrOptimal
                  ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
                  : [const Color(0xFFE65100), const Color(0xFFBF360C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isFcrOptimal ? Colors.green : Colors.deepOrange)
                    .withValues(alpha: 0.3),
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
                    'Feed Conversion Ratio (FCR) Engine',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
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
                      isFcrOptimal ? '⭐ Highly Efficient' : '⚠️ Feed Loss',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _calculatedFCR.toStringAsFixed(2),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'kg Feed required per 1 kg Live Body Weight',
                        style: TextStyle(
                            color: Colors.amber.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text('Net Profit / Bird',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 10)),
                        Text('₹ ${_profitPerBird.toStringAsFixed(1)}',
                            style: GoogleFonts.outfit(
                                color: Colors.greenAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interactive Parameters
        Text(
          'Batch Feed & Live Weight Metrics',
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
                // Total Feed Consumed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Feed Consumed',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('${_feedConsumedKg.toInt()} kg',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD84315))),
                  ],
                ),
                Slider(
                  value: _feedConsumedKg,
                  min: 100.0,
                  max: 10000.0,
                  divisions: 198,
                  activeColor: const Color(0xFFD84315),
                  onChanged: (v) => setState(() => _feedConsumedKg = v),
                ),
                const SizedBox(height: 8),

                // Total Live Weight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Live Weight Harvested',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('${_totalLiveWeightKg.toInt()} kg',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800)),
                  ],
                ),
                Slider(
                  value: _totalLiveWeightKg,
                  min: 100.0,
                  max: 6000.0,
                  divisions: 118,
                  activeColor: Colors.green.shade800,
                  onChanged: (v) => setState(() => _totalLiveWeightKg = v),
                ),
                const SizedBox(height: 8),

                // Live Bird Selling Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mandi Selling Price (₹/kg Live)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('₹ ${_liveBirdSellingRate.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.blue.shade800)),
                  ],
                ),
                Slider(
                  value: _liveBirdSellingRate,
                  min: 60.0,
                  max: 200.0,
                  divisions: 140,
                  activeColor: Colors.blue.shade800,
                  onChanged: (v) => setState(() => _liveBirdSellingRate = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Economic Feasibility Summary
        Text(
          'Batch Financial & Profitability Statement',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        _buildFinancialRow('Feed Cost / Bird',
            '₹ ${_feedCostPerBird.toStringAsFixed(1)} ($_feedCostPerKg ₹/kg feed)'),
        _buildFinancialRow('Chick & DOC Cost', '₹ ${_chickCostPerBird.toStringAsFixed(1)}'),
        _buildFinancialRow('Medicine & Vaccine Cost', '₹ ${_medicineCostPerBird.toStringAsFixed(1)}'),
        _buildFinancialRow('Total Production Cost / Bird',
            '₹ ${_totalCostPerBird.toStringAsFixed(1)}',
            isBold: true),
        _buildFinancialRow(
            'Gross Revenue / Bird', '₹ ${_revenuePerBird.toStringAsFixed(1)}',
            color: Colors.green.shade800, isBold: true),
        _buildFinancialRow('Net Profit across Flock ($_birdCount Birds)',
            '₹ ${_totalBatchProfit.toStringAsFixed(0)}',
            color: Colors.blue.shade900, isBold: true),
      ],
    );
  }

  Widget _buildFinancialRow(String title, String val,
      {bool isBold = false, Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
            Text(
              val,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color ?? Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: EGG LAYING TRACKER & TRAY ANALYTICS
  // =========================================================================
  Widget _buildEggTrackerTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Daily Egg Production Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE65100),
                Color(0xFFBF360C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Egg Production & Laying Curve",
                style: GoogleFonts.outfit(
                  color: Colors.amber.shade100,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_eggLayingRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$_dailyEggsCollected Eggs collected from $_activeLayersCount layers',
                        style: TextStyle(
                            color: Colors.amber.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_packedTraysCount Trays',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '₹ ${_dailyEggRevenue.toStringAsFixed(0)} / Day',
                        style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Collection Sliders
        Text(
          'Daily Egg Collection Entry',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Layer Bird Population',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('$_activeLayersCount Birds',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFE65100))),
                  ],
                ),
                Slider(
                  value: _activeLayersCount.toDouble(),
                  min: 100.0,
                  max: 5000.0,
                  divisions: 98,
                  activeColor: const Color(0xFFE65100),
                  onChanged: (v) =>
                      setState(() => _activeLayersCount = v.toInt()),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fresh Eggs Collected Today',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('$_dailyEggsCollected Eggs',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade900)),
                  ],
                ),
                Slider(
                  value: _dailyEggsCollected.toDouble(),
                  min: 0.0,
                  max: _activeLayersCount.toDouble(),
                  divisions: 100,
                  activeColor: Colors.amber.shade900,
                  onChanged: (v) =>
                      setState(() => _dailyEggsCollected = v.toInt()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 7-Day Egg History
        Text(
          '7-Day Egg Production Logs',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ..._eggHistory.map((h) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: const Icon(Icons.egg, color: Color(0xFFE65100)),
                ),
                title: Text('${h['day']} • ${h['eggs']} Eggs (${h['rate']}%)',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('Damaged: ${h['damaged']} • 30-egg trays packed',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Text('₹ ${h['rev']}',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade800)),
              ),
            )),
      ],
    );
  }

  // =========================================================================
  // TAB 4: BROODING, LIGHTING & CLIMATE MATRIX
  // =========================================================================
  Widget _buildBroodingClimateTab() {
    final broodingMatrix = [
      {
        'week': 'Week 1 (Day 1 - 7)',
        'targetTemp': '33°C - 35°C (92°F - 95°F)',
        'rh': '60% - 70%',
        'lighting': '23 Hours (30-40 Lux)',
        'airCfm': '0.10 CFM / bird',
        'keyAction': 'Provide electrolyte + Vitamin C first 6 hours. Pre-heat shed 24 hours in advance.',
      },
      {
        'week': 'Week 2 (Day 8 - 14)',
        'targetTemp': '30°C - 32°C (86°F - 90°F)',
        'rh': '55% - 65%',
        'lighting': '20 Hours (20 Lux)',
        'airCfm': '0.25 CFM / bird',
        'keyAction': 'Expand brooding circle; introduce starter crumbles on paper lining.',
      },
      {
        'week': 'Week 3 (Day 15 - 21)',
        'targetTemp': '27°C - 29°C (80°F - 84°F)',
        'rh': '50% - 60%',
        'lighting': '18 Hours (15 Lux)',
        'airCfm': '0.50 CFM / bird',
        'keyAction': 'Administer IBD Gumboro intermediate plus in drinking water with skimmed milk.',
      },
      {
        'week': 'Week 4 - 6 (Grower/Finisher)',
        'targetTemp': '21°C - 24°C (70°F - 75°F)',
        'rh': '50% - 60%',
        'lighting': '16 Hours (10 Lux)',
        'airCfm': '1.50 - 2.50 CFM / bird',
        'keyAction': 'Maintain cross ventilation; control litter moisture < 25% to eliminate ammonia.',
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Environmental Telemetry Warning Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.thermostat_auto_rounded,
                  color: Colors.orange, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shed Climate & Ammonia Watchdog',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: Colors.brown.shade900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chilling during Week 1 causes irreversible gut atrophy and ascites. Maintain strict brooding guidelines.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.brown.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Weekly Environmental & Lighting Protocols',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ...broodingMatrix.map((m) => Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m['week']!,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD84315),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            m['targetTemp']!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('💡 Light: ${m['lighting']}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800)),
                        Text('💨 Vent: ${m['airCfm']}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Action: ${m['keyAction']}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // =========================================================================
  // TAB 5: AVIAN VET HUB & DISEASE ENCYCLOPEDIA
  // =========================================================================
  Widget _buildAvianVetTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
            );
          },
          icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
          label: const Text('Consult Poultry AI Veterinarian'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD84315),
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Major Avian Diseases & First-Aid Protocols (${_poultryDiseases.length})',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ..._poultryDiseases.map((d) => _buildPoultryDiseaseCard(d)),
      ],
    );
  }

  Widget _buildPoultryDiseaseCard(Map<String, dynamic> d) {
    final symptoms = d['symptoms'] as List<String>;
    final firstAid = d['firstAid'] as List<String>;
    final badgeColor = d['badgeColor'] as Color;
    final diseasePhoto = d['diseasePhoto'] as String?;
    final medicinePhoto = d['medicinePhoto'] as String?;
    final medicineName = d['medicineName'] as String? ?? 'Prescribed Veterinary Remedy';
    final medicineDosage = d['medicineDosage'] as String? ?? 'Administer under veterinarian guidance.';
    final medType = d['medType'] as String? ?? 'Veterinary Formulation';
    final medicineWarning = d['medicineWarning'] as String? ?? 'Administer under registered veterinarian supervision.';
    final organicPhoto = d['organicPhoto'] as String?;
    final organicName = d['organicName'] as String? ?? 'Organic Herbal Solution';
    final organicIngredients = d['organicIngredients'] as String? ?? 'Natural herbal ingredients.';
    final organicDosage = d['organicDosage'] as String? ?? 'Mix in drinking water.';
    final organicBenefits = d['organicBenefits'] as String? ?? 'Zero chemical residue, natural immunity.';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withValues(alpha: 0.14),
          radius: 22,
          child: Icon(Icons.medical_services_rounded, color: badgeColor, size: 22),
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
              'Pathogen: ${d['agent']}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
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
          // 3-PHOTO VISUAL IDENTIFICATION: Disease Signs, Vet Medicine, Organic Remedy
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
                  child: _buildVisualPhotoTile(
                    title: 'Disease Signs',
                    tag: '🔍 Clinical',
                    tagColor: Colors.red.shade700,
                    imageUrl: diseasePhoto,
                    icon: Icons.biotech_rounded,
                    onTap: () => _showPhotoDetailDialog(
                      context,
                      title: '${d['name']} - Symptoms',
                      imageUrl: diseasePhoto ?? '',
                      tag: 'Avian Pathogen Signs',
                      description: 'Observed clinical signs in flock: ${symptoms.join(". ")}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Allopathic / Vet Medicine Photo Card
                SizedBox(
                  width: 145,
                  child: _buildVisualPhotoTile(
                    title: 'Vet Medicine / Pack',
                    tag: '💊 Chemical/Drug',
                    tagColor: Colors.blue.shade700,
                    imageUrl: medicinePhoto,
                    icon: Icons.medication_rounded,
                    onTap: () => _showPhotoDetailDialog(
                      context,
                      title: medicineName,
                      imageUrl: medicinePhoto ?? '',
                      tag: medType,
                      description: 'Prescribed Regimen: $medicineDosage\n\n⚠️ Caution: $medicineWarning',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 3. Organic & Bio-Fertilizer / Herbal Photo Card
                SizedBox(
                  width: 145,
                  child: _buildVisualPhotoTile(
                    title: 'Organic / Bio Remedy',
                    tag: '🌿 Natural / 0-Residue',
                    tagColor: Colors.green.shade800,
                    imageUrl: organicPhoto,
                    icon: Icons.eco_rounded,
                    onTap: () => _showPhotoDetailDialog(
                      context,
                      title: organicName,
                      imageUrl: organicPhoto ?? '',
                      tag: 'Organic Ethno-Veterinary Remedy',
                      description: 'Formula: $organicIngredients\n\nPreparation: $organicDosage\n\nBenefit: $organicBenefits',
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
                        '🌿 100% Organic',
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
                  '🥣 Preparation & Dosage: $organicDosage',
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

          // Key Symptoms
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
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade800)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),

          // First Aid Action
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
                      child: Text(f,
                          style: TextStyle(
                              fontSize: 12, color: Colors.green.shade900)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHOTO TILE HELPER & ZOOM MODAL DIALOG
  // ---------------------------------------------------------------------------
  Widget _buildVisualPhotoTile({
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
                errorBuilder: (_, __, ___) => _buildPhotoFallback(icon, title),
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
              _buildPhotoFallback(icon, title),
            // Gradient scrim
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
            // Top Tag
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
            // Zoom indicator
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
            ),
            // Bottom Title
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

  Widget _buildPhotoFallback(IconData icon, String title) {
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

  void _showPhotoDetailDialog(
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
                      color: const Color(0xFFD84315),
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
                      backgroundColor: const Color(0xFFD84315),
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
  // ACTIONS & MODALS
  // =========================================================================
  void _saveEggRecord() {
    setState(() {
      _eggHistory.insert(0, {
        'day': 'Today (Saved)',
        'eggs': _dailyEggsCollected,
        'damaged': _damagedEggs,
        'rate': _eggLayingRate,
        'rev': _dailyEggRevenue,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Daily egg collection record saved!'),
        backgroundColor: Color(0xFFE65100),
      ),
    );
  }

  void _showNewBatchModal() {
    final idCtrl = TextEditingController(
        text: 'BATCH-B24-${math.Random().nextInt(90) + 10}');
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register New Poultry Batch',
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(labelText: 'Batch Code'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Shed / House Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Initial Bird Count'),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _batches.add({
                      'id': idCtrl.text,
                      'name': nameCtrl.text,
                      'type': 'Commercial Broiler',
                      'breed': 'Cobb 500',
                      'initialCount': int.tryParse(countCtrl.text) ?? 1000,
                      'currentCount': int.tryParse(countCtrl.text) ?? 1000,
                      'mortalityCount': 0,
                      'mortalityRate': '0.0%',
                      'ageDays': 1,
                      'currentAvgWeight': '0.04 kg',
                      'targetWeight': '2.10 kg',
                      'fcr': 1.0,
                      'stage': 'Brooding Week 1',
                      'vaccine': 'Day 1 Marek Done',
                      'color': const Color(0xFFD84315),
                      'status': 'Brooding Active',
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84315),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Add Batch to Farm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Poultry Batch FCR & Mortality Report exported!'),
        backgroundColor: Color(0xFFD84315),
      ),
    );
  }
}
