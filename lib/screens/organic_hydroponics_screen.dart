import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrganicHydroponicsScreen extends StatefulWidget {
  const OrganicHydroponicsScreen({super.key});

  @override
  State<OrganicHydroponicsScreen> createState() =>
      _OrganicHydroponicsScreenState();
}

class _OrganicHydroponicsScreenState extends State<OrganicHydroponicsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ----------------------------------------------------
  // ORGANIC CONCOCTION STATE
  // ----------------------------------------------------
  String _selectedConcoction = 'Jeevamrutha (Bio-Fertilizer & Soil Microbes)';
  double _acreageToTreat = 2.5; // Acres

  // ----------------------------------------------------
  // HYDROPONICS & CEA LAB STATE
  // ----------------------------------------------------
  String _selectedHydroCrop = 'Leafy Greens (Lettuce, Spinach, Kale)';
  double _currentEc = 1.4; // mS/cm (Ideal: 1.2 - 1.8)
  double _currentPh = 6.2; // (Ideal: 5.8 - 6.5)

  // ----------------------------------------------------
  // CONCOCTIONS DATABASE
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _concoctionsDatabase = [
    {
      'id': 'jeevamrutha',
      'name': 'Jeevamrutha (Bio-Fertilizer & Soil Microbes)',
      'purpose': 'Multiplies native soil beneficial bacteria, actinomycetes & fungi (10⁹ cfu/ml)',
      'baseWaterPerAcre': 200, // Liters
      'ingredientsPerAcre': [
        {'name': 'Fresh Indigenous Cow Dung (Desi Cow)', 'qty': 10.0, 'unit': 'kg'},
        {'name': 'Indigenous Cow Urine (Gomutra)', 'qty': 10.0, 'unit': 'Liters'},
        {'name': 'Organic Jaggery (Gur / Sugar Cane Juice)', 'qty': 2.0, 'unit': 'kg'},
        {'name': 'Pulse / Gram Flour (Besan)', 'qty': 2.0, 'unit': 'kg'},
        {'name': 'Virgin Soil from Uncultivated Tree Base / Bund', 'qty': 0.5, 'unit': 'kg'},
      ],
      'fermentationHours': 48,
      'instructions':
          'Mix all ingredients clockwise with a wooden stick in a plastic drum. Ferment under shade for 48 to 72 hours, stirring for 1 minute twice daily. Filter through fine cloth and apply via drip or flood irrigation.',
      'shelfLife': '7 to 10 Days maximum',
      'color': const Color(0xFF33691E),
    },
    {
      'id': 'ghanajeevamrutha',
      'name': 'Ghanajeevamrutha (Solid Microbial Enriched Manure)',
      'purpose': 'Slow-release basal soil fertilizer rich in humus and soil conditioning microbes',
      'baseWaterPerAcre': 20, // Liters Jeevamrutha liquid for coating
      'ingredientsPerAcre': [
        {'name': 'Dry Indigenous Cow Dung / Vermicompost', 'qty': 100.0, 'unit': 'kg'},
        {'name': 'Liquid Jeevamrutha (2 days fermented)', 'qty': 20.0, 'unit': 'Liters'},
        {'name': 'Pulse / Gram Flour (Besan)', 'qty': 2.0, 'unit': 'kg'},
        {'name': 'Jaggery Powder', 'qty': 2.0, 'unit': 'kg'},
      ],
      'fermentationHours': 120,
      'instructions':
          'Spread dry cow dung evenly, sprinkle Jeevamrutha solution, mix thoroughly, make a heap, cover with jute bags for 48 hours, then dry in shade.',
      'shelfLife': '6 to 12 Months',
      'color': const Color(0xFF558B2F),
    },
    {
      'id': 'neemastra',
      'name': 'Neemastra (Botanical Pest Deterrent)',
      'purpose': 'Natural broad-spectrum pesticide against whiteflies, aphids, jassids, and thrips',
      'baseWaterPerAcre': 100, // Liters
      'ingredientsPerAcre': [
        {'name': 'Crushed Fresh Neem Leaves & Twigs', 'qty': 5.0, 'unit': 'kg'},
        {'name': 'Fresh Desi Cow Urine (Gomutra)', 'qty': 5.0, 'unit': 'Liters'},
        {'name': 'Fresh Cow Dung', 'qty': 2.0, 'unit': 'kg'},
      ],
      'fermentationHours': 24,
      'instructions':
          'Mix ingredients in 100L water and ferment for 24-48 hours. Filter through fine muslin cloth and spray directly on foliage without further dilution.',
      'shelfLife': '30 Days',
      'color': const Color(0xFF1B5E20),
    },
    {
      'id': 'dashparni',
      'name': 'Dashparni Ark (10-Leaf Super Bio-Pesticide)',
      'purpose': 'Heavy-duty organic shield against helicoverpa caterpillars, pod borers & fungus',
      'baseWaterPerAcre': 200, // Liters
      'ingredientsPerAcre': [
        {'name': 'Neem, Custard Apple, Papaya, Guava & Castor leaves', 'qty': 10.0, 'unit': 'kg (2kg each)'},
        {'name': 'Calotropis (Aak), Datura, Lantana, Pongamia leaves', 'qty': 8.0, 'unit': 'kg (2kg each)'},
        {'name': 'Crushed Green Chilli & Garlic Paste', 'qty': 1.0, 'unit': 'kg'},
        {'name': 'Desi Cow Urine', 'qty': 10.0, 'unit': 'Liters'},
        {'name': 'Fresh Cow Dung', 'qty': 2.0, 'unit': 'kg'},
      ],
      'fermentationHours': 720, // 30 days
      'instructions':
          'Crush leaves and ferment in water for 30 to 40 days under shade. Filter and spray at 200 ml per 15-liter knapsack sprayer tank.',
      'shelfLife': '6 Months',
      'color': const Color(0xFF004D40),
    },
    {
      'id': 'panchagavya',
      'name': 'Panchagavya (Vedic Plant Growth Booster)',
      'purpose': 'Hormonal growth promoter, flowering booster, and fruit quality enhancer',
      'baseWaterPerAcre': 50,
      'ingredientsPerAcre': [
        {'name': 'Desi Cow Dung + Cow Ghee', 'qty': 5.0, 'unit': 'kg (mixed for 3 days)'},
        {'name': 'Desi Cow Urine', 'qty': 3.0, 'unit': 'Liters'},
        {'name': 'Fresh Cow Milk + Curd', 'qty': 4.0, 'unit': 'Liters (2L each)'},
        {'name': 'Sugarcane Juice / Jaggery Water', 'qty': 3.0, 'unit': 'Liters'},
        {'name': 'Tender Coconut Water', 'qty': 3.0, 'unit': 'Liters'},
        {'name': 'Ripe Bananas (Poovan)', 'qty': 12.0, 'unit': 'pieces (mashed)'},
      ],
      'fermentationHours': 480, // 20 days
      'instructions':
          'Ferment for 18-21 days with periodic stirring. Dilute 300 ml per 10 liters of water for foliar spray at pre-flowering and fruit-set stages.',
      'shelfLife': '6 Months',
      'color': const Color(0xFF6A1B9A),
    },
  ];

  // ----------------------------------------------------
  // HYDROPONIC CROP TARGETS
  // ----------------------------------------------------
  final Map<String, Map<String, dynamic>> _hydroCropDatabase = {
    'Leafy Greens (Lettuce, Spinach, Kale)': {
      'ecMin': 1.2,
      'ecMax': 1.8,
      'phMin': 5.8,
      'phMax': 6.5,
      'waterTemp': '18°C - 22°C',
      'dliHours': '14 - 16 Hours',
      'notes': 'High vegetative nitrogen requirement; maintain DO > 6.5 mg/L to prevent root rot.',
    },
    'Fruiting Crops (Tomatoes, Bell Peppers)': {
      'ecMin': 2.0,
      'ecMax': 3.2,
      'phMin': 5.8,
      'phMax': 6.5,
      'waterTemp': '20°C - 24°C',
      'dliHours': '16 - 18 Hours',
      'notes': 'Switch to high Potassium & Calcium formula at flowering to avoid Blossom End Rot.',
    },
    'Berries (Hydroponic Strawberry)': {
      'ecMin': 1.0,
      'ecMax': 1.5,
      'phMin': 5.5,
      'phMax': 6.2,
      'waterTemp': '16°C - 20°C',
      'dliHours': '12 - 14 Hours',
      'notes': 'Sensitive to high salinity and salt accumulation; flush system every 14 days.',
    },
    'Culinary Herbs (Basil, Mint, Oregano)': {
      'ecMin': 1.0,
      'ecMax': 1.6,
      'phMin': 5.8,
      'phMax': 6.4,
      'waterTemp': '19°C - 23°C',
      'dliHours': '14 - 16 Hours',
      'notes': 'Lower EC intensifies essential oil aroma and leaf flavor compounds.',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // COMPUTATIONS
  // ----------------------------------------------------
  Map<String, dynamic> get _activeConcoctionData {
    return _concoctionsDatabase.firstWhere(
      (c) => c['name'] == _selectedConcoction,
      orElse: () => _concoctionsDatabase.first,
    );
  }

  Map<String, dynamic> get _activeHydroData {
    return _hydroCropDatabase[_selectedHydroCrop] ??
        _hydroCropDatabase['Leafy Greens (Lettuce, Spinach, Kale)']!;
  }

  @override
  Widget build(BuildContext context) {
    final concoction = _activeConcoctionData;
    final hydroData = _activeHydroData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 270.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF33691E),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
                  tooltip: 'Organic Traceability QR',
                  onPressed: _showTraceabilityModal,
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
                  tooltip: 'Export Audit Log',
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
                            Color(0xFF33691E),
                            Color(0xFF1B5E20),
                            Color(0xFF4A148C),
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
                                      const Icon(Icons.verified,
                                          color: Colors.greenAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'NPOP / PGS-India Certified Standards',
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
                                  'Chemical-Free: 100%',
                                  style: GoogleFonts.outfit(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Organic & Smart CEA Hydroponics',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bio-Inputs, Microbe Multipliers & Vertical CEA Lab',
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
                                    icon: Icons.eco_rounded,
                                    label: 'Bio-Formulations',
                                    value: '8 Recipes',
                                    color: Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.bolt_rounded,
                                    label: 'Nutrient EC',
                                    value: '$_currentEc mS/cm',
                                    color: Colors.purpleAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.science_rounded,
                                    label: 'Reservoir pH',
                                    value: '$_currentPh pH',
                                    color: Colors.cyanAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildHeroStatPill(
                                    icon: Icons.security_rounded,
                                    label: 'Audit Score',
                                    value: '98.5% Compliant',
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
                indicatorColor: Colors.lightGreenAccent,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.eco_rounded), text: 'Organic Formulator'),
                  Tab(icon: Icon(Icons.science_rounded), text: 'Hydroponics Lab'),
                  Tab(icon: Icon(Icons.biotech_rounded), text: 'Soil Microbiome'),
                  Tab(icon: Icon(Icons.verified_rounded), text: 'Traceability Audit'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrganicFormulatorTab(concoction),
            _buildHydroponicsLabTab(hydroData),
            _buildSoilMicrobiomeTab(),
            _buildTraceabilityAuditTab(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _saveConcoctionBatch,
              backgroundColor: const Color(0xFF33691E),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                'Save Recipe Batch',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          } else if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              onPressed: _commitHydroLog,
              backgroundColor: const Color(0xFF6A1B9A),
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: Text(
                'Commit EC/pH Log',
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
  // TAB 1: NATURAL FARMING & CONCOCTION FORMULATOR
  // =========================================================================
  Widget _buildOrganicFormulatorTab(Map<String, dynamic> concoction) {
    final ingredients =
        concoction['ingredientsPerAcre'] as List<Map<String, dynamic>>;
    final totalWater = ((concoction['baseWaterPerAcre'] as num) * _acreageToTreat).toInt();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Recipe Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                concoction['color'] as Color,
                const Color(0xFF1B5E20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (concoction['color'] as Color).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organic Concoction Formulator',
                style: GoogleFonts.outfit(
                  color: Colors.green.shade100,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                concoction['name'] as String,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scaled for ${_acreageToTreat.toStringAsFixed(1)} Acres • Total Solution: $totalWater Liters',
                style: TextStyle(color: Colors.green.shade100, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Controls Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedConcoction,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Formulation'),
                  items: _concoctionsDatabase.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['name'] as String,
                      child: Text(c['name'] as String,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedConcoction = v!),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Land Area to Treat',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('${_acreageToTreat.toStringAsFixed(1)} Acres',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF33691E))),
                  ],
                ),
                Slider(
                  value: _acreageToTreat,
                  min: 0.5,
                  max: 20.0,
                  divisions: 39,
                  activeColor: const Color(0xFF33691E),
                  onChanged: (v) => setState(() => _acreageToTreat = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Scaled Ingredients Table
        Text(
          'Exact Scaled Ingredients Required',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        ...ingredients.map((ing) {
          final scaledQty = (ing['qty'] as num).toDouble() * _acreageToTreat;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.check_circle, color: Color(0xFF33691E), size: 20),
              ),
              title: Text(
                ing['name'] as String,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              trailing: Text(
                '${scaledQty.toStringAsFixed(1)} ${ing['unit']}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: const Color(0xFF33691E),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Step by Step Preparation Card
        Card(
          color: const Color(0xFFF1F8E9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFC5E1A5))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: Color(0xFF33691E)),
                    const SizedBox(width: 8),
                    Text(
                      'Preparation & Dilution Protocol',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  concoction['instructions'] as String,
                  style: TextStyle(
                      fontSize: 13, color: Colors.green.shade900, height: 1.4),
                ),
                const Divider(height: 20),
                Text(
                  '⏳ Shelf Life: ${concoction['shelfLife']}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.brown.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: HYDROPONICS & VERTICAL CEA LAB
  // =========================================================================
  Widget _buildHydroponicsLabTab(Map<String, dynamic> hydroData) {
    final ecMin = (hydroData['ecMin'] as num).toDouble();
    final ecMax = (hydroData['ecMax'] as num).toDouble();
    final isEcOptimal = _currentEc >= ecMin && _currentEc <= ecMax;

    final phMin = (hydroData['phMin'] as num).toDouble();
    final phMax = (hydroData['phMax'] as num).toDouble();
    final isPhOptimal = _currentPh >= phMin && _currentPh <= phMax;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Hydro Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6A1B9A),
                Color(0xFF4A148C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precision CEA Hydroponic Reservoir Lab',
                style: GoogleFonts.outfit(
                  color: Colors.purple.shade100,
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
                        '$_currentEc mS/cm',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        isEcOptimal ? '🟢 Target EC Range' : '⚠️ Nutrient Imbalance',
                        style: TextStyle(
                            color: Colors.purple.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_currentPh pH',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        isPhOptimal ? '🟢 Optimal Absorption' : '⚠️ Adjust pH Dosing',
                        style: TextStyle(
                            color: Colors.purple.shade100, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Interactive Lab Controls
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedHydroCrop,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Cultivated Hydroponic Crop'),
                  items: _hydroCropDatabase.keys.map((c) {
                    return DropdownMenuItem<String>(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedHydroCrop = v!),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Electrical Conductivity (EC)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('$_currentEc mS/cm',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6A1B9A))),
                  ],
                ),
                Slider(
                  value: _currentEc,
                  min: 0.5,
                  max: 4.0,
                  divisions: 35,
                  activeColor: const Color(0xFF6A1B9A),
                  onChanged: (v) => setState(() => _currentEc = v),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Solution pH Level',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('$_currentPh',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            color: Colors.teal.shade800)),
                  ],
                ),
                Slider(
                  value: _currentPh,
                  min: 4.0,
                  max: 9.0,
                  divisions: 50,
                  activeColor: Colors.teal.shade800,
                  onChanged: (v) => setState(() => _currentPh = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Crop Target Specifications
        Text(
          'Optimal Agronomic Target Profile',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 10),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Target EC: $ecMin - $ecMax mS/cm',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    Text('Target pH: $phMin - $phMax',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 16),
                Text('🌡️ Water Temp: ${hydroData['waterTemp']}'),
                Text('💡 Photoperiod: ${hydroData['dliHours']}'),
                const SizedBox(height: 6),
                Text('📝 Note: ${hydroData['notes']}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 3: SOIL MICROBIOME & HUMUS REGENERATION
  // =========================================================================
  Widget _buildSoilMicrobiomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soil Biological Vigor & Humus Index',
                  style: GoogleFonts.outfit(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continuous application of Jeevamrutha and Ghanajeevamrutha promotes native earthworm (Eisenia foetida & Desi Eudrilus) surfacing.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Divider(height: 24),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.eco, color: Colors.green),
                  title: const Text('Earthworm Casting Density: 24 / m²'),
                  subtitle: const Text('Optimal soil porosity & aeration active'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bubble_chart, color: Colors.blue),
                  title: const Text('Organic Carbon Content: 1.42% (High)'),
                  subtitle: const Text('Benchmarked above ICAR 0.75% threshold'),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.layers, color: Colors.amber),
                  title: const Text('Live Mulching Coverage: 85%'),
                  subtitle: const Text('Sunnhemp & Cowpea green manure'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 4: TRACEABILITY & AUDIT LOG
  // =========================================================================
  Widget _buildTraceabilityAuditTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NPOP & PGS-India Farm Audit Compliance',
                  style: GoogleFonts.outfit(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'All bio-input applications, botanical extracts, and seed sourcing records are digitally immutably logged for certification export.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const Divider(height: 24),
                _buildAuditItem('Buffer Zone Maintenance', '3-meter physical buffer against chemical drift', true),
                _buildAuditItem('Heirloom Desi Seed Certification', 'Zero GMO / Hybrid chemical coated seeds', true),
                _buildAuditItem('Zero Synthetic Pesticides', '100% botanical sprays (Neemastra & Dashparni)', true),
                _buildAuditItem('Third-Party Soil Heavy Metal Test', 'Lead, Cadmium & Arsenic below detectable limits', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditItem(String title, String subtitle, bool isCompliant) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isCompliant ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: isCompliant ? Colors.green : Colors.red,
      ),
      title: Text(title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }

  // =========================================================================
  // ACTIONS & TOASTS
  // =========================================================================
  void _saveConcoctionBatch() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${_selectedConcoction.split(' ').first} batch logged for $_acreageToTreat Acres!'),
        backgroundColor: const Color(0xFF33691E),
      ),
    );
  }

  void _commitHydroLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Hydroponic EC/pH telemetry committed to cloud!'),
        backgroundColor: Color(0xFF6A1B9A),
      ),
    );
  }

  void _showTraceabilityModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Export Traceability QR generated for organic batch audit!'),
        backgroundColor: Color(0xFF33691E),
      ),
    );
  }

  void _showExportToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 NPOP / PGS-India Organic Compliance Audit Log exported!'),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
  }
}
