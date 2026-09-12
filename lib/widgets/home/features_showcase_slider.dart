import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/yield_profit_screen.dart';
import '../../screens/labour_screen.dart';
import '../../screens/risk_alerts_screen.dart';
import '../../screens/assistant_screen.dart';
import '../../screens/crop_health_screen.dart';
import '../../screens/water_mediation_screen.dart';
import '../../screens/market_screen.dart';
import '../../providers/locale_provider.dart';
import '../../utils/app_translations.dart';

/// Data model for each feature slide in the dashboard showcase.
class _FeatureSlideItem {
  final String titleKey;
  final String subKey;
  final String badgeKey;
  final String assetPath;
  final Color accentColor;
  final IconData icon;
  final Widget Function(BuildContext) screenBuilder;

  const _FeatureSlideItem({
    required this.titleKey,
    required this.subKey,
    required this.badgeKey,
    required this.assetPath,
    required this.accentColor,
    required this.icon,
    required this.screenBuilder,
  });
}

class FeaturesShowcaseSlider extends StatefulWidget {
  const FeaturesShowcaseSlider({super.key});

  @override
  State<FeaturesShowcaseSlider> createState() => _FeaturesShowcaseSliderState();
}

class _FeaturesShowcaseSliderState extends State<FeaturesShowcaseSlider> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentIndex = 0;
  bool _isUserInteracting = false;

  late final List<_FeatureSlideItem> _features;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);

    _features = [
      _FeatureSlideItem(
        titleKey: 'slide_yield_profit_title',
        subKey: 'slide_yield_profit_sub',
        badgeKey: 'slide_yield_profit_badge',
        assetPath: 'assets/features/feature_yield_profit.jpg',
        accentColor: const Color(0xFFFFB300),
        icon: Icons.trending_up_rounded,
        screenBuilder: (_) => const YieldProfitScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_contractors_title',
        subKey: 'slide_contractors_sub',
        badgeKey: 'slide_contractors_badge',
        assetPath: 'assets/features/feature_contractors_services.jpg',
        accentColor: const Color(0xFF43A047),
        icon: Icons.agriculture_rounded,
        screenBuilder: (_) => const LabourScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_risk_alerts_title',
        subKey: 'slide_risk_alerts_sub',
        badgeKey: 'slide_risk_alerts_badge',
        assetPath: 'assets/features/feature_risk_alerts.jpg',
        accentColor: const Color(0xFFE53935),
        icon: Icons.warning_amber_rounded,
        screenBuilder: (_) => const RiskAlertsScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_agrinova_title',
        subKey: 'slide_agrinova_sub',
        badgeKey: 'slide_agrinova_badge',
        assetPath: 'assets/features/feature_ask_agrinova.jpg',
        accentColor: const Color(0xFF00ACC1),
        icon: Icons.smart_toy_rounded,
        screenBuilder: (_) => const AIAssistantScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_crop_health_title',
        subKey: 'slide_crop_health_sub',
        badgeKey: 'slide_crop_health_badge',
        assetPath: 'assets/features/feature_crop_ai.jpg',
        accentColor: const Color(0xFF00E676),
        icon: Icons.biotech_rounded,
        screenBuilder: (_) => const CropHealthScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_water_sharing_title',
        subKey: 'slide_water_sharing_sub',
        badgeKey: 'slide_water_sharing_badge',
        assetPath: 'assets/features/feature_water_sharing.jpg',
        accentColor: const Color(0xFF0288D1),
        icon: Icons.water_drop_rounded,
        screenBuilder: (_) => const WaterMediationScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_mandi_title',
        subKey: 'slide_mandi_sub',
        badgeKey: 'slide_mandi_badge',
        assetPath: 'assets/features/feature_mandi_market.jpg',
        accentColor: const Color(0xFF8E24AA),
        icon: Icons.storefront_rounded,
        screenBuilder: (_) => const MarketScreen(),
      ),
      _FeatureSlideItem(
        titleKey: 'slide_weather_radar_title',
        subKey: 'slide_weather_radar_sub',
        badgeKey: 'slide_weather_radar_badge',
        assetPath: 'assets/features/feature_agro_weather.jpg',
        accentColor: const Color(0xFF3949AB),
        icon: Icons.radar_rounded,
        screenBuilder: (_) => const RiskAlertsScreen(),
      ),
    ];

    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    // Slides towards the left each by each with 2 seconds interval
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_isUserInteracting && _pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % _features.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context, _FeatureSlideItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: item.screenBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Listener(
          onPointerDown: (_) {
            setState(() => _isUserInteracting = true);
            _autoSlideTimer?.cancel();
          },
          onPointerUp: (_) {
            setState(() => _isUserInteracting = false);
            _startAutoSlideTimer();
          },
          onPointerCancel: (_) {
            setState(() => _isUserInteracting = false);
            _startAutoSlideTimer();
          },
          child: Stack(
            children: [
              // 1. Sliding PageView (Slides towards left every 2 seconds)
              PageView.builder(
                controller: _pageController,
                itemCount: _features.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = _features[index];
                  return _buildSlideCard(context, item);
                },
              ),

              // 2. Animated Dot Page Indicators at bottom right
              Positioned(
                bottom: 14,
                right: 18,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_features.length, (idx) {
                    final isActive = idx == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: 5,
                      width: isActive ? 20 : 5,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _features[_currentIndex].accentColor
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
              ),

              // 3. Mini Auto-Tour Pill at top right
              Positioned(
                top: 14,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _features[_currentIndex].accentColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_currentIndex + 1}/${_features.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideCard(BuildContext context, _FeatureSlideItem item) {
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;
    final title = AppTranslations.get(item.titleKey, langCode);
    final subtitle = AppTranslations.get(item.subKey, langCode);
    final badge = AppTranslations.get(item.badgeKey, langCode);
    final openText = AppTranslations.get('open_feature', langCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context, item),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Generated High-Resolution Feature Image
            Image.asset(
              item.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1B381E),
                  child: Center(
                    child: Icon(item.icon, size: 54, color: item.accentColor),
                  ),
                );
              },
            ),

            // Subtle Vignette & Contrast Gradients for crystal-clear readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Top Badge Pill
            Positioned(
              top: 14,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.accentColor.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.accentColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: item.accentColor, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      badge,
                      style: TextStyle(
                        color: item.accentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Content Overlay (Title, Subtitle, & Open CTA)
            Positioned(
              left: 16,
              right: 80,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 6,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.accentColor.withValues(alpha: 0.9),
                          item.accentColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: item.accentColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          openText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ],
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
}
