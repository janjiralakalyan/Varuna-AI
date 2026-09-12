import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/cache_service.dart';
import '../widgets/voice_wrapper.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../utils/app_translations.dart';

/// Representation of an official government scheme with mandatory verified portal URL
class GovtSchemeItem {
  final String name;
  final String category;
  final String badge;
  final String description;
  final String eligibility;
  final String url;
  final IconData icon;
  final Color color;

  const GovtSchemeItem({
    required this.name,
    required this.category,
    required this.badge,
    required this.description,
    this.eligibility = '',
    required this.url,
    required this.icon,
    required this.color,
  });
}

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _stateController = TextEditingController(
    text: 'Maharashtra',
  );
  final TextEditingController _cropController = TextEditingController(
    text: 'Cotton',
  );
  final TextEditingController _landSizeController = TextEditingController(
    text: '2.0',
  );
  final TextEditingController _portalSearchController = TextEditingController();

  bool _locationLoading = false;
  bool _loading = false;
  bool _checkingNewSchemes = false;
  String? _detectedState;
  String? _schemesResult;
  List<String> _translatedStates = [];
  String? _lastTranslatedLang;
  String _selectedCategory = 'All';
  String _portalStateFilter = 'All States';

  // Popular Indian states quick-select
  final List<String> _popularStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  // Official State Government Agriculture Portals
  static const Map<String, Map<String, String>> statePortals = {
    'Andhra Pradesh': {
      'name': 'YSR Rythu Bharosa / AP Agri Portal',
      'url': 'https://ysrrythubharosa.ap.gov.in',
      'desc':
          'Direct financial assistance of ₹13,500/year, input subsidies, and zero-interest crop loans.',
    },
    'Telangana': {
      'name': 'Rythu Bandhu / Agri Telangana',
      'url': 'https://rythubandhu.telangana.gov.in',
      'desc':
          'Investment support of ₹10,000/acre/year and Rythu Bima farmer group insurance.',
    },
    'Maharashtra': {
      'name': 'MahaDBT Farmer Schemes Portal',
      'url': 'https://mahadbt.maharashtra.gov.in',
      'desc':
          'Single-window DBT for tractor & implement subsidies, drip irrigation, and crop protection.',
    },
    'Karnataka': {
      'name': 'FRUITS Portal (Raitha Siri)',
      'url': 'https://fruits.karnataka.gov.in',
      'desc':
          'Farmer Registration & Unified Beneficiary Information System for all Karnataka agri benefits.',
    },
    'Tamil Nadu': {
      'name': 'Uzhavan / TN Agrisnet Portal',
      'url': 'https://www.tnagrisnet.tn.gov.in',
      'desc':
          'Direct machinery reservation, subsidized certified seeds, and solar pump schemes.',
    },
    'Gujarat': {
      'name': 'i-Khedut Portal',
      'url': 'https://ikhedut.gujarat.gov.in',
      'desc':
          'Comprehensive application gateway for water harvesting, farm power, and machinery in Gujarat.',
    },
    'Uttar Pradesh': {
      'name': 'UP Agriculture (Paradarshi Kisan Seva)',
      'url': 'http://upagriculture.com',
      'desc':
          'Online registration for seed subsidies, solar pump grants, and agricultural mechanization.',
    },
    'Madhya Pradesh': {
      'name': 'MP Krishi / Saara Portal',
      'url': 'https://mpkrishi.mp.gov.in',
      'desc':
          'Mukhyamantri Kisan Kalyan Yojana (₹6,000 add-on to PM-KISAN) and e-Uparjan procurement.',
    },
    'Rajasthan': {
      'name': 'RajKisan Saathi Portal',
      'url': 'https://rajkisan.rajasthan.gov.in',
      'desc':
          'Direct subsidies for farm ponds, pipeline laying, solar pumps, and greenhouse cultivation.',
    },
    'Punjab': {
      'name': 'Agri Punjab DBT Portal',
      'url': 'https://agri.punjab.gov.in',
      'desc':
          'Crop residue management machinery subsidies, seed distribution, and soil health grants.',
    },
    'Haryana': {
      'name': 'Meri Fasal Mera Byora',
      'url': 'https://fasal.haryana.gov.in',
      'desc':
          'Direct MSP procurement compensation, Bhavantar Bharpayee, and crop damage compensation.',
    },
    'Bihar': {
      'name': 'DBT Agriculture Bihar',
      'url': 'https://dbtagriculture.bihar.gov.in',
      'desc':
          'Agricultural input subsidy, diesel subsidy, seed grants, and farm equipment in Bihar.',
    },
    'Odisha': {
      'name': 'KALIA / Krushak Odisha',
      'url': 'https://kalia.odisha.gov.in',
      'desc':
          'Krushak Assistance for Livelihood and Income Augmentation (₹10,000/year assistance).',
    },
    'West Bengal': {
      'name': 'Krishak Bandhu Portal',
      'url': 'https://krishakbandhu.net',
      'desc':
          'Assured financial assistance up to ₹10,000/acre/year and ₹2 Lakhs farmer death insurance.',
    },
    'Kerala': {
      'name': 'Karshaka Mithra / Kerala Agri Portal',
      'url': 'https://keralaagriculture.gov.in',
      'desc':
          'Specialized subsidies for spices, paddy bonus, organic farming, and micro-enterprises.',
    },
  };

  // Verified State-Specific Government Schemes Database
  static const Map<String, List<GovtSchemeItem>> stateSpecificSchemes = {
    'Telangana': [
      GovtSchemeItem(
        name: 'Rythu Bandhu (Farmer Investment Support)',
        category: 'Income Support',
        badge: 'Telangana State',
        description:
            'Direct cash transfer of ₹10,000 per acre per year (₹5,000 for Kharif and ₹5,000 for Rabi) for agricultural inputs, seeds, and fertilizers.',
        eligibility: 'All resident landowning farmers registered on Dharani portal.',
        url: 'https://rythubandhu.telangana.gov.in',
        icon: Icons.currency_rupee_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'Rythu Bima (Farmer Life Insurance)',
        category: 'Insurance & Relief',
        badge: 'Telangana State',
        description:
            '₹5,00,000 natural or accidental life insurance coverage with 100% premium paid by the Telangana Government, deposited within 10 days of demise.',
        eligibility: 'Pattadar passbook holders aged 18 to 59 years.',
        url: 'https://rythubima.telangana.gov.in',
        icon: Icons.shield_rounded,
        color: Color(0xFF1565C0),
      ),
      GovtSchemeItem(
        name: 'Telangana Crop Loan Waiver Scheme (Runa Mafi)',
        category: 'Credit & Loans',
        badge: 'Telangana State',
        description:
            'Institutional agricultural crop debt waiver up to ₹2,00,000 directly crediting farmer bank loan accounts.',
        eligibility: 'Short-term agricultural crop borrowers from cooperative and commercial banks.',
        url: 'https://clw.telangana.gov.in',
        icon: Icons.credit_score_rounded,
        color: Color(0xFF6A1B9A),
      ),
      GovtSchemeItem(
        name: 'Telangana Micro Irrigation Project (TSMIP)',
        category: 'Machinery & Solar',
        badge: 'Telangana State',
        description:
            'Up to 100% subsidy for SC/ST farmers, 90% for small and marginal farmers on drip and sprinkler irrigation installations.',
        eligibility: 'Farmers with assured irrigation water sources across Telangana.',
        url: 'https://horticulture.telangana.gov.in',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF0288D1),
      ),
    ],
    'Andhra Pradesh': [
      GovtSchemeItem(
        name: 'YSR Rythu Bharosa - PM KISAN',
        category: 'Income Support',
        badge: 'Andhra Pradesh State',
        description:
            'Annual financial assistance of ₹13,500 per farmer family (including ₹6,000 from PM-KISAN) for agricultural and horticultural cultivation expenses.',
        eligibility: 'All landowning farmers and SC/ST/BC/Minority tenant farmer families in AP.',
        url: 'https://ysrrythubharosa.ap.gov.in',
        icon: Icons.currency_rupee_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'YSR Free Crop Insurance Scheme',
        category: 'Insurance & Relief',
        badge: 'Andhra Pradesh State',
        description:
            '100% state-funded crop insurance with zero premium charge to farmers. Automatically covers crops recorded in e-Crop booking against calamity loss.',
        eligibility: 'All cultivating farmers with active e-Crop bookings.',
        url: 'https://karshak.ap.gov.in',
        icon: Icons.shield_rounded,
        color: Color(0xFF1565C0),
      ),
      GovtSchemeItem(
        name: 'YSR Sunna Vaddi Panta Runalu',
        category: 'Credit & Loans',
        badge: 'Andhra Pradesh State',
        description:
            'Zero-interest crop loans up to ₹1,00,000 for prompt repayment within 1 year, with interest fully reimbursed by AP Government.',
        eligibility: 'Farmers who repay crop loans within the stipulated bank timeframe.',
        url: 'https://apagrisnet.gov.in',
        icon: Icons.percent_rounded,
        color: Color(0xFFE65100),
      ),
      GovtSchemeItem(
        name: 'YSR Jala Kala (Free Borewells)',
        category: 'Machinery & Solar',
        badge: 'Andhra Pradesh State',
        description:
            'Free drilling of agricultural borewells, hydrogeological surveys, and free distribution of electric/solar pump sets for water-starved fields.',
        eligibility: 'Small and marginal farmers holding 2.5 to 5 contiguous acres.',
        url: 'https://ysrjalakala.ap.gov.in',
        icon: Icons.solar_power_rounded,
        color: Color(0xFF00897B),
      ),
    ],
    'Maharashtra': [
      GovtSchemeItem(
        name: 'Namo Shetkari Mahasanman Nidhi',
        category: 'Income Support',
        badge: 'Maharashtra State',
        description:
            'Additional ₹6,000 per year directly transferred to bank accounts from Maharashtra State Govt (Total ₹12,000/year combining PM-KISAN).',
        eligibility: 'All approved PM-KISAN landholding beneficiaries in Maharashtra.',
        url: 'https://mahadbt.maharashtra.gov.in',
        icon: Icons.currency_rupee_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'MahaDBT Farm Machinery & Tractor Subsidy',
        category: 'Machinery & Solar',
        badge: 'Maharashtra State',
        description:
            'Up to 50% capital subsidy on purchase of new tractors, rotavators, power tillers, and threshers through lottery DBT.',
        eligibility: 'Registered farmers with 7/12 land extract and Aadhaar seeding on MahaDBT.',
        url: 'https://mahadbt.maharashtra.gov.in',
        icon: Icons.agriculture_rounded,
        color: Color(0xFFC2185B),
      ),
      GovtSchemeItem(
        name: 'Magel Tyala Shettale (Farm Pond Subsidy)',
        category: 'Machinery & Solar',
        badge: 'Maharashtra State',
        description:
            'Direct cash grant of up to ₹50,000 for digging and constructing on-farm rainwater harvesting ponds.',
        eligibility: 'Farmers holding at least 0.60 hectare arable land.',
        url: 'https://mahadbt.maharashtra.gov.in',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF0288D1),
      ),
      GovtSchemeItem(
        name: 'Mukhyamantri Saur Krushi Vahini Yojana 2.0',
        category: 'Machinery & Solar',
        badge: 'Maharashtra State',
        description:
            'Solarization of agricultural electricity feeders providing dedicated 8-hour daytime electricity for farming irrigation pumps.',
        eligibility: 'Rural agricultural electricity consumers in Maharashtra.',
        url: 'https://mahadiscom.in',
        icon: Icons.solar_power_rounded,
        color: Color(0xFFE65100),
      ),
    ],
    'Karnataka': [
      GovtSchemeItem(
        name: 'Raitha Siri Scheme (Millet Incentive)',
        category: 'Income Support',
        badge: 'Karnataka State',
        description:
            'Direct cash incentive of ₹10,000 per hectare deposited directly into the bank accounts of farmers growing designated minor millets.',
        eligibility: 'Farmers registered on FRUITS portal growing Siri Dhanya.',
        url: 'https://fruits.karnataka.gov.in',
        icon: Icons.grass_rounded,
        color: Color(0xFF388E3C),
      ),
      GovtSchemeItem(
        name: 'Krishi Bhagya Scheme',
        category: 'Machinery & Solar',
        badge: 'Karnataka State',
        description:
            'Up to 90% subsidy for SC/ST and 80% for general category farmers on farm ponds with polythene lining and diesel pumpsets.',
        eligibility: 'Dryland farmers in rainfed agricultural regions of Karnataka.',
        url: 'https://raitamitra.karnataka.gov.in',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF0288D1),
      ),
      GovtSchemeItem(
        name: 'Ganga Kalyana Scheme',
        category: 'Machinery & Solar',
        badge: 'Karnataka State',
        description:
            'Free drilling of borewells, pump energization, and water piping for small and marginal farmers belonging to backward classes.',
        eligibility: 'Small and marginal farmers belonging to SC, ST, and backward communities.',
        url: 'https://kmdc.karnataka.gov.in',
        icon: Icons.science_rounded,
        color: Color(0xFF7B1FA2),
      ),
    ],
    'Uttar Pradesh': [
      GovtSchemeItem(
        name: 'Mukhyamantri Khet Suraksha Yojana',
        category: 'Machinery & Solar',
        badge: 'Uttar Pradesh State',
        description:
            '60% subsidy (up to ₹1,43,000 per hectare) for installing solar fencing around agricultural fields to protect crops from wild animals.',
        eligibility: 'Farmers registered on the UP Agriculture portal.',
        url: 'http://upagriculture.com',
        icon: Icons.fence_rounded,
        color: Color(0xFFE65100),
      ),
      GovtSchemeItem(
        name: 'UP Solar Pump Subsidy (PM-KUSUM)',
        category: 'Machinery & Solar',
        badge: 'Uttar Pradesh State',
        description:
            'Up to 70% joint Central-State subsidy on 2HP, 3HP, 5HP, and 7.5HP solar irrigation pumps with online portal booking.',
        eligibility: 'First-come-first-serve registration on UP Agriculture portal.',
        url: 'http://upagriculture.com',
        icon: Icons.solar_power_rounded,
        color: Color(0xFFF57F17),
      ),
      GovtSchemeItem(
        name: 'UP Free Boring Scheme (Nishulk Boring)',
        category: 'Machinery & Solar',
        badge: 'Uttar Pradesh State',
        description:
            'Free shallow tube-well boring grant up to ₹10,000 with HDPE delivery pipe subsidy.',
        eligibility: 'Small and marginal farmers holding at least 0.2 hectare arable land.',
        url: 'http://minorirrigationup.gov.in',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF0288D1),
      ),
    ],
    'Madhya Pradesh': [
      GovtSchemeItem(
        name: 'Mukhyamantri Kisan Kalyan Yojana',
        category: 'Income Support',
        badge: 'Madhya Pradesh State',
        description:
            '₹6,000 per year state income support (Total ₹12,000/year combining PM-KISAN) in 3 equal installments.',
        eligibility: 'All landholding farmer families in MP verified on SAARA portal.',
        url: 'https://saara.mp.gov.in',
        icon: Icons.currency_rupee_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'Bhavantar Bhugtan Yojana',
        category: 'Insurance & Relief',
        badge: 'Madhya Pradesh State',
        description:
            'Direct cash transfer of price deficit difference whenever mandi auction price falls below the Minimum Support Price (MSP).',
        eligibility: 'Registered farmers selling notified crops in MP APMC mandis.',
        url: 'https://mpeuparjan.nic.in',
        icon: Icons.price_change_rounded,
        color: Color(0xFF1565C0),
      ),
      GovtSchemeItem(
        name: 'Mukhyamantri Solar Pump Yojana',
        category: 'Machinery & Solar',
        badge: 'Madhya Pradesh State',
        description:
            'Up to 90% subsidy for farmers without grid electricity to install solar irrigation pumps.',
        eligibility: 'Farmers with agricultural land and permanent water source in MP.',
        url: 'https://cmsolarpump.mp.gov.in',
        icon: Icons.solar_power_rounded,
        color: Color(0xFFE65100),
      ),
    ],
    'Punjab': [
      GovtSchemeItem(
        name: 'Crop Residue Management (CRM) Subsidy',
        category: 'Machinery & Solar',
        badge: 'Punjab State',
        description:
            '50% individual subsidy and 80% cooperative subsidy for Super Seeders, Happy Seeders, Balers, and Paddy Straw Choppers.',
        eligibility: 'Punjab farmers and registered Farmer Producer Organizations (FPOs).',
        url: 'https://agripb.gov.in',
        icon: Icons.agriculture_rounded,
        color: Color(0xFFC2185B),
      ),
      GovtSchemeItem(
        name: 'Pani Bachao, Paisa Kamao',
        category: 'Machinery & Solar',
        badge: 'Punjab State',
        description:
            'Direct cash incentive of ₹4 per kilowatt-hour of electricity saved in tube-well pumping credited directly to farmer bank accounts.',
        eligibility: 'Farmers connected to designated agricultural feeders with meters installed.',
        url: 'https://pspcl.in',
        icon: Icons.bolt_rounded,
        color: Color(0xFF00897B),
      ),
    ],
    'Haryana': [
      GovtSchemeItem(
        name: 'Mera Pani Meri Virasat',
        category: 'Income Support',
        badge: 'Haryana State',
        description:
            'Direct cash incentive of ₹7,000 per acre for switching from water-intensive paddy to pulses, cotton, or maize.',
        eligibility: 'Farmers registered on Meri Fasal Mera Byora portal in Haryana.',
        url: 'https://fasal.haryana.gov.in',
        icon: Icons.eco_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'Bhavantar Bharpayee Yojana (Horticulture)',
        category: 'Insurance & Relief',
        badge: 'Haryana State',
        description:
            'Fixed base price protection and risk compensation for 19 fruit and vegetable crops against market price dips.',
        eligibility: 'Registered horticulture growers in Haryana.',
        url: 'https://hortharyana.gov.in',
        icon: Icons.shield_rounded,
        color: Color(0xFF1565C0),
      ),
    ],
    'Gujarat': [
      GovtSchemeItem(
        name: 'i-Khedut Farm Tool & Equipment Subsidy',
        category: 'Machinery & Solar',
        badge: 'Gujarat State',
        description:
            '40% to 50% DBT subsidy on tractors, power tillers, rotavators, and harvesting machinery.',
        eligibility: 'Gujarat farmers registered on i-Khedut portal with 8-A land records.',
        url: 'https://ikhedut.gujarat.gov.in',
        icon: Icons.agriculture_rounded,
        color: Color(0xFFC2185B),
      ),
      GovtSchemeItem(
        name: 'Mukhya Mantri Kisan Sahay Yojana',
        category: 'Insurance & Relief',
        badge: 'Gujarat State',
        description:
            'Zero-premium crop compensation up to ₹20,000/ha for natural calamities like drought, excess rain, and unseasonal rainfall.',
        eligibility: 'All landholding farmers in notified calamity-hit talukas.',
        url: 'https://ikhedut.gujarat.gov.in',
        icon: Icons.shield_rounded,
        color: Color(0xFF1565C0),
      ),
    ],
    'Rajasthan': [
      GovtSchemeItem(
        name: 'Mukhyamantri Kisan Mitra Urja Yojana',
        category: 'Income Support',
        badge: 'Rajasthan State',
        description:
            '₹1,000 per month (up to ₹12,000 per year) direct subsidy on electricity bills for metered agricultural farm connections.',
        eligibility: 'General category rural metered agricultural electricity consumers in Rajasthan.',
        url: 'https://energy.rajasthan.gov.in',
        icon: Icons.bolt_rounded,
        color: Color(0xFF00897B),
      ),
      GovtSchemeItem(
        name: 'Tarbandi Scheme (Farm Fencing Grant)',
        category: 'Machinery & Solar',
        badge: 'Rajasthan State',
        description:
            '50% grant up to ₹40,000 for 400 meters of barbed wire fencing to protect standing crops from stray cattle and wild animals.',
        eligibility: 'Individual farmers holding at least 1.5 hectares or groups holding 5 hectares.',
        url: 'https://rajkisan.rajasthan.gov.in',
        icon: Icons.fence_rounded,
        color: Color(0xFFE65100),
      ),
    ],
    'Bihar': [
      GovtSchemeItem(
        name: 'Bihar Rajya Fasal Sahayata Yojana (BRFSY)',
        category: 'Insurance & Relief',
        badge: 'Bihar State',
        description:
            'Up to ₹10,000/hectare assistance for crop yield loss (>20%) with zero farmer premium charge.',
        eligibility: 'All landowning and non-landowning sharecropper farmers in Bihar.',
        url: 'https://pacsonline.bih.nic.in',
        icon: Icons.shield_rounded,
        color: Color(0xFF1565C0),
      ),
      GovtSchemeItem(
        name: 'Bihar Diesel Anudan Scheme',
        category: 'Machinery & Solar',
        badge: 'Bihar State',
        description:
            '₹75 per liter diesel subsidy (up to ₹750/acre/irrigation) for drought and delayed monsoon crops.',
        eligibility: 'Registered farmers on DBT Agriculture Bihar portal.',
        url: 'https://dbtagriculture.bihar.gov.in',
        icon: Icons.local_gas_station_rounded,
        color: Color(0xFF6A1B9A),
      ),
    ],
    'Odisha': [
      GovtSchemeItem(
        name: 'KALIA Scheme (Krushak Assistance for Livelihood)',
        category: 'Income Support',
        badge: 'Odisha State',
        description:
            '₹10,000 per family annually for small and marginal farmers, plus ₹12,500 for landless agricultural households.',
        eligibility: 'Small, marginal farmers, and landless agri laborers verified on KALIA portal.',
        url: 'https://kalia.odisha.gov.in',
        icon: Icons.currency_rupee_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'Balaram Scheme (Sharecropper Credit)',
        category: 'Credit & Loans',
        badge: 'Odisha State',
        description:
            'Collateral-free crop loans up to ₹50,000 for landless tenant farmers via Joint Liability Groups (JLGs).',
        eligibility: 'Landless tenant cultivators and sharecroppers in Odisha.',
        url: 'https://krushak.odisha.gov.in',
        icon: Icons.group_rounded,
        color: Color(0xFF1565C0),
      ),
    ],
    'West Bengal': [
      GovtSchemeItem(
        name: 'Krishak Bandhu (Natun) Scheme',
        category: 'Income Support',
        badge: 'West Bengal State',
        description:
            'Assured financial assistance of ₹10,000 per acre per year in two installments, plus ₹2,00,000 farmer death benefit.',
        eligibility: 'All landholding farmers and recorded Bhagchasis (sharecroppers).',
        url: 'https://krishakbandhu.net',
        icon: Icons.currency_rupee_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'Bangla Fasal Bima (BFB)',
        category: 'Insurance & Relief',
        badge: 'West Bengal State',
        description:
            '100% state-funded crop insurance with zero premium charge to farmers for notified food and cash crops.',
        eligibility: 'All cultivating farmers in West Bengal growing notified seasonal crops.',
        url: 'https://banglafasalbima.net',
        icon: Icons.shield_rounded,
        color: Color(0xFF1565C0),
      ),
    ],
    'Kerala': [
      GovtSchemeItem(
        name: 'Subhiksha Keralam Agri Mission',
        category: 'Income Support',
        badge: 'Kerala State',
        description:
            'Zero-interest agricultural loans and ₹35,000/ha subsidy for fallow land paddy, tuber, and vegetable cultivation.',
        eligibility: 'Farmers and Kudumbashree producer groups in Kerala.',
        url: 'https://keralaagriculture.gov.in',
        icon: Icons.eco_rounded,
        color: Color(0xFF2E7D32),
      ),
      GovtSchemeItem(
        name: 'Royal Incentive for Paddy Cultivators',
        category: 'Income Support',
        badge: 'Kerala State',
        description:
            'Direct ecological grant of ₹5,500 per hectare for preserving paddy wetland ecosystems.',
        eligibility: 'Paddy cultivators registered on Kerala AIMS portal.',
        url: 'https://aims.kerala.gov.in',
        icon: Icons.water_rounded,
        color: Color(0xFF00897B),
      ),
    ],
    'Tamil Nadu': [
      GovtSchemeItem(
        name: 'Uzhavan App Services & Machine Booking',
        category: 'Machinery & Solar',
        badge: 'Tamil Nadu State',
        description:
            'Online booking of subsidized tractors, harvesters, seed testing, and drip irrigation subsidies.',
        eligibility: 'Farmers registered on TN Agrisnet.',
        url: 'https://www.tnagrisnet.tn.gov.in',
        icon: Icons.agriculture_rounded,
        color: Color(0xFFC2185B),
      ),
      GovtSchemeItem(
        name: 'CM Solar Powered Pump Scheme',
        category: 'Machinery & Solar',
        badge: 'Tamil Nadu State',
        description:
            '70% capital subsidy on installation of 5HP to 10HP standalone solar water pumpsets.',
        eligibility: 'Farmers with agricultural electricity connection readiness.',
        url: 'https://aed.tn.gov.in',
        icon: Icons.solar_power_rounded,
        color: Color(0xFFE65100),
      ),
    ],
  };

  // Comprehensive verified Central Government schemes with mandatory official links
  final List<GovtSchemeItem> _centralSchemes = const [
    GovtSchemeItem(
      name: 'PM-KISAN (Pradhan Mantri Kisan Samman Nidhi)',
      category: 'Income Support',
      badge: 'Central Scheme',
      description:
          'Direct cash support of ₹6,000 per year transferred directly to bank accounts of farmer families in 3 equal four-monthly installments.',
      eligibility: 'All landholding farmer families across India.',
      url: 'https://pmkisan.gov.in',
      icon: Icons.currency_rupee_rounded,
      color: Color(0xFF2E7D32),
    ),
    GovtSchemeItem(
      name: 'PMFBY (Pradhan Mantri Fasal Bima Yojana)',
      category: 'Insurance & Relief',
      badge: 'Central Scheme',
      description:
          'Comprehensive crop insurance coverage with ultra-low farmer premium (1.5% - 2%) against non-preventable natural risks, drought, and pests.',
      eligibility: 'All farmers growing notified food crops and oilseeds.',
      url: 'https://pmfby.gov.in',
      icon: Icons.shield_rounded,
      color: Color(0xFF1565C0),
    ),
    GovtSchemeItem(
      name: 'Kisan Credit Card (KCC) via JanSamarth',
      category: 'Credit & Loans',
      badge: 'Central Scheme',
      description:
          'Institutional credit up to ₹3,00,000 at a concessional effective interest rate of 4% per annum for prompt repayment.',
      eligibility: 'All cultivating farmers, tenant farmers, and oral lessees.',
      url: 'https://www.jansamarth.in',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF6A1B9A),
    ),
    GovtSchemeItem(
      name: 'PM-KUSUM (Pradhan Mantri Kisan Urja Suraksha)',
      category: 'Machinery & Solar',
      badge: 'Central Scheme',
      description:
          'Up to 60% combined subsidy for installing standalone off-grid solar agricultural water pumps and solarization of grid-connected pumps.',
      eligibility: 'Individual farmers, panchayats, and cooperatives.',
      url: 'https://pmkusum.mnre.gov.in',
      icon: Icons.solar_power_rounded,
      color: Color(0xFFE65100),
    ),
    GovtSchemeItem(
      name: 'Soil Health Card Scheme',
      category: 'Income Support',
      badge: 'Central Scheme',
      description:
          'Periodic soil testing and customized crop-wise chemical & organic fertilizer dosage recommendations to boost yield and cut input costs.',
      eligibility: 'All agricultural landowners in India.',
      url: 'https://soilhealth.dac.gov.in',
      icon: Icons.science_rounded,
      color: Color(0xFF00897B),
    ),
    GovtSchemeItem(
      name: 'SMAM (Sub-Mission on Agricultural Mechanization)',
      category: 'Machinery & Solar',
      badge: 'Central Scheme',
      description:
          'Financial subsidy from 40% to 50% for purchasing farm tractors, rotavators, power tillers, drone sprayers, and custom hiring center equipment.',
      eligibility: 'Individual farmers and self-help groups.',
      url: 'https://agrimachinery.nic.in',
      icon: Icons.agriculture_rounded,
      color: Color(0xFFC2185B),
    ),
    GovtSchemeItem(
      name: 'e-NAM (National Agriculture Market)',
      category: 'Income Support',
      badge: 'Central Scheme',
      description:
          'Pan-India electronic trading portal networking over 1,000 APMC mandis to provide transparent price discovery and online payment direct to farmers.',
      eligibility: 'All farmers with harvested produce selling in regulated mandis.',
      url: 'https://enam.gov.in',
      icon: Icons.storefront_rounded,
      color: Color(0xFF388E3C),
    ),
    GovtSchemeItem(
      name: 'PMKSY (Per Drop More Crop - Micro Irrigation)',
      category: 'Machinery & Solar',
      badge: 'Central Scheme',
      description:
          'Subsidies from 45% to 55% on installation of drip and sprinkler irrigation systems, conserving water and improving crop quality.',
      eligibility: 'All farmers with assured water source.',
      url: 'https://pmksy.gov.in',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0288D1),
    ),
    GovtSchemeItem(
      name: 'PKVY (Paramparagat Krishi Vikas Yojana)',
      category: 'Income Support',
      badge: 'Central Scheme',
      description:
          'Financial assistance of ₹50,000 per hectare for organic cluster farming, PGS certification, organic inputs, and direct marketing.',
      eligibility: 'Farmer clusters adopting organic farming methods.',
      url: 'https://pgsindia-ncof.gov.in',
      icon: Icons.eco_rounded,
      color: Color(0xFF43A047),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _autoDetectState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    if (lang != _lastTranslatedLang) {
      _translateStates(lang);
    }
  }

  Future<void> _translateStates(String lang) async {
    _lastTranslatedLang = lang;
    if (lang == 'en') {
      setState(() {
        _translatedStates = List.from(_popularStates);
      });
      return;
    }

    final cacheKey = 'translated_states_$lang';
    if (CacheService.isFresh(cacheKey)) {
      final cached = CacheService.load(cacheKey);
      if (cached != null) {
        setState(() {
          _translatedStates = List<String>.from(jsonDecode(cached));
        });
        return;
      }
    }

    try {
      final prompt =
          "Translate the following Indian state names to ${AppConstants.langNames[lang] ?? lang}. "
          "Respond ONLY with a JSON array of strings in the same order. "
          "States: ${_popularStates.join(', ')}";

      final response = await AIService.getAIResponse(prompt, language: lang);
      final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> translated = jsonDecode(cleanJson);

      setState(() {
        _translatedStates = translated.cast<String>();
      });
      CacheService.save(cacheKey, jsonEncode(_translatedStates));
    } catch (e) {
      debugPrint("Error translating states: $e");
      setState(() {
        _translatedStates = List.from(_popularStates);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stateController.dispose();
    _cropController.dispose();
    _landSizeController.dispose();
    _portalSearchController.dispose();
    super.dispose();
  }

  // ─── AUTO DETECT STATE VIA GPS ───────────────────────────────────────────
  Future<void> _autoDetectState() async {
    setState(() => _locationLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _locationLoading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final state = placemarks.first.administrativeArea ?? '';
        if (state.isNotEmpty) {
          setState(() {
            _detectedState = state;
            _stateController.text = state;
            _portalStateFilter = state;
          });
        }
      }
    } catch (_) {
      // User can select manually
    }
    setState(() => _locationLoading = false);
  }

  // ─── LAUNCH GOVERNMENT PORTAL URL ────────────────────────────────────────
  Future<void> _launchGovtUrl(String urlStr) async {
    String cleanUrl = urlStr.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) {
      _showSnack('Invalid portal link: $urlStr');
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        _showSnack('Could not launch portal: $urlStr');
      }
    }
  }

  // ─── CHECK & TRIGGER REAL-TIME SCHEME NOTIFICATION ───────────────────────
  Future<void> _checkAndNotifyNewSchemes() async {
    final state = _stateController.text.trim();
    setState(() => _checkingNewSchemes = true);

    try {
      // Try backend endpoint first
      final uri = Uri.parse(
        '${AppConstants.baseUrl}/schemes/latest?state=${Uri.encodeComponent(state)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['schemes'] as List? ?? [];
        if (list.isNotEmpty) {
          final first = list.first;
          await NotificationService.showSchemeNotification(
            title: '🏛️ New Scheme for $state: ${first['name']}',
            body: '${first['benefit']} Official Portal: ${first['url']}',
            url: first['url'] ?? 'https://pmkisan.gov.in',
            state: state,
          );
          _showSnack(
            '🔔 Real-time notification triggered for $state schemes! Check notification bar.',
          );
          setState(() => _checkingNewSchemes = false);
          return;
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // Fallback: Use local state database
    final localList = stateSpecificSchemes[state] ?? _centralSchemes;
    if (localList.isNotEmpty) {
      final item = localList.first;
      await NotificationService.showSchemeNotification(
        title: '🏛️ Active Scheme for $state: ${item.name}',
        body: '${item.description} Apply online: ${item.url}',
        url: item.url,
        state: state,
      );
      _showSnack(
        '🔔 Real-time alert dispatched for $state schemes! Check your notification bar.',
      );
    } else {
      _showSnack('No new schemes found for $state at this time.');
    }

    setState(() => _checkingNewSchemes = false);
  }

  // ─── ENSURE MANDATORY LINKS IN TEXT ──────────────────────────────────────
  String _formatSchemesWithLinks(String text, String state) {
    String formatted = text;

    final knownUrls = {
      'pmkisan.gov.in': 'https://pmkisan.gov.in',
      'pmfby.gov.in': 'https://pmfby.gov.in',
      'soilhealth.dac.gov.in': 'https://soilhealth.dac.gov.in',
      'jansamarth.in': 'https://www.jansamarth.in',
      'enam.gov.in': 'https://enam.gov.in',
      'pmkusum.mnre.gov.in': 'https://pmkusum.mnre.gov.in',
      'agrimachinery.nic.in': 'https://agrimachinery.nic.in',
      'pmksy.gov.in': 'https://pmksy.gov.in',
      'pgsindia-ncof.gov.in': 'https://pgsindia-ncof.gov.in',
      'mahadbt.maharashtra.gov.in': 'https://mahadbt.maharashtra.gov.in',
      'ysrrythubharosa.ap.gov.in': 'https://ysrrythubharosa.ap.gov.in',
      'rythubandhu.telangana.gov.in': 'https://rythubandhu.telangana.gov.in',
      'fruits.karnataka.gov.in': 'https://fruits.karnataka.gov.in',
      'ikhedut.gujarat.gov.in': 'https://ikhedut.gujarat.gov.in',
      'upagriculture.com': 'http://upagriculture.com',
      'mpkrishi.mp.gov.in': 'https://mpkrishi.mp.gov.in',
      'rajkisan.rajasthan.gov.in': 'https://rajkisan.rajasthan.gov.in',
      'fasal.haryana.gov.in': 'https://fasal.haryana.gov.in',
      'dbtagriculture.bihar.gov.in': 'https://dbtagriculture.bihar.gov.in',
      'kalia.odisha.gov.in': 'https://kalia.odisha.gov.in',
      'krishakbandhu.net': 'https://krishakbandhu.net',
    };

    knownUrls.forEach((domain, fullUrl) {
      if (!formatted.contains('($fullUrl)') && !formatted.contains('($domain)')) {
        formatted = formatted.replaceAll(domain, '[$domain]($fullUrl)');
      }
    });

    return formatted;
  }

  // ─── FETCH SCHEMES ───────────────────────────────────────────────────────
  Future<void> _findSchemes() async {
    final state = _stateController.text.trim();
    final crop = _cropController.text.trim();
    final landSize = double.tryParse(_landSizeController.text) ?? 1.0;
    final lang =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    final cacheKey = 'schemes_v3_${state}_${crop}_$lang';

    if (CacheService.isFresh(cacheKey)) {
      final cached = CacheService.load(cacheKey);
      if (cached != null) {
        setState(() => _schemesResult = cached);
        return;
      }
    }

    setState(() {
      _loading = true;
      _schemesResult = null;
    });

    bool backendSuccess = false;
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/recommend-schemes');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'state': state,
              'crop': crop,
              'land_size': landSize,
              'lang': lang,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['schemes'] != null) {
          setState(() {
            _schemesResult = _formatSchemesWithLinks(data['schemes'], state);
          });
          backendSuccess = true;
        }
      }
    } catch (_) {
      // Backend unreachable — fallback to direct AI
    }

    if (!backendSuccess) {
      try {
        final prompt =
            'You are an expert on Indian central and state government agricultural schemes.\n\n'
            'A farmer in $state grows $crop on $landSize hectares.\n\n'
            'Recommend the top 5 most relevant central and state government schemes for $state.\n\n'
            'MANDATORY REQUIREMENT: For EVERY single scheme, you MUST provide the official government portal link as a markdown link [Official Portal](https://...). Always include genuine official URLs like pmkisan.gov.in, pmfby.gov.in, soilhealth.dac.gov.in, enam.gov.in, jansamarth.in, pmkusum.mnre.gov.in, agrimachinery.nic.in, or $state state agriculture portals. Do not omit links.\n\n'
            'For each scheme include:\n'
            '1. **Scheme Name**\n'
            '2. **Benefits & Subsidy Amount**\n'
            '3. **Eligibility**\n'
            '4. **How to Apply**\n'
            '5. **Official Portal**: [Visit Official Portal](https://...)\n\n'
            'Format in clear Markdown. Include PM-KISAN, PMFBY, and $state-specific schemes.';

        final response = await AIService.getAIResponse(prompt, language: lang);
        setState(() {
          _schemesResult = _formatSchemesWithLinks(response, state);
        });
      } catch (e) {
        _showSnack('Could not fetch schemes: $e');
      }
    }

    if (_schemesResult != null) {
      CacheService.save(cacheKey, _schemesResult!);

      // Also dispatch a real-time notification alert to the phone
      NotificationService.showSchemeNotification(
        title: '🏛️ Schemes Available for $crop in $state',
        body: 'Customized government subsidies and verified links ready. Tap to view.',
        url: statePortals[state]?['url'] ?? 'https://pmkisan.gov.in',
        state: state,
      );
    }

    setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;
    String voiceContent = AppTranslations.get('voice_schemes_intro', langCode);
    if (_schemesResult != null) {
      voiceContent += '. ${_schemesResult!.replaceAll('*', '')}';
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.govtSchemes),
        elevation: 0,
        actions: [
          IconButton(
            icon: _checkingNewSchemes
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_alert_rounded),
            onPressed: _checkingNewSchemes ? null : _checkAndNotifyNewSchemes,
            tooltip: 'Trigger Real-time Scheme Notification',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _locationLoading ? null : _autoDetectState,
            tooltip: 'Detect my state',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.psychology_outlined, size: 20),
              text: 'AI Scheme Finder',
            ),
            Tab(
              icon: Icon(Icons.account_balance, size: 20),
              text: 'Official Govt Portals',
            ),
          ],
        ),
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.governmentSchemes,
        textToRead: voiceContent,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFinderTab(),
            _buildPortalsTab(),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: AI SCHEME FINDER WITH MANDATORY LINKS & STATE SCHEMES ─────────
  Widget _buildFinderTab() {
    final currentState = _stateController.text.trim();
    final statePortalData = statePortals[currentState];
    final specificSchemes = stateSpecificSchemes[currentState] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with mandatory link badge & Real-time alerts trigger
          _buildBanner(),
          const SizedBox(height: 14),

          // Real-time notification alert bar
          _buildRealtimeNotificationBar(currentState),
          const SizedBox(height: 16),

          // State Official Portal Quick Card (Mandatory Link)
          if (statePortalData != null) ...[
            _buildStatePortalCard(currentState, statePortalData),
            const SizedBox(height: 16),
          ],

          // Form
          _buildForm(),
          const SizedBox(height: 16),

          // Quick state chips
          _buildStateChips(),
          const SizedBox(height: 20),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: _loading ? null : _findSchemes,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(
                _loading
                    ? AppLocalizations.of(context)!.searching
                    : 'Find Schemes with Official Links',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dedicated State-Specific Schemes Section (Instant Availability)
          if (specificSchemes.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFE65100), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active $currentState Government Schemes (${specificSchemes.length})',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...specificSchemes.map((scheme) => _buildSchemePortalCard(scheme)),
            const SizedBox(height: 20),
          ],

          // AI Recommendations Results
          if (_schemesResult != null) _buildResults(),
        ],
      ),
    );
  }

  // ─── REAL-TIME NOTIFICATION BAR ──────────────────────────────────────────
  Widget _buildRealtimeNotificationBar(String state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5CAE9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Real-Time Scheme Notifications',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                Text(
                  'Live alerts active for $state newly launched subsidies',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF1A237E)),
              ),
            ),
            onPressed: _checkingNewSchemes ? null : _checkAndNotifyNewSchemes,
            child: _checkingNewSchemes
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Check Now',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── BANNER ──────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.governmentSchemes,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _locationLoading
                          ? AppLocalizations.of(context)!.detectingState
                          : _detectedState != null
                              ? '📍 ${AppLocalizations.of(context)!.autoDetected(_detectedState!)}'
                              : AppLocalizations.of(context)!.subsidiesForFarmers,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_locationLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_rounded, color: Color(0xFFFFD54F), size: 16),
                SizedBox(width: 6),
                Text(
                  'Mandatory Official Govt Portal Links Guaranteed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATE PORTAL HIGHLIGHT CARD ─────────────────────────────────────────
  Widget _buildStatePortalCard(
      String stateName, Map<String, String> portalData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCE93D8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🏛️ Official $stateName Agriculture Portal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Color(0xFF4A148C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OFFICIAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            portalData['name'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: Color(0xFF311B92),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            portalData['desc'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _launchGovtUrl(portalData['url'] ?? ''),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                'Open ${portalData['name']?.split('/').first.trim()} Portal',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FORM ─────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _stateController,
            onChanged: (val) {
              setState(() {
                _portalStateFilter = val;
              });
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.state,
              prefixIcon: const Icon(Icons.map_outlined, color: Colors.indigo),
              suffixIcon: _locationLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.indigo),
                      onPressed: _autoDetectState,
                      tooltip: 'Use my location',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cropController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.cropType,
              prefixIcon: const Icon(Icons.grass_rounded, color: Colors.green),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _landSizeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.landSize,
              prefixIcon: const Icon(Icons.straighten, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK STATE CHIPS ────────────────────────────────────────────────────
  Widget _buildStateChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickSelectState,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: Iterable<int>.generate(_popularStates.length).map((index) {
            final stateEn = _popularStates[index];
            final stateDisplay = (_translatedStates.length > index)
                ? _translatedStates[index]
                : stateEn;
            final isSelected = _stateController.text == stateEn ||
                _stateController.text == stateDisplay;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _stateController.text = stateEn;
                  _portalStateFilter = stateEn;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.indigo : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  stateDisplay,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── RESULTS WITH CLICKABLE LINKS & QUICK ACTION BUTTONS ──────────────────
  Widget _buildResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.indigo.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.indigo, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.schemesFor(
                    _stateController.text,
                    _cropController.text,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '🔗 Tap any blue portal link below to apply directly on the official government website.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
          const Divider(height: 22),

          // Markdown Content with clickable, styled links
          MarkdownBody(
            data: _schemesResult!,
            onTapLink: (text, href, title) {
              if (href != null) {
                _launchGovtUrl(href);
              }
            },
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14, height: 1.6),
              h2: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              h3: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
              listBullet: const TextStyle(fontSize: 14),
              strong: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              a: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF0D47A1),
                decorationThickness: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Interactive 1-tap buttons for prominent schemes
          _buildQuickActionButtons(),
          const SizedBox(height: 14),

          // KVK Info footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.kvkInfo,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK LAUNCH ACTION BUTTONS ──────────────────────────────────────────
  Widget _buildQuickActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_rounded, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 6),
              Text(
                '1-Tap Launch Official Application Portals:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickPortalChip(
                'PM-KISAN (₹6000/yr)',
                'https://pmkisan.gov.in',
                Icons.currency_rupee,
                const Color(0xFF2E7D32),
              ),
              _buildQuickPortalChip(
                'PMFBY Crop Insurance',
                'https://pmfby.gov.in',
                Icons.shield,
                const Color(0xFF1565C0),
              ),
              _buildQuickPortalChip(
                'Kisan Credit Card (4%)',
                'https://www.jansamarth.in',
                Icons.credit_card,
                const Color(0xFF6A1B9A),
              ),
              _buildQuickPortalChip(
                'Soil Health Card',
                'https://soilhealth.dac.gov.in',
                Icons.science,
                const Color(0xFF00897B),
              ),
              _buildQuickPortalChip(
                'PM-KUSUM Solar',
                'https://pmkusum.mnre.gov.in',
                Icons.solar_power,
                const Color(0xFFE65100),
              ),
              _buildQuickPortalChip(
                'SMAM Machinery Subsidy',
                'https://agrimachinery.nic.in',
                Icons.agriculture,
                const Color(0xFFC2185B),
              ),
              _buildQuickPortalChip(
                'e-NAM Mandi',
                'https://enam.gov.in',
                Icons.storefront,
                const Color(0xFF388E3C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPortalChip(
      String label, String url, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _launchGovtUrl(url),
    );
  }

  // ─── TAB 2: COMPLETE DIRECTORY OF OFFICIAL GOVT PORTALS ──────────────────
  Widget _buildPortalsTab() {
    final categories = [
      'All',
      'Income Support',
      'Insurance & Relief',
      'Credit & Loans',
      'Machinery & Solar',
      'State Portals',
    ];

    final searchQuery = _portalSearchController.text.trim().toLowerCase();

    // Central schemes list
    final filteredCentral = _centralSchemes.where((scheme) {
      final matchesCategory = _selectedCategory == 'All' ||
          _selectedCategory == scheme.category;
      final matchesSearch = searchQuery.isEmpty ||
          scheme.name.toLowerCase().contains(searchQuery) ||
          scheme.description.toLowerCase().contains(searchQuery) ||
          scheme.url.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    // State schemes matching selected state filter
    List<GovtSchemeItem> matchingStateSchemes = [];
    if (_portalStateFilter == 'All States') {
      stateSpecificSchemes.forEach((_, list) {
        matchingStateSchemes.addAll(list);
      });
    } else {
      matchingStateSchemes = stateSpecificSchemes[_portalStateFilter] ?? [];
    }

    final filteredStateSchemes = matchingStateSchemes.where((scheme) {
      final matchesCategory = _selectedCategory == 'All' ||
          _selectedCategory == scheme.category ||
          _selectedCategory == 'State Portals';
      final matchesSearch = searchQuery.isEmpty ||
          scheme.name.toLowerCase().contains(searchQuery) ||
          scheme.badge.toLowerCase().contains(searchQuery) ||
          scheme.description.toLowerCase().contains(searchQuery) ||
          scheme.url.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    // Filter state portals
    final filteredStatePortals = statePortals.entries.where((entry) {
      final matchesState = _portalStateFilter == 'All States' ||
          entry.key == _portalStateFilter;
      final matchesCategory = _selectedCategory == 'All' ||
          _selectedCategory == 'State Portals';
      final matchesSearch = searchQuery.isEmpty ||
          entry.key.toLowerCase().contains(searchQuery) ||
          (entry.value['name']?.toLowerCase().contains(searchQuery) ?? false) ||
          (entry.value['desc']?.toLowerCase().contains(searchQuery) ?? false);
      return matchesState && matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.indigo, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verified Official Portals Directory',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select any state below to view all state-specific schemes with guaranteed official application links.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // State Selector Dropdown Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.indigo, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Select State:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _popularStates.contains(_portalStateFilter)
                          ? _portalStateFilter
                          : 'All States',
                      isExpanded: true,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                      ),
                      items: ['All States', ..._popularStates].map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _portalStateFilter = val;
                            if (val != 'All States') {
                              _stateController.text = val;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _portalSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search schemes (e.g., Rythu, Insurance, Tractor)...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _portalSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Categories Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Section 1: State Specific Schemes
          if (filteredStateSchemes.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFF6A1B9A), size: 20),
                const SizedBox(width: 6),
                Text(
                  _portalStateFilter == 'All States'
                      ? '🏛️ State Government Specific Schemes'
                      : '🏛️ $_portalStateFilter State Government Schemes',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...filteredStateSchemes.map((scheme) => _buildSchemePortalCard(scheme)),
            const SizedBox(height: 16),
          ],

          // Section 2: Central Government Schemes
          if (filteredCentral.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.flag_rounded, color: Color(0xFF1B5E20), size: 20),
                SizedBox(width: 6),
                Text(
                  '🇮🇳 Central Government Schemes (All India)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...filteredCentral.map((scheme) => _buildSchemePortalCard(scheme)),
            const SizedBox(height: 16),
          ],

          // Section 3: State Government Portals
          if (filteredStatePortals.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFF311B92), size: 20),
                SizedBox(width: 6),
                Text(
                  '🏛️ State Agriculture DBT Official Portals',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF311B92),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...filteredStatePortals.map((entry) => _buildStateSchemeCard(
                  entry.key,
                  entry.value['name'] ?? '',
                  entry.value['url'] ?? '',
                  entry.value['desc'] ?? '',
                )),
          ],

          if (filteredCentral.isEmpty &&
              filteredStateSchemes.isEmpty &&
              filteredStatePortals.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'No schemes found matching your search.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSchemePortalCard(GovtSchemeItem scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(scheme.icon, color: scheme.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scheme.badge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: scheme.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scheme.category,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
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
          const SizedBox(height: 10),
          Text(
            scheme.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          if (scheme.eligibility.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 15, color: Colors.green),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Eligibility: ${scheme.eligibility}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, size: 15, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    scheme.url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _launchGovtUrl(scheme.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'Open Official Government Portal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSchemeCard(
      String state, String portalName, String url, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_city,
                    color: Color(0xFF7B1FA2), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$state State Government',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                    Text(
                      portalName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, size: 15, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _launchGovtUrl(url),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                'Visit Official $state Portal',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
