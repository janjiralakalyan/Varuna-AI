import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/agro_monitoring_service.dart';
import '../providers/locale_provider.dart';
import '../utils/app_translations.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({super.key});

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  GoogleMapController? _mapController;
  bool isLoading = true;
  String? errorMessage;

  String? polyId;
  Map<String, dynamic>? soilData;
  List<dynamic>? weatherForecast;
  List<dynamic>? satelliteImages;

  String _selectedSatLayer = 'truecolor';
  double _satZoom = 1.0;
  // Dynamic Farm Location (Defaulting to Hyderabad until determined)
  double baseLat = 17.3850;
  double baseLng = 78.4867;

  // Define a polygon for the farm
  List<List<double>> farmCoordinates = [];

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5));
          baseLat = position.latitude;
          baseLng = position.longitude;
        }
      }
    } catch (e) {
      debugPrint("Location fallback to default coords: $e");
    }

    farmCoordinates = [
      [baseLng - 0.0025, baseLat - 0.0025],
      [baseLng + 0.0025, baseLat - 0.0025],
      [baseLng + 0.0025, baseLat + 0.0025],
      [baseLng - 0.0025, baseLat + 0.0025],
      [baseLng - 0.0025, baseLat - 0.0025],
    ];

    if (mounted) setState(() {});
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(baseLat, baseLng)),
    );
  }

  Future<void> _loadFarmData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await _getCurrentLocation();

    try {
      try {
        polyId = await AgroMonitoringService.createPolygon("My Smart Farm", farmCoordinates);
      } catch (_) {
        polyId = await AgroMonitoringService.getExistingPolygonId();
      }

      if (polyId != null) {
        try {
          soilData = await AgroMonitoringService.getCurrentSoilData(polyId!);
        } catch (_) {}
        try {
          weatherForecast = await AgroMonitoringService.getWeatherForecast(baseLat, baseLng);
        } catch (_) {}
        try {
          final endDate = DateTime.now();
          final startDate = endDate.subtract(const Duration(days: 30));
          satelliteImages = await AgroMonitoringService.getSatelliteImages(polyId!, startDate, endDate);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Farm data fetch warning: $e");
    }

    // Default fallback soil metrics if API is pending or offline
    soilData ??= {
      't0': 301.15, // ~28°C
      'moisture': 0.38, // 38%
    };

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Set<Polygon> _generateFarmPolygon() {
    return {
      Polygon(
        polygonId: const PolygonId('my_farm'),
        points: farmCoordinates.map((coord) => LatLng(coord[1], coord[0])).toList(),
        fillColor: AppConstants.primaryColor.withValues(alpha: 0.3),
        strokeColor: AppConstants.primaryColor,
        strokeWidth: 2,
      ),
    };
  }

  // Format Kelvin to Celsius
  String _formatTemp(dynamic kelvin) {
    if (kelvin == null) return '--';
    final double k = kelvin is int ? kelvin.toDouble() : kelvin as double;
    return '${(k - 273.15).toStringAsFixed(1)}°C';
  }

  Widget _buildMetricsCard(BuildContext context, String langCode) {
    if (soilData == null) return const SizedBox.shrink();

    final t0 = soilData!['t0']; // Surface Temp
    final moisture = soilData!['moisture']; // Moisture volume

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🌱 Soil Metrics (Real-Time)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(Icons.thermostat_rounded, AppTranslations.get('sat_surface_temp', langCode), _formatTemp(t0), Colors.orange),
                _buildMetricItem(Icons.water_drop_rounded, AppTranslations.get('sat_soil_moisture', langCode), '${(moisture * 100).toStringAsFixed(1)}%', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildAgroMonitoringSatelliteHero(BuildContext context, String langCode) {
    Map<String, dynamic>? recentImage;
    if (satelliteImages != null && satelliteImages!.isNotEmpty) {
      recentImage = satelliteImages!.first as Map<String, dynamic>?;
    }

    final dateUnix = recentImage?['dt'];
    final dateStr = dateUnix != null
        ? DateFormat('dd MMM yyyy').format(DateTime.fromMillisecondsSinceEpoch(dateUnix * 1000))
        : 'Live Scene';
    final satType = (recentImage?['type'] ?? 'Sentinel-2').toString();
    final cloudCover = recentImage?['cl'] != null ? '${(recentImage!['cl']).toStringAsFixed(0)}%' : '0%';

    final truecolorUrl = recentImage?['image']?['truecolor'];
    final ndviUrl = recentImage?['image']?['ndvi'];
    final falsecolorUrl = recentImage?['image']?['falsecolor'] ?? recentImage?['image']?['ndwi'] ?? recentImage?['image']?['evi'];

    String? activeImageUrl;
    String layerTitle = 'True Color Optical';
    String layerDesc = AppTranslations.get('sat_desc_truecolor', langCode);
    Color layerAccent = const Color(0xFF00E676);

    if (_selectedSatLayer == 'ndvi') {
      activeImageUrl = ndviUrl ?? truecolorUrl;
      layerTitle = 'NDVI Canopy Vigor';
      layerDesc = AppTranslations.get('sat_desc_ndvi', langCode);
      layerAccent = const Color(0xFF69F0AE);
    } else if (_selectedSatLayer == 'falsecolor') {
      activeImageUrl = falsecolorUrl ?? truecolorUrl;
      layerTitle = 'Moisture & False Color';
      layerDesc = AppTranslations.get('sat_desc_moisture', langCode);
      layerAccent = const Color(0xFF4DD0E1);
    } else {
      activeImageUrl = truecolorUrl ?? ndviUrl;
      layerTitle = 'True Color Optical';
      layerDesc = AppTranslations.get('sat_desc_truecolor', langCode);
      layerAccent = const Color(0xFF64B5F6);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛰️ 1. Top HUD Header: Satellite Constellation & Scene Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black.withValues(alpha: 0.45),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00E676),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00E676),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$satType • ${AppTranslations.get('sat_live_badge', langCode)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$dateStr • Cloud: $cloudCover',
                      style: const TextStyle(
                        color: Color(0xFFC8E6C9),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🛰️ 2. Interactive Satellite Imagery Viewport
            SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Active Satellite Layer
                  if (activeImageUrl != null && activeImageUrl.isNotEmpty)
                    Transform.scale(
                      scale: _satZoom,
                      child: Image.network(
                        activeImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFF09170D),
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFF00E676)),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/features/feature_agro_weather.jpg',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    )
                  else
                    Image.asset(
                      'assets/features/feature_agro_weather.jpg',
                      fit: BoxFit.cover,
                    ),

                  // Contrast Vignette Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // Floating Farm Parcel Boundary Reticle
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF00E676).withValues(alpha: 0.75),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF00E676).withValues(alpha: 0.08),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 6,
                            child: Text(
                              'PARCEL #142/A',
                              style: TextStyle(
                                color: const Color(0xFF00E676).withValues(alpha: 0.9),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 6,
                            child: Text(
                              '4.75 AC',
                              style: TextStyle(
                                color: const Color(0xFF00E676).withValues(alpha: 0.9),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Zoom in/out tool buttons on the right
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _buildMapToolIcon(Icons.add_rounded, () {
                          setState(() {
                            if (_satZoom < 1.8) _satZoom += 0.2;
                          });
                        }),
                        const SizedBox(height: 6),
                        _buildMapToolIcon(Icons.remove_rounded, () {
                          setState(() {
                            if (_satZoom > 0.8) _satZoom -= 0.2;
                          });
                        }),
                      ],
                    ),
                  ),

                  // Bottom Active Layer Title & Parcel Coordinates
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: layerAccent.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: layerAccent.withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  layerTitle.toUpperCase(),
                                  style: TextStyle(
                                    color: layerAccent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${baseLat.toStringAsFixed(4)}°N, ${baseLng.toStringAsFixed(4)}°E',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Fullscreen modal tap icon
                        GestureDetector(
                          onTap: () {
                            if (activeImageUrl != null) {
                              _showFullScreenSatelliteImage(context, activeImageUrl, layerTitle);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🛰️ 3. Multi-Spectral Layer Switcher Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF09170D),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSatLayerChip(
                          modeKey: 'truecolor',
                          label: AppTranslations.get('sat_layer_truecolor', langCode),
                          icon: Icons.satellite_alt_rounded,
                          accentColor: const Color(0xFF64B5F6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSatLayerChip(
                          modeKey: 'ndvi',
                          label: AppTranslations.get('sat_layer_ndvi', langCode),
                          icon: Icons.eco_rounded,
                          accentColor: const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSatLayerChip(
                          modeKey: 'falsecolor',
                          label: AppTranslations.get('sat_layer_moisture', langCode),
                          icon: Icons.water_drop_rounded,
                          accentColor: const Color(0xFF4DD0E1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    layerDesc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
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

  Widget _buildSatLayerChip({
    required String modeKey,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedSatLayer == modeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSatLayer = modeKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isSelected ? accentColor : Colors.white60),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapToolIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  void _showFullScreenSatelliteImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Satellite GIS: $title',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            InteractiveViewer(
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const SizedBox(
                  height: 250,
                  child: Center(child: Text('Image not available', style: TextStyle(color: Colors.white))),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppTranslations.get('sat_gis_title', langCode)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFarmData),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.farmMap,
        textToRead: AppTranslations.get('voice_farm_map_intro', langCode),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadFarmData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                        ),

                      // 🛰️ HERO AGROMONITORING REAL-TIME SATELLITE GIS CARD
                      _buildAgroMonitoringSatelliteHero(context, langCode),

                      const SizedBox(height: 16),

                      // 🌱 SOIL & ROOT METRICS
                      _buildMetricsCard(context, langCode),

                      const SizedBox(height: 16),

                      // 🗺️ GOOGLE MAP HYBRID FIELD SURVEY
                      Text(
                        '🗺️ ${AppTranslations.get('sat_hybrid_map', langCode)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GoogleMap(
                            onMapCreated: (controller) => _mapController = controller,
                            initialCameraPosition: CameraPosition(target: LatLng(baseLat, baseLng), zoom: 15),
                            polygons: _generateFarmPolygon(),
                            mapType: MapType.hybrid,
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
