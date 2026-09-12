import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../screens/farm_map_screen.dart';

enum MapLayerMode { satellite, ndvi, moisture }

class AgroMonitorMapCard extends StatefulWidget {
  final VoidCallback? onExploreTap;

  const AgroMonitorMapCard({
    super.key,
    this.onExploreTap,
  });

  @override
  State<AgroMonitorMapCard> createState() => _AgroMonitorMapCardState();
}

class _AgroMonitorMapCardState extends State<AgroMonitorMapCard>
    with SingleTickerProviderStateMixin {
  MapLayerMode _selectedLayer = MapLayerMode.ndvi;
  late AnimationController _radarController;
  double _zoomLevel = 1.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _handleExplore() {
    if (widget.onExploreTap != null) {
      widget.onExploreTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FarmMapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withValues(alpha: _isHovered ? 0.22 : 0.12),
              blurRadius: _isHovered ? 26 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 235,
            decoration: const BoxDecoration(
              color: Color(0xFF0F2414),
            ),
            child: Stack(
              children: [
                // 1. Background Interactive Geospatial Simulation Canvas
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _AgroMapCanvasPainter(
                          radarProgress: _radarController.value,
                          layerMode: _selectedLayer,
                          zoomLevel: _zoomLevel,
                        ),
                      );
                    },
                  ),
                ),

                // 2. Subtle Vignette Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.70),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Top HUD Bar: Live Status & Layer Selector
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Live Satellite Radar Sync Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _radarController,
                              builder: (context, _) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00E676),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E676)
                                            .withValues(alpha: 0.6 + 0.4 * math.sin(_radarController.value * 2 * math.pi)),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'SENTINEL-2 • LIVE GIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Layer Switcher Chips
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLayerButton(
                              icon: Icons.satellite_alt_rounded,
                              label: 'SAT',
                              mode: MapLayerMode.satellite,
                            ),
                            _buildLayerButton(
                              icon: Icons.eco_rounded,
                              label: 'NDVI',
                              mode: MapLayerMode.ndvi,
                            ),
                            _buildLayerButton(
                              icon: Icons.water_drop_rounded,
                              label: 'H₂O',
                              mode: MapLayerMode.moisture,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Center Zoom & Control Shortcuts
                Positioned(
                  right: 14,
                  top: 56,
                  child: Column(
                    children: [
                      _buildMapToolBtn(
                        icon: Icons.add_rounded,
                        onTap: () {
                          setState(() {
                            if (_zoomLevel < 1.6) _zoomLevel += 0.2;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildMapToolBtn(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          setState(() {
                            if (_zoomLevel > 0.8) _zoomLevel -= 0.2;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // 5. Bottom HUD: Farm Coordinates, Health Metrics, & CTA Button
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Farm Boundary Coordinates HUD
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF81C784),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Parcel #142/A • Devarkadra (16.64°N, 77.91°E)',
                            style: TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Active layer legend badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getLayerColor().withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getLayerColor().withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              _getLayerBadgeText(),
                              style: TextStyle(
                                color: _getLayerColor(),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Metrics & CTA Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AgroMonitor Field Scan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _selectedLayer == MapLayerMode.ndvi
                                      ? 'NDVI: 0.78 (Optimal Canopy) • 4.75 Ac'
                                      : _selectedLayer == MapLayerMode.moisture
                                          ? 'Root Moisture: 62% • Low Stress'
                                          : 'High-Res Optical Geo-Survey 2026',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Explore Solutions / Field GIS CTA Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleExplore,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore Field GIS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getLayerColor() {
    switch (_selectedLayer) {
      case MapLayerMode.satellite:
        return const Color(0xFF64B5F6);
      case MapLayerMode.ndvi:
        return const Color(0xFF69F0AE);
      case MapLayerMode.moisture:
        return const Color(0xFF4DD0E1);
    }
  }

  String _getLayerBadgeText() {
    switch (_selectedLayer) {
      case MapLayerMode.satellite:
        return 'OPTICAL 10M';
      case MapLayerMode.ndvi:
        return 'NDVI: 0.78 VIGOROUS';
      case MapLayerMode.moisture:
        return 'SOIL H₂O: 62%';
    }
  }

  Widget _buildLayerButton({
    required IconData icon,
    required String label,
    required MapLayerMode mode,
  }) {
    final isSelected = _selectedLayer == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLayer = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapToolBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

/// Custom Geospatial Canvas Painter that renders realistic farm parcels,
/// NDVI heat patterns, topography contours, water irrigation streams, and animated radar sweep.
class _AgroMapCanvasPainter extends CustomPainter {
  final double radarProgress;
  final MapLayerMode layerMode;
  final double zoomLevel;

  _AgroMapCanvasPainter({
    required this.radarProgress,
    required this.layerMode,
    required this.zoomLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Center-based zoom scaling
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(zoomLevel);
    canvas.translate(-size.width / 2, -size.height / 2);

    final bgRect = Offset.zero & size;

    // 1. Draw Field Terrain Grids & Soil Base
    final terrainPaint = Paint()..style = PaintingStyle.fill;
    if (layerMode == MapLayerMode.satellite) {
      terrainPaint.color = const Color(0xFF1E3A20);
    } else if (layerMode == MapLayerMode.ndvi) {
      terrainPaint.color = const Color(0xFF102814);
    } else {
      terrainPaint.color = const Color(0xFF132B36);
    }
    canvas.drawRect(bgRect, terrainPaint);

    // 2. Field Boundary Polygons (Farmer Parcels)
    _drawFarmParcels(canvas, size);

    // 3. Draw Water Canal Stream
    _drawCanalNetwork(canvas, size);

    // 4. Draw Animated Radar Pulse Wave
    _drawRadarWave(canvas, size);

    canvas.restore();
  }

  void _drawFarmParcels(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Main Farmer Parcel Polygon (Devarkadra Sugarcane & Paddy field)
    final mainFieldPath = Path()
      ..moveTo(w * 0.22, h * 0.22)
      ..lineTo(w * 0.74, h * 0.18)
      ..lineTo(w * 0.88, h * 0.68)
      ..lineTo(w * 0.62, h * 0.82)
      ..lineTo(w * 0.16, h * 0.72)
      ..close();

    // Secondary Neighbouring Parcel
    final subFieldPath = Path()
      ..moveTo(w * 0.76, h * 0.20)
      ..lineTo(w * 0.98, h * 0.24)
      ..lineTo(w * 0.96, h * 0.62)
      ..lineTo(w * 0.89, h * 0.66)
      ..close();

    // Fill Parcel based on Selected Layer
    final fieldPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (layerMode == MapLayerMode.ndvi) {
      // Lush vegetation gradient (NDVI 0.78 healthy canopy)
      fieldPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF2E7D32), // High vigor green
          Color(0xFF43A047), // Healthy emerald
          Color(0xFF66BB6A), // Bright canopy
          Color(0xFF81C784), // Moderate
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      borderPaint.color = const Color(0xFFB9F6CA);
    } else if (layerMode == MapLayerMode.moisture) {
      // Moisture gradient (62% saturation)
      fieldPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF00695C),
          Color(0xFF00897B),
          Color(0xFF00ACC1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      borderPaint.color = const Color(0xFF80DEEA);
    } else {
      // True Color Optical Satellite
      fieldPaint.shader = const LinearGradient(
        colors: [
          Color(0xFF2E5A27),
          Color(0xFF3B6E32),
          Color(0xFF4C8240),
          Color(0xFF33582A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
      borderPaint.color = const Color(0xFFA5D6A7);
    }

    canvas.drawPath(mainFieldPath, fieldPaint);
    canvas.drawPath(mainFieldPath, borderPaint);

    // Draw Subfield with softer opacity
    final subPaint = Paint()
      ..color = borderPaint.color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(subFieldPath, subPaint);

    // Draw Field Contour Lines (Crop Furrows / Rows)
    final furrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double i = 0.28; i <= 0.65; i += 0.08) {
      canvas.drawLine(
        Offset(w * 0.25, h * i),
        Offset(w * 0.72, h * (i + 0.02)),
        furrowPaint,
      );
    }

    // Centroid Marker for Farmer Field
    final markerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.48, h * 0.48), 3.5, markerPaint);

    final markerRing = Paint()
      ..color = borderPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(w * 0.48, h * 0.48), 8.0, markerRing);
  }

  void _drawCanalNetwork(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Irrigation Saraswati Canal Branch A Path
    final canalPath = Path()
      ..moveTo(0, h * 0.55)
      ..cubicTo(w * 0.2, h * 0.52, w * 0.35, h * 0.78, w * 0.65, h * 0.88)
      ..lineTo(w * 1.0, h * 0.95);

    final canalGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final canalWater = Paint()
      ..color = const Color(0xFF80D8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(canalPath, canalGlow);
    canvas.drawPath(canalPath, canalWater);
  }

  void _drawRadarWave(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.48, h * 0.48);

    final maxRadius = w * 0.65;
    final waveRadius = maxRadius * radarProgress;

    // Expanding Radar Circle
    final radarRing = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: (1.0 - radarProgress).clamp(0.0, 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(center, waveRadius, radarRing);

    // Radar Scanning Beam Sweep
    final sweepAngle = radarProgress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          const Color(0xFF00E676).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 100));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.drawCircle(Offset.zero, 110, sweepPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AgroMapCanvasPainter oldDelegate) {
    return oldDelegate.radarProgress != radarProgress ||
        oldDelegate.layerMode != layerMode ||
        oldDelegate.zoomLevel != zoomLevel;
  }
}
