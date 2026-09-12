import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_screen.dart';

class HorticultureScreen extends StatefulWidget {
  const HorticultureScreen({super.key});

  @override
  State<HorticultureScreen> createState() => _HorticultureScreenState();
}

class _HorticultureScreenState extends State<HorticultureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final double _orchardAcreage = 4.0;
  final double _polyhouseTemp = 26.5;
  final double _polyhouseHumidity = 72.0;

  final List<Map<String, dynamic>> _orchardBlocks = [
    {
      'name': 'Block A - High Density Mango',
      'variety': 'Alphonso (Ratnagiri)',
      'trees': 450,
      'stage': 'Full Bloom Flowering',
      'canopyStatus': 'Pruned & Aerated',
      'sprayDue': 'Gibberellic Acid Booster (in 3 days)',
      'color': const Color(0xFFE65100),
    },
    {
      'name': 'Block B - Pomegranate Orchards',
      'variety': 'Bhagawa Super',
      'trees': 600,
      'stage': 'Fruit Development (Marble Size)',
      'canopyStatus': 'Trellised & Bagged',
      'sprayDue': 'Bacterial Blight Shield (Bordeaux)',
      'color': const Color(0xFFC2185B),
    },
    {
      'name': 'Polyhouse 1 - Colored Capsicum',
      'variety': 'Indra Yellow & Red Bell',
      'plants': 3200,
      'stage': 'Harvesting (Flush 3)',
      'canopyStatus': 'De-suckered & Trained',
      'sprayDue': 'Calcium Nitrate Drip Fertigation',
      'color': const Color(0xFF2E7D32),
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: const Color(0xFFE65100),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE65100),
                        Color(0xFFEF6C00),
                        Color(0xFFBF360C),
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
                                    const Icon(Icons.nature_people_rounded, color: Colors.amberAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Precision Orchards & CEA',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '3 Active Blocks',
                                style: GoogleFonts.outfit(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Horticulture & Canopy Intelligence',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Flowering boosters, micro-climate, pruning schedules & fruit quality.',
                            style: TextStyle(color: Colors.orange.shade100, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildHeaderMetricPill(Icons.park_rounded, 'Orchard Area', '$_orchardAcreage Acres', Colors.amberAccent),
                                const SizedBox(width: 8),
                                _buildHeaderMetricPill(Icons.thermostat_rounded, 'Polyhouse Climate', '$_polyhouseTemp°C • $_polyhouseHumidity%', Colors.greenAccent),
                                const SizedBox(width: 8),
                                _buildHeaderMetricPill(Icons.wb_sunny_rounded, 'Canopy PAR', '1150 µmol/m²', Colors.cyanAccent),
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
                isScrollable: true,
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.park_rounded), text: 'Orchard Blocks'),
                  Tab(icon: Icon(Icons.flare_rounded), text: 'Fruit-Set & Bloom'),
                  Tab(icon: Icon(Icons.roofing_rounded), text: 'Polyhouse Climate'),
                  Tab(icon: Icon(Icons.inventory_2_rounded), text: 'Post-Harvest & Cold Chain'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOrchardBlocksTab(),
            _buildFruitSetBoosterTab(),
            _buildPolyhouseClimateTab(),
            _buildPostHarvestTab(),
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
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: Text(
          'Horticulture AI Doctor',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeaderMetricPill(IconData icon, String label, String val, Color color) {
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

  Widget _buildOrchardBlocksTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Orchard Blocks & High-Density Plantations', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE65100)),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._orchardBlocks.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            b['name'],
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFE65100)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            b['variety'],
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge('Stage: ${b['stage']}', Colors.purple.shade700),
                        const SizedBox(width: 8),
                        _buildBadge('Canopy: ${b['canopyStatus']}', Colors.teal.shade700),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notification_important_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Next Action: ${b['sprayDue']}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildFruitSetBoosterTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFFA000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌸 Flowering Induction & Fruit Retention Protocol', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Boost flower-to-fruit ratio and prevent premature flower/fruit drop with precision bio-stimulants.', style: TextStyle(color: Colors.orange.shade50, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildProtocolCard(
          stage: 'Pre-Bloom Induction (Flower Bud Initiation)',
          actions: [
            'Foliar spray: Paclobutrazol (Cultar) / Potassium Nitrate (13-0-45) @ 10g/L',
            'Withhold irrigation for 25-30 days to induce stress flowering in sub-tropical orchards',
            'Spray Solubor (Boron 20%) @ 1.5g/L for uniform pollen viability',
          ],
          color: Colors.purple.shade700,
        ),
        _buildProtocolCard(
          stage: 'Full Bloom & Pollination Phase',
          actions: [
            'Introduce 2-3 Apis cerana beehives per acre for cross-pollination boost',
            'Avoid harsh chemical insecticides during active morning bee visits (8 AM - 11 AM)',
            'Spray Seaweed Extract bio-stimulant @ 2ml/L to enhance stigma receptivity',
          ],
          color: Colors.amber.shade800,
        ),
        _buildProtocolCard(
          stage: 'Fruit-Set & Marble Size Retention',
          actions: [
            'Gibberellic Acid (GA3) @ 20 ppm + Chelated Calcium @ 1g/L to prevent fruitlet drop',
            'Maintain steady soil moisture; apply micro-drip fertigation with 0-52-34 (MKP)',
            'Thin dense clusters (keep 1-2 superior fruits per panicle) for maximum fruit size',
          ],
          color: Colors.teal.shade700,
        ),
      ],
    );
  }

  Widget _buildPolyhouseClimateTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Protected Cultivation & Climate Control', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Automated Mist & Fogger Automation', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                    Switch(value: true, onChanged: (_) {}, activeColor: const Color(0xFFE65100)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildClimateDial('Target Temp', '24 - 28 °C', Icons.thermostat),
                    _buildClimateDial('Relative Humidity', '65 - 75 %', Icons.water_drop),
                    _buildClimateDial('VPD (Transpiration)', '0.95 kPa', Icons.air),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostHarvestTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Cold Chain & Shelf-Life Management', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildColdChainCard('Pre-Cooling Protocol', 'Reduce core temperature to 12°C within 4 hours of harvest to arrest respiration.', Icons.ac_unit),
        _buildColdChainCard('Ethylene Scrubbing', 'Use Potassium Permanganate filters in storage cartons to delay over-ripening.', Icons.science),
        _buildColdChainCard('Modified Atmosphere Packaging (MAP)', 'Optimal gas mix (5% O2, 5% CO2) extends mango and pomegranate transit life to 35 days.', Icons.inventory),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildProtocolCard({required String stage, required List<String> actions, required Color color}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(Icons.eco_rounded, color: color, size: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(stage, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
              ],
            ),
            const SizedBox(height: 10),
            ...actions.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text(a, style: const TextStyle(fontSize: 12, height: 1.3))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateDial(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE65100), size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildColdChainCard(String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade50,
          child: Icon(icon, color: const Color(0xFFE65100)),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
