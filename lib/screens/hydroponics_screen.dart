import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_screen.dart';

class HydroponicsScreen extends StatefulWidget {
  const HydroponicsScreen({super.key});

  @override
  State<HydroponicsScreen> createState() => _HydroponicsScreenState();
}

class _HydroponicsScreenState extends State<HydroponicsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _reservoirEc = 1.65; // mS/cm (Target: 1.4 - 1.8)
  double _reservoirPh = 6.15; // (Target: 5.8 - 6.5)
  double _waterTempC = 21.5; // °C (Target: 18 - 22°C)
  double _waterLevelPct = 84.0; // %
  String _selectedSystemType = 'NFT Channel System (Nutrient Film Technique)';

  final List<Map<String, dynamic>> _nutrientRecipes = [
    {
      'crop': 'Butterhead & Romaine Lettuce',
      'targetEc': '1.2 - 1.6 mS/cm',
      'targetPh': '5.6 - 6.2',
      'npkRatio': '16-5-25 (High Nitrogen & Potassium)',
      'lightingHours': '16 Hours / day (DLI: 14 mol/m²)',
      'color': const Color(0xFF6A1B9A),
    },
    {
      'crop': 'Hydroponic Strawberries',
      'targetEc': '1.4 - 1.9 mS/cm',
      'targetPh': '5.8 - 6.2',
      'npkRatio': '8-12-32 (High Potassium for Brix)',
      'lightingHours': '14 Hours / day (PPFD: 350 µmol)',
      'color': const Color(0xFFAD1457),
    },
    {
      'crop': 'Cherry Tomatoes & Bell Peppers (DWC/Dutch Bucket)',
      'targetEc': '2.0 - 2.8 mS/cm',
      'targetPh': '6.0 - 6.5',
      'npkRatio': '12-15-36 (Heavy Magnesium & Calcium)',
      'lightingHours': '18 Hours / day (PPFD: 500 µmol)',
      'color': const Color(0xFFE65100),
    },
    {
      'crop': 'Exotic Culinary Herbs (Basil, Mint, Oregano)',
      'targetEc': '1.0 - 1.4 mS/cm',
      'targetPh': '5.8 - 6.3',
      'npkRatio': '14-7-28 (Essential oil boost)',
      'lightingHours': '14 Hours / day',
      'color': const Color(0xFF2E7D32),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FD),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: const Color(0xFF6A1B9A),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6A1B9A),
                        Color(0xFF8E24AA),
                        Color(0xFF4A148C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.science_rounded, color: Colors.cyanAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Controlled Environment Agriculture',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(8)),
                                child: Text('Sensors Online', style: GoogleFonts.outfit(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hydroponics & CEA Telemetry',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Closed-loop reservoir dosing, EC/pH balancing & automated NFT schedules.',
                            style: TextStyle(color: Colors.purple.shade100, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildMetricChip(Icons.bolt, 'EC Level', '$_reservoirEc mS/cm', Colors.greenAccent),
                                const SizedBox(width: 8),
                                _buildMetricChip(Icons.water_drop, 'pH Balance', '$_reservoirPh (Optimal)', Colors.cyanAccent),
                                const SizedBox(width: 8),
                                _buildMetricChip(Icons.thermostat, 'Water Temp', '$_waterTempC °C', Colors.amberAccent),
                                const SizedBox(width: 8),
                                _buildMetricChip(Icons.opacity, 'Tank Volume', '${_waterLevelPct.toInt()}%', Colors.purpleAccent),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyanAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.speed_rounded), text: 'Reservoir Telemetry'),
                  Tab(icon: Icon(Icons.science_outlined), text: 'Nutrient Recipes'),
                  Tab(icon: Icon(Icons.timer_outlined), text: 'Pump & Light Schedules'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTelemetryTab(),
            _buildNutrientRecipesTab(),
            _buildSchedulesTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
          );
        },
        backgroundColor: const Color(0xFF6A1B9A),
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: Text(
          'Hydro AI Chemist',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9)),
              Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTab() {
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
                Text('Active System Profile', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedSystemType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Hydroponic System Architecture',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NFT Channel System (Nutrient Film Technique)', child: Text('NFT Channel System (Nutrient Film Technique)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Deep Water Culture (DWC Raft Beds)', child: Text('Deep Water Culture (DWC Raft Beds)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Dutch Bucket / Bato Bucket (Vine Crops)', child: Text('Dutch Bucket / Bato Bucket (Vine Crops)', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 'Vertical Aeroponics Tower', child: Text('Vertical Aeroponics Tower', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSystemType = v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Live Dosing Pumps & Balancers', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildDosingCard('A/B Nutrient Dosing Pump', 'Auto-injected 45 ml Part A & Part B today.', Colors.purple.shade700, true),
        _buildDosingCard('pH Down Pump (Phosphoric Acid)', 'Stable at pH 6.15. No dosing required.', Colors.teal.shade700, false),
        _buildDosingCard('Submersible Oxygen Diffuser', 'Dissolved Oxygen at 8.2 mg/L (Aerobic root zone).', Colors.blue.shade700, true),
      ],
    );
  }

  Widget _buildNutrientRecipesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Target Crop Nutrient Formulations', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ..._nutrientRecipes.map((r) => Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                        Expanded(
                          child: Text(
                            r['crop'],
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF6A1B9A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(r['targetEc'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.purple.shade900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Target pH: ${r['targetPh']} • Ratio: ${r['npkRatio']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Lighting: ${r['lightingHours']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSchedulesTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Automated Lighting & Pump Timing', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildScheduleCard('NFT Circulation Pump', 'Continuous 24/7 with 15 min rest at night', Icons.autorenew),
        _buildScheduleCard('Full-Spectrum LED Grow Lights', '06:00 AM – 10:00 PM (16h Photoperiod)', Icons.wb_incandescent),
        _buildScheduleCard('Ozone Tank Sterilization', 'Every Sunday at 02:00 AM (30 min cycle)', Icons.sanitizer),
      ],
    );
  }

  Widget _buildDosingCard(String title, String desc, Color color, bool active) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.water_drop, color: color),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Switch(value: active, onChanged: (_) {}, activeColor: color),
      ),
    );
  }

  Widget _buildScheduleCard(String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade50,
          child: Icon(icon, color: const Color(0xFF6A1B9A)),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
