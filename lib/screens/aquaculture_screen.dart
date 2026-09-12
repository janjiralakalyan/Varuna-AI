import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_screen.dart';

class AquacultureScreen extends StatefulWidget {
  const AquacultureScreen({super.key});

  @override
  State<AquacultureScreen> createState() => _AquacultureScreenState();
}

class _AquacultureScreenState extends State<AquacultureScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _waveController;
  late AnimationController _bubbleController;

  // ----------------------------------------------------
  // WATER QUALITY TELEMETRY STATE
  // ----------------------------------------------------
  double _dissolvedOxygen = 5.8; // mg/L (Safe: 5.0 - 8.0)
  double _waterPh = 7.8; // (Safe: 7.5 - 8.5)
  double _ammoniaTan = 0.04; // ppm (Safe: < 0.10)
  final double _nitriteNo2 = 0.02; // ppm (Safe: < 0.10)
  double _salinity = 16.0; // ppt (Shrimp: 10 - 25)
  final double _alkalinity = 140.0; // ppm CaCO3 (Safe: 120 - 180)

  // ----------------------------------------------------
  // BIOMASS & FEED STATE
  // ----------------------------------------------------
  String _selectedSpecies = 'Vannamei Shrimp (L. vannamei)';
  final double _seedStockedCount = 90000.0; // Post-Larvae PL
  double _avgBodyWeightGrams = 18.5; // grams
  double _survivalRatePercent = 82.0; // %
  final int _dayOfCulture = 56; // DOC

  // Check-Tray State
  final double _trayAdjustmentFactor = 1.0;

  // ----------------------------------------------------
  // POND INVENTORY LIST
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _ponds = [
    {
      'name': 'Pond #1 (East Bay)',
      'area': '1.25 Acres',
      'type': 'Earthen Pond (HDPE Lined)',
      'species': 'Vannamei Shrimp',
      'doc': 56,
      'stockingDensity': '60 PL / m²',
      'currentAbw': '18.5 g',
      'totalBiomass': '1,365 kg',
      'aeratorCount': '4 Paddlewheels (8 HP)',
      'doLevel': '5.8 mg/L',
      'phLevel': '7.8',
      'status': 'Optimal (Feeding Active)',
      'color': const Color(0xFF00838F),
      'harvestDate': '28 Sep 2026',
    },
    {
      'name': 'Pond #2 (North Lake)',
      'area': '2.50 Acres',
      'type': 'Freshwater Earthen Pond',
      'species': 'Indian Major Carps (Rohu/Catla)',
      'doc': 140,
      'stockingDensity': '3,000 Fingerlings / Acre',
      'currentAbw': '680 g',
      'totalBiomass': '4,200 kg',
      'aeratorCount': '2 Spiral Aerators',
      'doLevel': '5.2 mg/L',
      'phLevel': '7.6',
      'status': 'Plankton Bloom Healthy',
      'color': const Color(0xFF006064),
      'harvestDate': '15 Nov 2026',
    },
    {
      'name': 'Biofloc Tank A-1',
      'area': '15,000 Liters (Circular)',
      'type': 'Biofloc Intensive Tank',
      'species': 'GIFT Tilapia (Genetically Improved)',
      'doc': 72,
      'stockingDensity': '120 fish / m³',
      'currentAbw': '280 g',
      'totalBiomass': '490 kg',
      'aeratorCount': 'Blower Air Ring 24/7',
      'doLevel': '6.4 mg/L',
      'phLevel': '7.4',
      'status': 'Floc Volume: 22 ml/L',
      'color': const Color(0xFF004D40),
      'harvestDate': '10 Oct 2026',
    },
    {
      'name': 'Nursery Pond #1',
      'area': '0.50 Acre',
      'type': 'Nursery Phase',
      'species': 'Scampi (Macrobrachium rosenbergii)',
      'doc': 22,
      'stockingDensity': '120 PL / m²',
      'currentAbw': '4.2 g',
      'totalBiomass': '180 kg',
      'aeratorCount': '2 Paddlewheels',
      'doLevel': '6.1 mg/L',
      'phLevel': '8.0',
      'status': 'Ready for Primary Transfer',
      'color': const Color(0xFF0097A7),
      'harvestDate': '20 Dec 2026',
    },
  ];

  // ----------------------------------------------------
  // AQUA DISEASE ENCYCLOPEDIA
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _aquaDiseases = [
    {
      'name': 'White Spot Syndrome Virus (WSSV)',
      'target': 'Penaeid Shrimp (Vannamei / Monodon)',
      'severity': 'Critical (100% Mortality in 3-5 Days)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Virkon Aquatic Sanitizer + Aqua-C 50% (Coated Vitamin C)',
      'medicineDosage':
          '1.5 ppm pond water disinfection; 5g Coated Vitamin C / kg feed top-dressed with squid oil binder.',
      'medType': 'Aquatic Biosecurity Sanitizer & Immune Stimulant',
      'medicineWarning': 'CRITICAL BIOSECURITY: Never discharge infected pond water into public creeks without 10 ppm chlorine bleaching.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Garlic & Curcumin Bio-Extract with Beta-Glucan Feed Binder',
      'organicIngredients': 'Fresh Garlic Juice (Alliin 20ml/kg feed) + Pure Curcumin Turmeric extract (10g/kg) + Phyllanthus niruri (Bhuiamla 10g/kg).',
      'organicDosage': 'Top-dress on pellet feed with egg white/squid oil binder twice daily for 7 days. Apply 20kg Jaggery / Acre to maintain pond C:N ratio.',
      'organicBenefits': 'Suppresses viral replication, boosts hemocyte phagocytosis, and eliminates chemical toxicity in shrimp hepatopancreas.',
      'symptoms': [
        'White calcified spots (0.5 to 2 mm) inside the carapace and shell',
        'Reddish-pink body discoloration with loose cuticle',
        'Lethargic swimming near pond surface and edges during morning',
        'Sudden complete cessation of feed in check-trays followed by mortality'
      ],
      'firstAid': [
        'Immediate quarantine: stop all pond water exchange and inlet pumping.',
        'Run all available aerators 24/7 to maintain DO > 6.0 mg/L.',
        'Apply high-dose Vitamin C (5 g/kg feed) and beta-glucan immunostimulants.',
        'If crop is near marketable size (> 15 g), undertake emergency harvest.'
      ],
      'prevention': 'Screened SPF (Specific Pathogen Free) seed; crab fencing & bird netting.',
      'badgeColor': Colors.red.shade800,
    },
    {
      'name': 'Early Mortality Syndrome (EMS / AHPND)',
      'target': 'Shrimp Post-Larvae (DOC 10 - 35)',
      'severity': 'High (Acute Hepatopancreatic Necrosis)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Pro-Aqua Biocare (Bacillus subtilis Drench) + Yucca Toxin Extractor',
      'medicineDosage':
          '500g Probiotic / Acre fermented with 5kg jaggery for 24 hours; broadcast in morning with aerators running.',
      'medType': 'Multi-Strain Soil & Water Probiotic Ferment',
      'medicineWarning': 'Reduce feeding by 50% immediately during outbreak to prevent toxic organic loading on pond bottom.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Fermented Jaggery-Rice Bran Heterotrophic Probiotic (FRB)',
      'organicIngredients': 'De-oiled Rice Bran (DOB 25kg) + Organic Jaggery (10kg) + Yeast (500g) + Multi-strain Bacillus probiotic (200g).',
      'organicDosage': 'Aerate and ferment in 200L water drum for 36 hours. Broadcast 50L fermented slurry per Acre every 3 days at 10 AM.',
      'organicBenefits': 'Outcompetes pathogenic green colony Vibrio parahaemolyticus naturally, stabilizes biofloc, and digests toxic pond sludge.',
      'symptoms': [
        'Pale, shrunken, and atrophied hepatopancreas with black streaks',
        'Empty gut and stomach despite feed in trays',
        'Soft shells and slow growth leading to sudden mass mortality',
        'Turbid, toxic pond bottom with high Vibrio parahaemolyticus count'
      ],
      'firstAid': [
        'Apply probiotic Bacillus subtilis + Lactobacillus drench to suppress Vibrio.',
        'Dose organic acids (Citric / Formic acid) in feed to lower gut pH.',
        'Reduce feed by 40-50% to prevent pond bottom organic loading.',
        'Apply Yucca extract + Zeolite to adsorb toxins at pond bottom.'
      ],
      'prevention': 'Nursery central drainage; strict biosecurity and water maturation.',
      'badgeColor': Colors.deepOrange.shade800,
    },
    {
      'name': 'Bacterial Gill Rot / Columnaris',
      'target': 'Freshwater Carps (Rohu/Catla) & Tilapia',
      'severity': 'High (Suffocation Hazard)',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'BKC 50% (Benzalkonium Chloride) + Terramycin Aqua 50%',
      'medicineDosage':
          '1 Liter BKC 50% / Acre-meter water column + 50 mg Terramycin / kg biomass in floating pellet feed for 7 days.',
      'medType': 'Water Clarifier Sanitizer & Aqua Antibiotic Feed Premix',
      'medicineWarning': 'Dilute BKC in 50 Liters of pond water before broadcasting. Apply only on sunny mornings with aerators active.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Neem Cake & Raw Rock Salt (NaCl) Gill Sanitizing Flush',
      'organicIngredients': 'De-oiled Neem Seed Cake (100 kg/Acre) + Unrefined Rock Salt (150 kg/Acre) + Turmeric powder (5 kg/Acre).',
      'organicDosage': 'Soak neem cake overnight, broadcast slurry over fish shoaling areas; dissolve rock salt and turmeric across surface water column.',
      'organicBenefits': 'Natural antibacterial & anti-parasitic agent, restores gill lamellar tissue, prevents fungal saprolegniasis.',
      'symptoms': [
        'Dark brown, eroded, and necrotic gill filaments covered with mucus',
        'Fish gasping at water surface and crowding near inlet/aerators',
        'White patches around head and fins with frayed skin lesions'
      ],
      'firstAid': [
        'Bath treatment: Dip affected fish in 2 ppm Potassium Permanganate (KMNO4).',
        'Apply Common Salt (NaCl) at 0.5% - 1.0% across the water column.',
        'Feed medicated feed containing Oxytetracycline (50 mg/kg biomass) for 7 days.',
        'Flush 20% surface water and boost aerator runtime.'
      ],
      'prevention': 'Avoid overcrowding; maintain ammonia < 0.05 ppm and DO > 5.0 mg/L.',
      'badgeColor': Colors.cyan.shade900,
    },
    {
      'name': 'Toxic Ammonia (NH3) & Pond Bottom Acidification',
      'target': 'All Aquatic Species & Biofloc',
      'severity': 'Emergency Chemical Toxicity',
      'diseasePhoto':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600&auto=format&fit=crop&q=80',
      'medicinePhoto':
          'https://images.unsplash.com/photo-1607613009820-a29f7bb81c04?w=600&auto=format&fit=crop&q=80',
      'medicineName': 'Pond Zeolite Activated Granules + Agri-Dolomite Lime (CaMg(CO3)2)',
      'medicineDosage':
          '50-100 kg / Acre Zeolite broadcast over sludge zones + 100 kg Dolomite to buffer alkalinity > 120 ppm.',
      'medType': 'Inorganic Toxin Binder & Mineral Buffer Fertilizer',
      'medicineWarning': 'Test Total Ammonia Nitrogen (TAN) and pH. If pH > 8.5, free toxic unionized NH3 increases exponentially.',
      'organicPhoto':
          'https://images.unsplash.com/photo-1509358271058-acd22cc93898?w=600&auto=format&fit=crop&q=80',
      'organicName': 'Agricultural Quicklime (CaO) & Carbon Molasses Balance',
      'organicIngredients': 'High-grade Burnt Quicklime / CaO (50 kg/Acre) + Pure Sugarcane Molasses (25 kg/Acre) + Yucca Schidigera extract.',
      'organicDosage': 'Broadcast quicklime at dusk to sanitize sludge; apply molasses diluted 1:5 in water at 9 AM under sunshine to convert ammonia into microbial protein.',
      'organicBenefits': 'Corrects acidic pond bottom (pH 7.5 - 8.2), eliminates toxic H2S gas odor, and provides mineral hardness.',
      'symptoms': [
        'Shrimp jumping or crawling to pond bunds; fish piping at surface',
        'Brown blood disease in fish due to methemoglobin formation',
        'Heavy microalgal bloom crash with foul hydrogen sulfide smell'
      ],
      'firstAid': [
        'Apply Zeolite (50-100 kg/Acre) immediately to bind free ammonia.',
        'Apply Jaggery/Molasses (20-30 kg/Acre) to boost heterotrophic bacteria (C:N 15:1).',
        'Stop feeding completely for 24-48 hours until TAN drops below 0.1 ppm.',
        'Run aerators non-stop to strip volatile ammonia gas.'
      ],
      'prevention': 'Never overfeed; monitor check-trays accurately 1 hour after feeding.',
      'badgeColor': Colors.amber.shade900,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // COMPUTED CALCULATIONS
  // ----------------------------------------------------
  double get _estimatedLiveStock =>
      _seedStockedCount * (_survivalRatePercent / 100.0);

  double get _totalPondBiomassKg =>
      (_estimatedLiveStock * _avgBodyWeightGrams) / 1000.0;

  double get _baseFeedPercentOfBiomass {
    if (_avgBodyWeightGrams < 3.0) return 7.5;
    if (_avgBodyWeightGrams < 8.0) return 5.5;
    if (_avgBodyWeightGrams < 15.0) return 3.8;
    if (_avgBodyWeightGrams < 25.0) return 2.8;
    return 2.2;
  }

  double get _dailyFeedRequirementKg =>
      (_totalPondBiomassKg * (_baseFeedPercentOfBiomass / 100.0)) *
      _trayAdjustmentFactor;

  double get _perMealFeedKg => _dailyFeedRequirementKg / 4.0;

  bool get _isWaterQualitySafe =>
      _dissolvedOxygen >= 4.8 &&
      _waterPh >= 7.4 &&
      _waterPh <= 8.5 &&
      _ammoniaTan < 0.10 &&
      _nitriteNo2 < 0.10;

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
              backgroundColor: const Color(0xFF00838F),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.waves_rounded, color: Colors.white),
                  tooltip: 'Aerator Automation',
                  onPressed: _showAeratorAutomationToast,
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  tooltip: 'Export Pond Water Log',
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
                            Color(0xFF00838F),
                            Color(0xFF006064),
                            Color(0xFF004D40),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
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
                                      const Icon(Icons.water_drop,
                                          color: Colors.cyanAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CIFA / MPEDA Smart Aqua Standards',
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
                                  _isWaterQualitySafe
                                      ? '🟢 Ponds Normal'
                                      : '⚠️ Water Alert',
                                  style: GoogleFonts.outfit(
                                    color: _isWaterQualitySafe
                                        ? Colors.greenAccent
                                        : Colors.amberAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Aquaculture & Pond Telemetry',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Biomass, Water Chemistry & Feed Radar',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildHeroStatPill(
                                    icon: Icons.pool_rounded,
                                    label: 'Total Ponds',
                                    value: '${_ponds.length} Water Bodies',
                                    color: Colors.cyanAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.water_rounded,
                                    label: 'DO Level',
                                    value: '$_dissolvedOxygen mg/L',
                                    color: Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.monitor_weight_outlined,
                                    label: 'Pond #1 Biomass',
                                    value:
                                        '${_totalPondBiomassKg.toStringAsFixed(0)} kg',
                                    color: Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.restaurant_rounded,
                                    label: 'Daily Feed',
                                    value:
                                        '${_dailyFeedRequirementKg.toStringAsFixed(1)} kg',
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
                indicatorColor: Colors.cyanAccent,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.science_rounded), text: 'Water Chemistry'),
                  Tab(icon: Icon(Icons.calculate_rounded), text: 'Biomass & Feed'),
                  Tab(icon: Icon(Icons.pool_rounded), text: 'Pond Inventory'),
                  Tab(icon: Icon(Icons.medical_services_rounded), text: 'Aqua Pathogens'),
                  Tab(icon: Icon(Icons.history_rounded), text: 'Water Log History'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWaterChemistryTab(),
            _buildBiomassFeedTab(),
            _buildPondInventoryTab(),
            _buildAquaPathogensTab(),
            _buildWaterLogHistoryTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _saveWaterLog,
              backgroundColor: const Color(0xFF00838F),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                'Save Water Test',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          } else if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _logFeedingExecution,
              backgroundColor: const Color(0xFF006064),
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: Text(
                'Commit Feed Entry',
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
  // TAB 1: WATER QUALITY TELEMETRY & CHEMISTRY LAB
  // =========================================================================
  Widget _buildWaterChemistryTab() {
    final isDoOptimal = _dissolvedOxygen >= 5.0;
    final isPhOptimal = _waterPh >= 7.5 && _waterPh <= 8.5;
    final isAmmoniaOptimal = _ammoniaTan <= 0.08;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Water Health Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: (isDoOptimal && isPhOptimal && isAmmoniaOptimal)
                  ? [const Color(0xFF00838F), const Color(0xFF004D40)]
                  : [const Color(0xFFC62828), const Color(0xFF8E0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00838F).withValues(alpha: 0.3),
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
                  Text(
                    'Pond #1 Water Chemistry Status',
                    style: GoogleFonts.outfit(
                      color: Colors.cyan.shade100,
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
                      '4 Aerators Running',
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
              Text(
                (isDoOptimal && isPhOptimal && isAmmoniaOptimal)
                    ? '🟢 Optimal Aquatic Environment'
                    : '⚠️ Water Quality Hazard Triggered',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Alkalinity: ${_alkalinity.toInt()} ppm CaCO3 • Salinity: ${_salinity.toInt()} ppt',
                style: TextStyle(color: Colors.cyan.shade100, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interactive Sliders for 6 Water Parameters
        Text(
          'Real-Time Water Lab Sliders',
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
                // DO Slider
                _buildParameterSlider(
                  label: 'Dissolved Oxygen (DO)',
                  value: '$_dissolvedOxygen mg/L',
                  val: _dissolvedOxygen,
                  min: 1.0,
                  max: 12.0,
                  safeMin: 5.0,
                  safeMax: 8.0,
                  color: Colors.blue.shade700,
                  onChanged: (v) => setState(() => _dissolvedOxygen = v),
                ),
                const Divider(height: 20),

                // pH Slider
                _buildParameterSlider(
                  label: 'Water pH Level',
                  value: '$_waterPh',
                  val: _waterPh,
                  min: 6.0,
                  max: 10.0,
                  safeMin: 7.5,
                  safeMax: 8.5,
                  color: Colors.teal.shade700,
                  onChanged: (v) => setState(() => _waterPh = v),
                ),
                const Divider(height: 20),

                // Ammonia TAN
                _buildParameterSlider(
                  label: 'Total Ammonia Nitrogen (TAN)',
                  value: '$_ammoniaTan ppm',
                  val: _ammoniaTan,
                  min: 0.0,
                  max: 0.50,
                  safeMin: 0.0,
                  safeMax: 0.08,
                  color: Colors.deepOrange.shade700,
                  onChanged: (v) => setState(() => _ammoniaTan = v),
                ),
                const Divider(height: 20),

                // Salinity
                _buildParameterSlider(
                  label: 'Salinity',
                  value: '${_salinity.toInt()} ppt',
                  val: _salinity,
                  min: 0.0,
                  max: 40.0,
                  safeMin: 10.0,
                  safeMax: 25.0,
                  color: Colors.cyan.shade700,
                  onChanged: (v) => setState(() => _salinity = v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSlider({
    required String label,
    required String value,
    required double val,
    required double min,
    required double max,
    required double safeMin,
    required double safeMax,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final isSafe = val >= safeMin && val <= safeMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSafe ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: val,
          min: min,
          max: max,
          divisions: 100,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: PRECISION BIOMASS & CHECK-TRAY FEEDING CHART
  // =========================================================================
  Widget _buildBiomassFeedTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Biomass & Feed Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00838F),
                Color(0xFF004D40),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00838F).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biomass & Feeding Chart Calculator',
                style: GoogleFonts.outfit(
                  color: Colors.cyan.shade100,
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
                        '${_totalPondBiomassKg.toStringAsFixed(0)} kg',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Total Estimated Biomass (DOC $_dayOfCulture)',
                        style: TextStyle(
                            color: Colors.cyan.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_dailyFeedRequirementKg.toStringAsFixed(1)} kg',
                        style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Daily Feed Requirement',
                        style: TextStyle(
                            color: Colors.cyan.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Parameter Adjusters
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Species Cultivated'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Vannamei Shrimp (L. vannamei)',
                      child: Text('Vannamei Shrimp (L. vannamei)'),
                    ),
                    DropdownMenuItem(
                      value: 'Black Tiger Shrimp (P. monodon)',
                      child: Text('Black Tiger Shrimp (P. monodon)'),
                    ),
                    DropdownMenuItem(
                      value: 'Indian Major Carps (Rohu/Catla)',
                      child: Text('Indian Major Carps (Rohu/Catla)'),
                    ),
                    DropdownMenuItem(
                      value: 'GIFT Tilapia (O. niloticus)',
                      child: Text('GIFT Tilapia (O. niloticus)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedSpecies = v!),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Average Body Weight (ABW)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('${_avgBodyWeightGrams.toStringAsFixed(1)} grams',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF00838F))),
                  ],
                ),
                Slider(
                  value: _avgBodyWeightGrams,
                  min: 0.5,
                  max: 100.0,
                  divisions: 199,
                  activeColor: const Color(0xFF00838F),
                  onChanged: (v) => setState(() => _avgBodyWeightGrams = v),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Survival Rate',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('${_survivalRatePercent.toInt()}%',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800)),
                  ],
                ),
                Slider(
                  value: _survivalRatePercent,
                  min: 40.0,
                  max: 100.0,
                  divisions: 60,
                  activeColor: Colors.green.shade800,
                  onChanged: (v) => setState(() => _survivalRatePercent = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4x Daily Meal Breakdown Cards
        Text(
          '4-Shift Daily Feeding Schedule',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        _buildMealCard('Shift 1 (06:00 AM)', '${_perMealFeedKg.toStringAsFixed(1)} kg',
            '25% Daily Ration • 2 Check-trays sampled', Icons.wb_twilight_rounded),
        _buildMealCard('Shift 2 (11:00 AM)', '${_perMealFeedKg.toStringAsFixed(1)} kg',
            '25% Daily Ration • Check-trays inspected at 12:00 PM', Icons.wb_sunny_rounded),
        _buildMealCard('Shift 3 (04:30 PM)', '${_perMealFeedKg.toStringAsFixed(1)} kg',
            '25% Daily Ration • Check-trays inspected at 05:30 PM', Icons.wb_sunny_outlined),
        _buildMealCard('Shift 4 (09:00 PM)', '${_perMealFeedKg.toStringAsFixed(1)} kg',
            '25% Daily Ration • Aerators active on all lines', Icons.nightlight_rounded),
      ],
    );
  }

  Widget _buildMealCard(String title, String qty, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00838F).withValues(alpha: 0.12),
          child: Icon(icon, color: const Color(0xFF00838F)),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(desc,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Text(
          qty,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: const Color(0xFF00838F)),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: POND INVENTORY
  // =========================================================================
  Widget _buildPondInventoryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text(
          'Registered Farm Ponds (${_ponds.length})',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ..._ponds.map((p) => Card(
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
                          p['name'] as String,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.cyan.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'DOC ${p['doc']}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.cyan.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Text('${p['species']} • ${p['area']}'),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Biomass: ${p['totalBiomass']}',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                color: Colors.teal.shade800)),
                        Text('DO: ${p['doLevel']} | pH: ${p['phLevel']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // =========================================================================
  // TAB 4: AQUATIC PATHOGENS & REMEDIATION
  // =========================================================================
  Widget _buildAquaPathogensTab() {
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
          label: const Text('Consult Aquaculture AI Specialist'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00838F),
            minimumSize: const Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Aquatic Pathogens & Remediation (${_aquaDiseases.length})',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ..._aquaDiseases.map((d) => _buildAquaDiseaseCard(d)),
      ],
    );
  }

  Widget _buildAquaDiseaseCard(Map<String, dynamic> d) {
    final symptoms = d['symptoms'] as List<String>;
    final firstAid = d['firstAid'] as List<String>;
    final badgeColor = d['badgeColor'] as Color;
    final diseasePhoto = d['diseasePhoto'] as String?;
    final medicinePhoto = d['medicinePhoto'] as String?;
    final medicineName = d['medicineName'] as String? ?? 'Prescribed Aqua Formulation';
    final medicineDosage = d['medicineDosage'] as String? ?? 'Apply according to water volume.';
    final medType = d['medType'] as String? ?? 'Aquatic Treatment Formulation';
    final medicineWarning = d['medicineWarning'] as String? ?? 'Apply strictly according to water volume and DO levels.';
    final organicPhoto = d['organicPhoto'] as String?;
    final organicName = d['organicName'] as String? ?? 'Biological Probiotic Remediation';
    final organicIngredients = d['organicIngredients'] as String? ?? 'Natural biological ingredients.';
    final organicDosage = d['organicDosage'] as String? ?? 'Broadcast across water column.';
    final organicBenefits = d['organicBenefits'] as String? ?? 'Improves water quality, 0% antibiotic residues.';

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
          child: Icon(Icons.water, color: badgeColor, size: 22),
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
              'Target: ${d['target']}',
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
          // 3-PHOTO VISUAL IDENTIFICATION: Pathogen Signs, Aqua Chemical, Bio-Probiotic
          // -----------------------------------------------------------------
          Text(
            '📸 Visual Identification & Product Packaging (Tap to Enlarge):',
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
                  child: _buildAquaPhotoTile(
                    title: 'Pathogen Signs',
                    tag: '🔍 Signs',
                    tagColor: Colors.red.shade700,
                    imageUrl: diseasePhoto,
                    icon: Icons.set_meal_rounded,
                    onTap: () => _showAquaPhotoDetailDialog(
                      context,
                      title: '${d['name']} - Symptoms',
                      imageUrl: diseasePhoto ?? '',
                      tag: 'Aquatic Pathogen Signs',
                      description: 'Observed signs in biomass: ${symptoms.join(". ")}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Chemical / Medicine Photo Card
                SizedBox(
                  width: 145,
                  child: _buildAquaPhotoTile(
                    title: 'Aqua Chemical / Pack',
                    tag: '💊 Chemical/Drug',
                    tagColor: const Color(0xFF00838F),
                    imageUrl: medicinePhoto,
                    icon: Icons.science_rounded,
                    onTap: () => _showAquaPhotoDetailDialog(
                      context,
                      title: medicineName,
                      imageUrl: medicinePhoto ?? '',
                      tag: medType,
                      description: 'Prescribed Dosage: $medicineDosage\n\n⚠️ Caution: $medicineWarning',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 3. Organic & Bio-Fertilizer / Probiotic Photo Card
                SizedBox(
                  width: 145,
                  child: _buildAquaPhotoTile(
                    title: 'Organic / Bio Remedy',
                    tag: '🌿 Bio-Flourish',
                    tagColor: Colors.teal.shade800,
                    imageUrl: organicPhoto,
                    icon: Icons.eco_rounded,
                    onTap: () => _showAquaPhotoDetailDialog(
                      context,
                      title: organicName,
                      imageUrl: organicPhoto ?? '',
                      tag: 'Organic Aquaculture Remediation',
                      description: 'Ingredients: $organicIngredients\n\nApplication: $organicDosage\n\nBenefits: $organicBenefits',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // -----------------------------------------------------------------
          // OPTION A: ALLOPATHIC / CHEMICAL AQUA TREATMENT
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF00838F), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        medicineName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: const Color(0xFF006064),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        medType,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006064),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '🧪 Chemical Protocol: $medicineDosage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyan.shade900,
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
          // OPTION B: ORGANIC & BIOLOGICAL POND REMEDIATION
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: Colors.teal, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        organicName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🌿 Bio-Flourish',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '🌱 Organic Components: $organicIngredients',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '🥣 Preparation & Application: $organicDosage',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '✨ Pond Benefit: $organicBenefits',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade800,
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
          const SizedBox(height: 4),
          ...symptoms.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.healing_rounded, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  'Remediation Action & Protocol:',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: Colors.teal.shade900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...firstAid.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(f,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal.shade900))),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: Color(0xFF00838F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prevention: ${d['prevention']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900,
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

  Widget _buildAquaPhotoTile({
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
                errorBuilder: (_, __, ___) => _buildAquaPhotoFallback(icon, title),
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
              _buildAquaPhotoFallback(icon, title),
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

  Widget _buildAquaPhotoFallback(IconData icon, String title) {
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

  void _showAquaPhotoDetailDialog(
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
                          child: Icon(Icons.water_damage_rounded,
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
                      color: const Color(0xFF00838F),
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
                      backgroundColor: const Color(0xFF00838F),
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
  // TAB 5: WATER LOG HISTORY
  // =========================================================================
  Widget _buildWaterLogHistoryTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text(
          'Recent Telemetry & Testing History',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ...[
          {'date': 'Today 06:00 AM', 'do': '5.8 mg/L', 'ph': '7.8', 'temp': '28.5°C'},
          {'date': 'Yesterday 06:00 PM', 'do': '6.4 mg/L', 'ph': '8.1', 'temp': '29.2°C'},
          {'date': 'Yesterday 06:00 AM', 'do': '5.4 mg/L', 'ph': '7.7', 'temp': '28.0°C'},
          {'date': '12 Aug 06:00 PM', 'do': '6.1 mg/L', 'ph': '8.0', 'temp': '29.0°C'},
        ].map((h) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.cyan.shade50,
                  child: const Icon(Icons.water, color: Color(0xFF00838F)),
                ),
                title: Text('${h['date']} (Pond #1)',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('DO: ${h['do']} • pH: ${h['ph']} • Temp: ${h['temp']}'),
                trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
              ),
            )),
      ],
    );
  }

  // =========================================================================
  // ACTIONS & TOASTS
  // =========================================================================
  void _saveWaterLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Water quality log (DO 5.8 mg/L, pH 7.8) committed to cloud!'),
        backgroundColor: Color(0xFF00838F),
      ),
    );
  }

  void _logFeedingExecution() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Shift feeding log committed to cloud inventory!'),
        backgroundColor: Color(0xFF006064),
      ),
    );
  }

  void _showAeratorAutomationToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Auto-aerator relay active: paddlewheels running on Schedule 1!'),
        backgroundColor: Color(0xFF00838F),
      ),
    );
  }

  void _showExportToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Aquaculture Pond Water Audit & MPEDA log exported!'),
        backgroundColor: Color(0xFF006064),
      ),
    );
  }
}
