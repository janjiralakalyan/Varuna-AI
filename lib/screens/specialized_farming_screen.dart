import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_screen.dart';

class SpecializedFarmingScreen extends StatefulWidget {
  const SpecializedFarmingScreen({super.key});

  @override
  State<SpecializedFarmingScreen> createState() =>
      _SpecializedFarmingScreenState();
}

class _SpecializedFarmingScreenState extends State<SpecializedFarmingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _beeHives = [
    {
      'id': 'HIVE-01',
      'species': 'Apis cerana indica (Indian Honey Bee)',
      'status': 'Strong Colony (Queen Active)',
      'frames': 8,
      'honeyReady': '3.5 kg est. harvest in 10 days',
      'color': const Color(0xFFF57F17),
    },
    {
      'id': 'HIVE-02',
      'species': 'Apis mellifera (Italian Bee)',
      'status': 'Super Box Installed',
      'frames': 10,
      'honeyReady': '5.2 kg super frame ready',
      'color': const Color(0xFFE65100),
    },
  ];

  final List<Map<String, dynamic>> _mushroomBeds = [
    {
      'batch': 'Batch M-14 (Oyster Mushroom - Pleurotus)',
      'bags': 250,
      'stage': 'Pinhead Emergence (Flush 1)',
      'humidity': '88% (Optimal)',
      'temp': '24.2 °C',
      'action': 'Spray fine water mist 3x daily; maintain cross ventilation',
      'color': const Color(0xFF5D4037),
    },
    {
      'batch': 'Batch M-15 (Milky Mushroom - Calocybe indica)',
      'bags': 180,
      'stage': 'Casing Layer Incubation',
      'humidity': '82%',
      'temp': '31.0 °C',
      'action': 'Maintain darkness until mycelium run completes',
      'color': const Color(0xFF795548),
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
      backgroundColor: const Color(0xFFFCF9F2),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: const Color(0xFFF57F17),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF57F17),
                        Color(0xFFE65100),
                        Color(0xFF6D4C41),
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
                                    const Icon(Icons.hive_rounded, color: Colors.amberAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'High-Value Micro-Enterprises',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Multi-Species Hub',
                                style: GoogleFonts.outfit(color: Colors.amber.shade200, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Specialized & Micro-Farming',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Apiculture apiaries, mushroom substrate spawns & sericulture silkworm logs.',
                            style: TextStyle(color: Colors.amber.shade100, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPill(Icons.hive, 'Apiary Hives', '8 Colonies', Colors.amberAccent),
                                const SizedBox(width: 8),
                                _buildPill(Icons.bubble_chart, 'Mushroom Bags', '430 Straw Bags', Colors.cyanAccent),
                                const SizedBox(width: 8),
                                _buildPill(Icons.spa, 'Silkworm Trays', '120 DFLs', Colors.greenAccent),
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
                indicatorColor: Colors.amberAccent,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.hive_rounded), text: 'Apiculture (Bees)'),
                  Tab(icon: Icon(Icons.bubble_chart_rounded), text: 'Mushroom Farm'),
                  Tab(icon: Icon(Icons.spa_rounded), text: 'Sericulture (Silk)'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBeekeepingTab(),
            _buildMushroomTab(),
            _buildSericultureTab(),
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
        backgroundColor: const Color(0xFFF57F17),
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: Text(
          'Micro-Farm AI Doctor',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label, String val, Color color) {
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

  Widget _buildBeekeepingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Active Apiary Colonies & Honey Harvest Log', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ..._beeHives.map((h) => Card(
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
                        Text(h['id'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFF57F17))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text('${h['frames']} Frames', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange.shade900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(h['species'], style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(h['honeyReady'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown.shade900))),
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

  Widget _buildMushroomTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Mushroom Spawn Running & Cropping Room', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ..._mushroomBeds.map((m) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['batch'], style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF5D4037))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildBadge('Stage: ${m['stage']}', Colors.brown.shade700),
                        const SizedBox(width: 8),
                        _buildBadge('RH: ${m['humidity']}', Colors.teal.shade700),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Guideline: ${m['action']}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSericultureTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        Text('Silkworm Rearing Beds & Cocoon Crop', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _buildSeriCard('5th Instar Feeding Stage', 'Feed fresh V1 Mulberry shoots twice daily. Avoid wet leaves.', Icons.energy_savings_leaf),
        _buildSeriCard('Mounting & Chandrike Spinners', 'Transfer mature golden-yellow worms to plastic mountages for cocoon spinning.', Icons.all_inclusive),
        _buildSeriCard('Uzi Fly Biological Protection', 'Install nylon mesh net around rearing house and place Uzi traps.', Icons.security),
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

  Widget _buildSeriCard(String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.brown.shade50,
          child: Icon(icon, color: const Color(0xFF5D4037)),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
