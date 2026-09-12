import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/farming_domain.dart';
import '../providers/farming_domain_provider.dart';
import '../widgets/domain_selector_sheet.dart';
import 'market_screen.dart';
import 'crop_health_screen.dart';
import 'assistant_screen.dart';
import 'yield_profit_screen.dart';
import 'contracts_screen.dart';
import 'schemes_screen.dart';
import 'risk_alerts_screen.dart';
import 'farm_map_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'crop_screen.dart';
import 'water_mediation_screen.dart';
import '../widgets/voice_wrapper.dart';
import '../services/notification_polling_service.dart';
import '../widgets/home/live_stats_ticker.dart';
import '../widgets/home/features_showcase_slider.dart';
import '../utils/app_translations.dart';
import '../providers/locale_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  NotificationPollingService? _pollingService;
  int _currentNavIndex = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    final box = Hive.box('profileBox');
    final name = box.get('name', defaultValue: '') as String;
    if (name.isNotEmpty) {
      _pollingService = NotificationPollingService(
        role: 'farmer',
        name: name,
        pollInterval: const Duration(seconds: 30),
      )..start();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pollingService?.stop();
    super.dispose();
  }

  String _getTimeBasedGreeting(String langCode) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppTranslations.get('greeting_morning', langCode);
    } else if (hour < 17) {
      return AppTranslations.get('greeting_afternoon', langCode);
    } else {
      return AppTranslations.get('greeting_evening', langCode);
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FarmMapScreen()),
        ).then((_) => setState(() => _currentNavIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
        ).then((_) => setState(() => _currentNavIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiskAlertsScreen()),
        ).then((_) => setState(() => _currentNavIndex = 0));
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) => setState(() => _currentNavIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final box = Hive.box('profileBox');
    final farmerName = box.get('name', defaultValue: '') as String;
    final displayName = farmerName.isNotEmpty ? farmerName : 'Farmer';
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;

    final domainProvider = context.watch<FarmingDomainProvider>();
    final currentDomain = domainProvider.currentDomainInfo;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: VoiceWrapper(
        screenTitle: l10n.homeDashboard,
        textToRead: AppTranslations.get('voice_home_intro', langCode),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🌿 1. TOP APP BAR & BRANDING (Screen 1 Match)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: _buildScreen1TopBar(context, currentDomain),
                  ),
                ),

                // 🌅 2. GREETING & GENTLE TAGLINE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTimeBasedGreeting(langCode),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF556B55),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '$displayName!',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B381E),
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('🌱', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppTranslations.get('tagline_healthy_farms', langCode),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A8E7A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 📊 3. TELEMETRY QUICK PILLS ROW (Screen 1: Weather, Moisture, Crop Health)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTelemetryPillsRow(context, langCode),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),

                // 🌟 4. PROJECT FEATURES SHOWCASE SLIDER (Auto-slides left every 2 seconds)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: FeaturesShowcaseSlider(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // ⚡ 5. THE 6 PRIMARY SERVICE ACTION CARDS (Screen 1 3x2 Grid)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppTranslations.get('smart_farm_services', langCode),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B381E),
                                letterSpacing: -0.3,
                              ),
                            ),
                            InkWell(
                              onTap: () => DomainSelectorSheet.show(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Text(
                                  '${currentDomain.title} ▾',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildScreen1ServiceGrid(context, langCode),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 📈 6. LIVE APMC MANDI & AGRO CLIMATE TICKER
                SliverToBoxAdapter(
                  child: LiveStatsTicker(
                    items: [
                      AppTranslations.get('ticker_market_tomato', langCode),
                      AppTranslations.get('ticker_weather_clear', langCode),
                      AppTranslations.get('ticker_subsidy_drip', langCode),
                      AppTranslations.get('ticker_canal_flow', langCode),
                      '${currentDomain.title}: ${AppTranslations.get('ticker_iot_online', langCode)}',
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // 🌾 7. SPECIALIZED DOMAIN SUITE SPOTLIGHT
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDomainSpotlightCard(context, currentDomain),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
      // 📱 8. NATIVE SCREEN 1 BOTTOM NAVIGATION BAR
      bottomNavigationBar: _buildScreen1BottomNavBar(context, langCode),
    );
  }

  /// Top Bar with Logo, Brand title, Subtitle, Domain Pill, Notifications, & Profile Avatar
  Widget _buildScreen1TopBar(BuildContext context, FarmingDomainInfo currentDomain) {
    return Row(
      children: [
        // Sprout / App Brand Icon
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC8E6C9)),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.eco_rounded,
              color: Color(0xFF2E7D32),
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Brand Name & Subtitle (Screen 1 Match)
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AgriNova',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              Text(
                'Smarter Agriculture, Brighter Farmers',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF68836B),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // Notifications Bell with active ping badge
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF2E5933),
                size: 24,
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Profile Avatar with online green ring badge (Screen 1 Match)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1.8),
                ),
                child: const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFFC8E6C9),
                  child: Icon(Icons.person_rounded, color: Color(0xFF1B5E20), size: 20),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3 Telemetry Quick Status Pills (Screen 1: Weather, Soil Moisture, Crop Health)
  Widget _buildTelemetryPillsRow(BuildContext context, String langCode) {
    return Row(
      children: [
        // 1. Weather: Sunny, 28°C / Local Farm
        Expanded(
          child: _buildTelemetryCard(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFFFA000),
            iconBg: const Color(0xFFFFF8E1),
            value: AppTranslations.get('telemetry_sunny', langCode),
            label: AppTranslations.get('telemetry_local_farm', langCode),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RiskAlertsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // 2. Soil Moisture: Optimal 62% / Root H2O
        Expanded(
          child: _buildTelemetryCard(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0288D1),
            iconBg: const Color(0xFFE1F5FE),
            value: AppTranslations.get('telemetry_optimal', langCode),
            label: AppTranslations.get('telemetry_root_moisture', langCode),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FarmMapScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),

        // 3. Crop Health: 94% Vigorous / Crop Health
        Expanded(
          child: _buildTelemetryCard(
            icon: Icons.eco_rounded,
            iconColor: const Color(0xFF388E3C),
            iconBg: const Color(0xFFE8F5E9),
            value: AppTranslations.get('telemetry_vigorous', langCode),
            label: AppTranslations.get('telemetry_crop_health', langCode),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CropHealthScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EFE8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2D1F),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF718272),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 6 Service Cards Grid (Screen 1: Jala-Mitra, Crop Advisor, Weather Alerts, Disease Detection, Market Prices, Govt Schemes)
  Widget _buildScreen1ServiceGrid(BuildContext context, String langCode) {
    return Column(
      children: [
        // Row 1: Jala-Mitra, Crop Advisor, Weather Alerts
        Row(
          children: [
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('service_jala_mitra_title', langCode),
                subtitle: AppTranslations.get('service_jala_mitra_sub', langCode),
                icon: Icons.water_drop_rounded,
                themeColor: const Color(0xFF00796B),
                cardBg: const Color(0xFFE0F2F1),
                badgeText: AppTranslations.get('service_jala_mitra_badge', langCode),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WaterMediationScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('service_crop_advisor_title', langCode),
                subtitle: AppTranslations.get('service_crop_advisor_sub', langCode),
                icon: Icons.grass_rounded,
                themeColor: const Color(0xFF2E7D32),
                cardBg: const Color(0xFFE8F5E9),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CropScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('service_weather_alerts_title', langCode),
                subtitle: AppTranslations.get('service_weather_alerts_sub', langCode),
                icon: Icons.thunderstorm_rounded,
                themeColor: const Color(0xFF0288D1),
                cardBg: const Color(0xFFE1F5FE),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiskAlertsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Disease Detection, Market Prices, Govt Schemes
        Row(
          children: [
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('service_disease_detect_title', langCode),
                subtitle: AppTranslations.get('service_disease_detect_sub', langCode),
                icon: Icons.biotech_rounded,
                themeColor: const Color(0xFFD32F2F),
                cardBg: const Color(0xFFFFEBEE),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CropHealthScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('service_market_prices_title', langCode),
                subtitle: AppTranslations.get('service_market_prices_sub', langCode),
                icon: Icons.trending_up_rounded,
                themeColor: const Color(0xFF7B1FA2),
                cardBg: const Color(0xFFF3E5F5),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('service_govt_schemes_title', langCode),
                subtitle: AppTranslations.get('service_govt_schemes_sub', langCode),
                icon: Icons.account_balance_rounded,
                themeColor: const Color(0xFF303F9F),
                cardBg: const Color(0xFFE8EAF6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchemesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Yield Profit Prediction, Contractors & Services, Ask AgriNova
        Row(
          children: [
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('slide_yield_profit_title', langCode),
                subtitle: AppTranslations.get('slide_yield_profit_sub', langCode),
                icon: Icons.monetization_on_rounded,
                themeColor: const Color(0xFFF57F17),
                cardBg: const Color(0xFFFFF8E1),
                badgeText: AppTranslations.get('slide_yield_profit_badge', langCode),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const YieldProfitScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('slide_contractors_title', langCode),
                subtitle: AppTranslations.get('slide_contractors_sub', langCode),
                icon: Icons.handshake_rounded,
                themeColor: const Color(0xFF1E88E5),
                cardBg: const Color(0xFFE3F2FD),
                badgeText: AppTranslations.get('slide_contractors_badge', langCode),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContractsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceActionCard(
                title: AppTranslations.get('slide_agrinova_title', langCode),
                subtitle: AppTranslations.get('slide_agrinova_sub', langCode),
                icon: Icons.auto_awesome_rounded,
                themeColor: const Color(0xFF00897B),
                cardBg: const Color(0xFFE0F2F1),
                badgeText: AppTranslations.get('slide_agrinova_badge', langCode),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color themeColor,
    required Color cardBg,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EFE8)),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: themeColor, size: 20),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2D1F),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Specialized Domain Hub Spotlight (Dairy, Poultry, Aquaculture, etc.)
  Widget _buildDomainSpotlightCard(BuildContext context, FarmingDomainInfo domain) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: domain.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              domain.primaryColor.withValues(alpha: 0.08),
              domain.secondaryColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: domain.primaryColor,
                  radius: 17,
                  child: Icon(domain.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${domain.title} Hub',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B381E),
                        ),
                      ),
                      Text(
                        domain.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToDomainScreen(context, domain.type),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: domain.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(60, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Open Hub', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: domain.keyFeatures
                  .take(4)
                  .map(
                    (feat) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: domain.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '✓ $feat',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: domain.primaryColor,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen 1 Native Bottom Navigation Bar (Home, Explore, Chat, Alerts, Profile)
  Widget _buildScreen1BottomNavBar(BuildContext context, String langCode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8EFE8), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, AppTranslations.get('nav_home', langCode)),
              _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, AppTranslations.get('nav_explore', langCode)),
              _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, AppTranslations.get('nav_chat', langCode)),
              _buildNavItem(3, Icons.notifications_rounded, Icons.notifications_none_rounded, AppTranslations.get('nav_alerts', langCode)),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, AppTranslations.get('nav_profile', langCode)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () => _onBottomNavTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 22,
              color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF8D9A8D),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF8D9A8D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDomainScreen(BuildContext context, FarmingDomainType type) {
    switch (type) {
      case FarmingDomainType.crops:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CropScreen()),
        );
        break;
      case FarmingDomainType.dairyLivestock:
        Navigator.pushNamed(context, '/dairy');
        break;
      case FarmingDomainType.poultry:
        Navigator.pushNamed(context, '/poultry');
        break;
      case FarmingDomainType.aquaculture:
        Navigator.pushNamed(context, '/aquaculture');
        break;
      case FarmingDomainType.hydroponics:
      case FarmingDomainType.organicNatural:
        Navigator.pushNamed(context, '/organic');
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CropScreen()),
        );
        break;
    }
  }
}
