import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/app_translations.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:hive/hive.dart';

import 'package:farmer_ai/screens/disease_result_screen.dart';
import 'package:farmer_ai/screens/history_screen.dart';
import 'package:farmer_ai/screens/disease_gallery_screen.dart';
import '../widgets/voice_wrapper.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class DiseaseScreen extends StatefulWidget {
  final bool isEmbedded;
  const DiseaseScreen({super.key, this.isEmbedded = false});

  @override
  State<DiseaseScreen> createState() => _DiseaseScreenState();
}

class _DiseaseScreenState extends State<DiseaseScreen>
    with SingleTickerProviderStateMixin {
  File? imageFile;
  bool loading = false;
  int activeMode = 0; // 0: Disease Detection, 1: Fruit Ripeness, 2: Deep Weed

  // 🌾 Field & Irrigation Context Telemetry for AI Water Engine
  String _selectedCropType = 'Paddy';
  String _selectedGrowthStage = 'Flowering';
  double _soilMoisture = 28.0; // %
  double _temperature = 32.0; // °C
  final double _recentRainfall = 0.0; // mm
  int _daysSinceIrrigation = 4; // days
  String _fieldCondition = 'Dry';
  bool _isFieldContextExpanded = false;

  final List<String> _cropTypes = [
    'Paddy',
    'Tomato',
    'Potato',
    'Corn',
    'Cotton',
    'Wheat',
    'Chilli',
    'Apple',
    'Grape',
    'Sugarcane',
  ];

  final List<String> _growthStages = [
    'Seedling',
    'Vegetative',
    'Flowering',
    'Fruit/Grain Setting',
    'Maturity',
  ];

  final List<String> _fieldConditions = [
    'Dry',
    'Normal',
    'Waterlogged',
  ];

  final ImagePicker _picker = ImagePicker();

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  // 📸 Pick image
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  // 🔍 Analyze image based on selected activeMode
  Future<void> analyzeImage() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or capture an image first')),
      );
      return;
    }

    setState(() => loading = true);
    final lang =
        Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;

    try {
      if (activeMode == 0) {
        await _analyzeDisease(lang);
      } else if (activeMode == 1) {
        await _analyzeFruit(lang);
      } else if (activeMode == 2) {
        await _analyzeWeed(lang);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("API ERROR: $e");
      String errorMessage;
      final errStr = e.toString().toLowerCase();
      if (e is SocketException || errStr.contains('socket')) {
        errorMessage = 'Network error: Could not reach AI server. Check your internet connection.';
      } else if (errStr.contains('429') || errStr.contains('too many requests')) {
        errorMessage = 'Server busy (Rate limited). Please wait 5 seconds and try again.';
      } else if (errStr.contains('timeout') || errStr.contains('timed out')) {
        errorMessage = 'Server is warming up (Render cold start). Please wait 30s and try again.';
      } else if (e is FormatException) {
        errorMessage = 'Invalid response from server. Please try again.';
      } else {
        String msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('<!DOCTYPE') || msg.contains('<html') || msg.contains('just a moment')) {
          msg = 'Server rate-limited or updating. Please wait 5s and try again.';
        }
        errorMessage = msg.startsWith('Error') ? msg : 'Error: $msg';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🛡️ Network Helper with Automatic Retry for Rate Limits & Failover
  Future<http.StreamedResponse> _sendWithFallback(
    http.MultipartRequest request,
    String imagePath,
  ) async {
    Future<http.MultipartFile> freshFile() =>
        http.MultipartFile.fromPath('file', imagePath);

    // Set standard mobile client headers (avoid Cloudflare bot detection triggers)
    request.headers['Accept'] = 'application/json';

    // Attempt 1: primary request
    try {
      final res = await request.send().timeout(const Duration(seconds: 25));
      if (res.statusCode != 429) {
        return res;
      }
      debugPrint("Received HTTP 429 rate limit on attempt 1. Retrying with delay...");
    } catch (e) {
      debugPrint("Primary connection attempt failed ($e). Retrying with Render production backend...");
    }

    // Wait 1.5 seconds to clear temporary rate limit window
    await Future.delayed(const Duration(milliseconds: 1500));

    // Attempt 2: Fresh request retry
    final currentUrl = request.url.toString();
    final renderUrl = currentUrl.contains(AppConstants.renderUrl)
        ? currentUrl
        : currentUrl.replaceFirst(AppConstants.baseUrl, AppConstants.renderUrl);
    final fallbackRequest = http.MultipartRequest('POST', Uri.parse(renderUrl));
    fallbackRequest.headers['Accept'] = 'application/json';
    fallbackRequest.fields.addAll(request.fields);
    fallbackRequest.files.add(await freshFile());
    return await fallbackRequest.send().timeout(const Duration(seconds: 60));
  }

  // 🍃 Mode 0: Disease Detection
  Future<void> _analyzeDisease(String lang) async {
    final imagePath = imageFile!.path;
    final uri = Uri.parse('${AppConstants.baseUrl}/detect-disease');
    final request = http.MultipartRequest('POST', uri);
    request.fields['lang'] = lang;
    request.fields['crop_type'] = _selectedCropType;
    request.fields['growth_stage'] = _selectedGrowthStage;
    request.fields['soil_moisture'] = _soilMoisture.toStringAsFixed(1);
    request.fields['temperature'] = _temperature.toStringAsFixed(1);
    request.fields['recent_rainfall_mm'] = _recentRainfall.toStringAsFixed(1);
    request.fields['days_since_irrigation'] = _daysSinceIrrigation.toString();
    request.fields['field_condition'] = _fieldCondition;
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final streamedResponse = await _sendWithFallback(request, imagePath);
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(body);
      final disease = data['disease'] ?? 'Unknown Disease';
      final recommendation =
          data['recommendation'] ?? 'No recommendation available.';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final treatment = data['treatment'];
      final aiExplanation = data['ai_explanation'];
      final datasetReferenceImages = (data['dataset_reference_samples'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final matchedPatterns = (data['matched_patterns'] as List?)
          ?.map((e) => e.toString())
          .toList();
      final datasetName = data['dataset_name'] as String?;

      // Foliar symptom classification & AI water engine telemetry
      final category = data['category'] as String?;
      final waterRequirement = data['water_requirement'] as String?;
      final soilMoistureStatus = data['soil_moisture'] as String?;
      final cropStress = data['crop_stress'] as String?;
      final nextIrrigation = data['next_irrigation'] as String?;
      final waterEstimation = (data['water_estimation'] as Map?)?.cast<String, dynamic>();

      final box = Hive.box('historyBox');
      box.add({
        'imagePath': imageFile!.path,
        'disease': disease,
        'confidence': confidence,
        'date': DateTime.now().toString(),
        'treatment': treatment,
        'mode': 'Disease Detection',
        'category': category,
        'water_requirement': waterRequirement,
        'crop_stress': cropStress,
        'next_irrigation': nextIrrigation,
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiseaseResultScreen(
            disease: disease,
            confidence: confidence,
            recommendation: recommendation,
            treatment: treatment,
            aiExplanation: aiExplanation,
            uploadedImagePath: imageFile!.path,
            datasetReferenceImages: datasetReferenceImages,
            matchedPatterns: matchedPatterns,
            datasetName: datasetName,
            category: category,
            waterRequirement: waterRequirement,
            soilMoistureStatus: soilMoistureStatus,
            cropStress: cropStress,
            nextIrrigation: nextIrrigation,
            waterEstimation: waterEstimation,
            cropType: _selectedCropType,
          ),
        ),
      );
    } else {
      throw Exception("Server status ${streamedResponse.statusCode}");
    }
  }

  // 🍎 Mode 1: Fruit Ripeness & Classification
  Future<void> _analyzeFruit(String lang) async {
    final imagePath = imageFile!.path;
    final uri = Uri.parse('${AppConstants.baseUrl}/classify-fruit');
    final request = http.MultipartRequest('POST', uri);
    request.fields['lang'] = lang;
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final streamedResponse = await _sendWithFallback(request, imagePath);
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      final fruitName = data['fruit'] ?? 'Unknown Fruit';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final aiInfo = data['ai_info'] ?? 'Fruit classified successfully.';
      final datasetReferenceImages = (data['dataset_reference_samples'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final matchedPatterns = (data['matched_patterns'] as List?)
          ?.map((e) => e.toString())
          .toList();
      final datasetName = data['dataset_name'] as String?;

      final box = Hive.box('historyBox');
      box.add({
        'imagePath': imagePath,
        'disease': 'Fruit: $fruitName',
        'confidence': confidence,
        'date': DateTime.now().toString(),
        'mode': 'Fruit Classification',
      });

      if (!mounted) return;
      _showFruitResultSheet(
        fruitName: fruitName,
        confidence: confidence,
        aiInfo: aiInfo,
        uploadedImagePath: imagePath,
        datasetReferenceImages: datasetReferenceImages,
        matchedPatterns: matchedPatterns,
        datasetName: datasetName,
      );
    } else {
      throw Exception("Server error ${streamedResponse.statusCode}: ${body.length > 200 ? body.substring(0, 200) : body}");
    }
  }

  // 🌿 Mode 2: Deep Weed Species Detection
  Future<void> _analyzeWeed(String lang) async {
    final imagePath = imageFile!.path;
    final uri = Uri.parse('${AppConstants.baseUrl}/detect-weed');
    final request = http.MultipartRequest('POST', uri);
    request.fields['lang'] = lang;
    request.files.add(await http.MultipartFile.fromPath('file', imagePath));

    final streamedResponse = await _sendWithFallback(request, imagePath);
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      final weedName = data['weed'] ?? 'Unknown Weed Species';
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final controlAdvice = data['control_advice'] ?? 'No advice available.';
      final isWeed = data['is_weed'] ?? (!weedName.contains("Negative") && !weedName.contains("No Weed"));
      final sprayDecision = data['spray_decision'] ?? (isWeed ? "SPRAY HERE 🎯 (Target Weed Identified)" : "DO NOT SPRAY 🚫 (Crop Protected Zone)");
      final roboticCommand = data['robotic_command'] ?? (isWeed ? "ACTUATE_NOZZLE_ON" : "NOZZLE_SHUT_OFF");
      final datasetReferenceImages = (data['dataset_reference_samples'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final matchedPatterns = (data['matched_patterns'] as List?)
          ?.map((e) => e.toString())
          .toList();
      final datasetName = data['dataset_name'] as String?;

      final box = Hive.box('historyBox');
      box.add({
        'imagePath': imagePath,
        'disease': 'Weed: $weedName',
        'confidence': confidence,
        'date': DateTime.now().toString(),
        'mode': 'Weed Detection',
        'spray_decision': sprayDecision,
      });

      if (!mounted) return;
      _showWeedResultSheet(
        weedName: weedName,
        confidence: confidence,
        controlAdvice: controlAdvice,
        isWeed: isWeed,
        sprayDecision: sprayDecision,
        roboticCommand: roboticCommand,
        uploadedImagePath: imagePath,
        datasetReferenceImages: datasetReferenceImages,
        matchedPatterns: matchedPatterns,
        datasetName: datasetName,
      );
    } else {
      throw Exception("Server error ${streamedResponse.statusCode}: ${body.length > 200 ? body.substring(0, 200) : body}");
    }
  }

  // 🍎 Bottom Sheet for Fruit Classification
  void _showFruitResultSheet({
    required String fruitName,
    required double confidence,
    required String aiInfo,
    String? uploadedImagePath,
    List<Map<String, dynamic>>? datasetReferenceImages,
    List<String>? matchedPatterns,
    String? datasetName,
  }) {
    final refSamples = datasetReferenceImages ?? [
      {
        'title': 'Dataset Exemplar 1 (Commercial Harvest)',
        'image_url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=80',
        'stage': 'Commercial Harvest Window',
        'hallmark': 'Firm peel with balanced soluble solids (Brix 12.5°)',
      },
      {
        'title': 'Dataset Exemplar 2 (Peak Table Ripeness)',
        'image_url': 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=600&q=80',
        'stage': 'Peak Table Sweetness',
        'hallmark': 'Full carotenoid saturation & maximum Brix sweetness',
      },
    ];

    final patterns = matchedPatterns ?? [
      'Peel carotenoid & anthocyanin chromatic shift',
      'Chlorophyll breakdown and cuticle gloss index',
      'Firmness & soluble solids (Brix) correlation',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.apple_rounded, color: Colors.deepOrange, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fruitName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fruits-360 Ripeness Vision AI',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${confidence.toStringAsFixed(1)}%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔬 DATASET REFERENCE COMPARISON CARDS
              Text(
                '🔬 ML Ripening Pattern vs Dataset Exemplars',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 195,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Uploaded Card
                    _buildCompareCard(
                      title: '📸 Your Uploaded Sample',
                      badge: 'Live Scan',
                      badgeColor: Colors.blue.shade700,
                      imageWidget: uploadedImagePath != null && File(uploadedImagePath).existsSync()
                          ? Image.file(File(uploadedImagePath), fit: BoxFit.cover, width: 150, height: 120)
                          : Container(width: 150, height: 120, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                      subtitle: 'Field camera capture',
                    ),
                    const SizedBox(width: 10),

                    // Dataset Sample 1
                    _buildCompareCard(
                      title: refSamples[0]['title'] ?? 'Dataset Exemplar 1',
                      badge: refSamples[0]['stage'] ?? 'Commercial Stage',
                      badgeColor: Colors.orange.shade800,
                      imageWidget: Image.network(
                        refSamples[0]['image_url'],
                        fit: BoxFit.cover,
                        width: 150,
                        height: 120,
                        errorBuilder: (_, __, ___) => Image.asset('assets/crops/tomato.jpg', fit: BoxFit.cover, width: 150, height: 120),
                      ),
                      subtitle: refSamples[0]['hallmark'] ?? 'Harvest window index',
                    ),
                    const SizedBox(width: 10),

                    // Dataset Sample 2
                    if (refSamples.length > 1) ...[
                      _buildCompareCard(
                        title: refSamples[1]['title'] ?? 'Dataset Exemplar 2',
                        badge: refSamples[1]['stage'] ?? 'Peak Ripeness',
                        badgeColor: Colors.purple.shade700,
                        imageWidget: Image.network(
                          refSamples[1]['image_url'],
                          fit: BoxFit.cover,
                          width: 150,
                          height: 120,
                          errorBuilder: (_, __, ___) => Image.asset('assets/crops/potato.jpg', fit: BoxFit.cover, width: 150, height: 120),
                        ),
                        subtitle: refSamples[1]['hallmark'] ?? 'Peak table sugar',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Matched Hallmarks
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧬 Matched Ripening Markers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange.shade900),
                    ),
                    const SizedBox(height: 6),
                    ...patterns.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.deepOrange, size: 14),
                              const SizedBox(width: 6),
                              Expanded(child: Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AI Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.deepOrange, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Nutritional & Market Harvesting Advice',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade900, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(aiInfo, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌿 Bottom Sheet for Deep Weed Detection
  void _showWeedResultSheet({
    required String weedName,
    required double confidence,
    required String controlAdvice,
    required bool isWeed,
    required String sprayDecision,
    required String roboticCommand,
    String? uploadedImagePath,
    List<Map<String, dynamic>>? datasetReferenceImages,
    List<String>? matchedPatterns,
    String? datasetName,
  }) {
    Color themeColor = isWeed ? Colors.red : Colors.green;
    IconData themeIcon = isWeed ? Icons.my_location_rounded : Icons.shield_rounded;

    final refSamples = datasetReferenceImages ?? [
      {
        'title': 'Dataset Exemplar 1 (Rosette / Vegetative)',
        'image_url': 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?auto=format&fit=crop&w=600&q=80',
        'stage': 'Vegetative Stage (Target)',
        'hallmark': 'Dense basal rosette with serrated margins',
      },
      {
        'title': 'Dataset Exemplar 2 (Flowering / Mature)',
        'image_url': 'https://images.unsplash.com/photo-1599818818844-3b60882e3532?auto=format&fit=crop&w=600&q=80',
        'stage': 'Flowering Stage (Biohazard)',
        'hallmark': 'Profuse seedhead branching requiring pulse spray',
      },
    ];

    final patterns = matchedPatterns ?? [
      'Distinct serrated margin & foliar pubescence',
      'Broadleaf dicot branching vs monocot crop blade',
      'High weed biomass density requiring precision spray',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🎯 ROBOTIC SPRAYER DECISION BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(themeIcon, color: themeColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isWeed ? 'SPRAY HERE 🎯' : 'DO NOT SPRAY 🚫',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: themeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isWeed ? 'Target Weed Identified for Sprayer' : 'Protected Crop / Safe Area',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isWeed ? 'SPRAY' : 'SHUT OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.grass_rounded, color: Colors.green.shade800, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weedName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'DeepWeeds AI Drone Telemetry',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text('${confidence.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: themeColor)),
                ],
              ),
              const SizedBox(height: 14),

              // 🔬 DATASET REFERENCE COMPARISON CARDS
              Text(
                '🔬 Botanical Pattern vs DeepWeeds Dataset',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 195,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Uploaded Card
                    _buildCompareCard(
                      title: '📸 Your Uploaded Sample',
                      badge: 'Live Drone/Camera',
                      badgeColor: Colors.blue.shade700,
                      imageWidget: uploadedImagePath != null && File(uploadedImagePath).existsSync()
                          ? Image.file(File(uploadedImagePath), fit: BoxFit.cover, width: 150, height: 120)
                          : Container(width: 150, height: 120, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                      subtitle: 'Field vegetation input',
                    ),
                    const SizedBox(width: 10),

                    // Dataset Sample 1
                    _buildCompareCard(
                      title: refSamples[0]['title'] ?? 'Dataset Exemplar 1',
                      badge: refSamples[0]['stage'] ?? 'Target Stage',
                      badgeColor: Colors.red.shade800,
                      imageWidget: Image.network(
                        refSamples[0]['image_url'],
                        fit: BoxFit.cover,
                        width: 150,
                        height: 120,
                        errorBuilder: (_, __, ___) => Image.asset('assets/crops/bajra.jpg', fit: BoxFit.cover, width: 150, height: 120),
                      ),
                      subtitle: refSamples[0]['hallmark'] ?? 'Early stage target',
                    ),
                    const SizedBox(width: 10),

                    // Dataset Sample 2
                    if (refSamples.length > 1) ...[
                      _buildCompareCard(
                        title: refSamples[1]['title'] ?? 'Dataset Exemplar 2',
                        badge: refSamples[1]['stage'] ?? 'Mature Stage',
                        badgeColor: Colors.purple.shade700,
                        imageWidget: Image.network(
                          refSamples[1]['image_url'],
                          fit: BoxFit.cover,
                          width: 150,
                          height: 120,
                          errorBuilder: (_, __, ___) => Image.asset('assets/crops/cotton.jpg', fit: BoxFit.cover, width: 150, height: 120),
                        ),
                        subtitle: refSamples[1]['hallmark'] ?? 'Flowering biohazard',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Matched Botanical Traits
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧬 Matched Botanical Markers',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 6),
                    ...patterns.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                              const SizedBox(width: 6),
                              Expanded(child: Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🗺️ SPRAYER / DRONE GRID MAP
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.grid_4x4_rounded, size: 18, color: Colors.black87),
                            SizedBox(width: 6),
                            Text('Target Spray Grid Map (3x3)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Text('Cmd: $roboticCommand', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (col) {
                        return Column(
                          children: List.generate(3, (row) {
                            bool isCenter = (row == 1 && col == 1);
                            bool activeSpray = isCenter && isWeed;
                            Color cellColor = activeSpray
                                ? Colors.red.shade600
                                : (isCenter && !isWeed ? Colors.green.shade600 : Colors.green.shade100);
                            return Container(
                              margin: const EdgeInsets.all(3),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(8),
                                border: activeSpray ? Border.all(color: Colors.red.shade900, width: 2) : null,
                              ),
                              child: Center(
                                child: Icon(
                                  activeSpray ? Icons.local_see_rounded : Icons.shield_outlined,
                                  color: activeSpray ? Colors.white : Colors.green.shade800,
                                  size: 16,
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Control Advice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isWeed ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: themeColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isWeed ? 'Robotic Spray & Drone Guidance' : 'Crop Area Protection Protocol',
                          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(controlAdvice, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isWeed ? Colors.red.shade700 : Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Acknowledge', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompareCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required Widget imageWidget,
    required String subtitle,
  }) {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                imageWidget,
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    String voiceContent =
        "${AppLocalizations.of(context)!.diseaseDetection}. Mode: ${activeMode == 0 ? 'Plant Disease' : activeMode == 1 ? 'Fruit Ripeness' : 'Weed Detection'}. ${AppLocalizations.of(context)!.uploadLeafHint}";

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(AppLocalizations.of(context)!.diseaseDetection),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: AppLocalizations.of(context)!.predictionHistory,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
              ],
            ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.diseaseDetection,
        textToRead: voiceContent,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // 🎛️ Mode Selector Cards
              _buildModeSelector(),

              const SizedBox(height: 20),

              // Mode Description Banner
              _buildModeHeaderBanner(),

              if (activeMode == 0) ...[
                const SizedBox(height: 16),
                _buildFieldContextCard(),
              ],

              const SizedBox(height: 20),

              // 📸 Scanner / Image Container with Micro-Animations
              _buildImageScannerBox(),

              const SizedBox(height: 24),

              // Camera & Gallery Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: AppConstants.primaryColor, width: 1.5),
                        ),
                      ),
                      onPressed:
                          loading ? null : () => pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(AppLocalizations.of(context)!.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.primaryColor,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: AppConstants.primaryColor, width: 1.5),
                        ),
                      ),
                      onPressed:
                          loading ? null : () => pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(AppLocalizations.of(context)!.gallery),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🚀 Analyze Button with Dynamic Text
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: (imageFile == null || loading)
                          ? [Colors.grey.shade400, Colors.grey.shade500]
                          : [Colors.green.shade600, Colors.teal.shade700],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: (imageFile != null && !loading)
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        (imageFile == null || loading) ? null : analyzeImage,
                    child: loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'AI Model Analyzing...',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                        : Text(
                            activeMode == 0
                                ? AppLocalizations.of(context)!.analyzeLeaf
                                : activeMode == 1
                                    ? AppTranslations.get('fruit_ripeness_mode', Provider.of<LocaleProvider>(context, listen: false).locale.languageCode)
                                    : AppTranslations.get('detect_weed_species', Provider.of<LocaleProvider>(context, listen: false).locale.languageCode),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🌟 Dynamic Feature Showcase Card
              _buildFeatureCard(),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // 📖 Browse Diseases Guide Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiseaseGalleryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(AppLocalizations.of(context)!.browseGuide),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    side: const BorderSide(color: AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎛️ Mode Selector Cards Component
  Widget _buildModeSelector() {
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _buildModeTab(0, AppTranslations.get('plant_disease_mode', langCode), Icons.eco_rounded, Colors.green),
          _buildModeTab(1, AppTranslations.get('fruit_ripeness_mode', langCode), Icons.apple_rounded, Colors.orange),
          _buildModeTab(2, AppTranslations.get('weed_detection_mode', langCode), Icons.grass_rounded, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildModeTab(
      int index, String title, IconData icon, Color activeColor) {
    final bool isSelected = activeMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!loading) {
            setState(() {
              activeMode = index;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 Mode Header Banner
  Widget _buildModeHeaderBanner() {
    final langCode = Provider.of<LocaleProvider>(context).locale.languageCode;
    String title = activeMode == 0
        ? AppTranslations.get('plant_disease_mode', langCode)
        : activeMode == 1
            ? AppTranslations.get('fruit_ripeness_mode', langCode)
            : AppTranslations.get('weed_detection_mode', langCode);

    String subtitle = activeMode == 0
        ? AppTranslations.get('select_capture_leaf', langCode)
        : activeMode == 1
            ? AppTranslations.get('select_capture_fruit', langCode)
            : AppTranslations.get('select_capture_weed', langCode);

    IconData icon = activeMode == 0
        ? Icons.coronavirus_rounded
        : activeMode == 1
            ? Icons.bakery_dining_rounded
            : Icons.spa_rounded;

    MaterialColor badgeColor = activeMode == 0
        ? Colors.green
        : activeMode == 1
            ? Colors.orange
            : Colors.teal;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<int>(activeMode),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [badgeColor.withValues(alpha: 0.12), badgeColor.withValues(alpha: 0.04)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: badgeColor.shade900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌾 Interactive Field & Irrigation Telemetry Card
  Widget _buildFieldContextCard() {
    Color moistureColor;
    if (_soilMoisture < 30) {
      moistureColor = Colors.orange.shade800;
    } else if (_soilMoisture <= 65) {
      moistureColor = Colors.green.shade700;
    } else {
      moistureColor = Colors.blue.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isFieldContextExpanded
              ? Colors.teal.shade300
              : Colors.grey.shade200,
          width: _isFieldContextExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header clickable toggle
          InkWell(
            onTap: () {
              setState(() {
                _isFieldContextExpanded = !_isFieldContextExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Field & Irrigation Telemetry',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'AI Multi-factor',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isFieldContextExpanded
                              ? 'Calibrate crop, stage & soil moisture for water diagnostics'
                              : '$_selectedCropType • $_selectedGrowthStage • Soil ${_soilMoisture.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isFieldContextExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
            ),
          ),

          // Collapsed quick overview badges
          if (!_isFieldContextExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildQuickPill(Icons.grass_rounded, _selectedCropType, Colors.green.shade700),
                  _buildQuickPill(Icons.trending_up_rounded, _selectedGrowthStage, Colors.amber.shade900),
                  _buildQuickPill(Icons.water_rounded, 'Soil ${_soilMoisture.toInt()}%', moistureColor),
                  _buildQuickPill(Icons.wb_sunny_rounded, '${_temperature.toInt()}°C', Colors.deepOrange),
                  _buildQuickPill(Icons.calendar_today_rounded, '$_daysSinceIrrigation d ago', Colors.indigo),
                ],
              ),
            ),

          // Expanded drawer controls
          if (_isFieldContextExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Crop Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Target Crop Species',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _selectedCropType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _cropTypes.map((crop) {
                        final isSel = _selectedCropType == crop;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(crop),
                            selected: isSel,
                            selectedColor: Colors.teal.shade700,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : Colors.black87,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedCropType = crop);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Growth Stage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Growth Phenology Stage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _selectedGrowthStage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _growthStages.map((stage) {
                        final isSel = _selectedGrowthStage == stage;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(stage),
                            selected: isSel,
                            selectedColor: Colors.amber.shade800,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : Colors.black87,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedGrowthStage = stage);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Soil Moisture Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Current Soil Moisture',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _soilMoisture < 30
                                ? '(Low - Stressed)'
                                : (_soilMoisture <= 65
                                    ? '(Adequate - Optimal)'
                                    : '(High / Saturated)'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: moistureColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_soilMoisture.toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: moistureColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: moistureColor,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: moistureColor,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _soilMoisture,
                      min: 10.0,
                      max: 90.0,
                      divisions: 16,
                      label: '${_soilMoisture.toInt()}%',
                      onChanged: (val) {
                        setState(() => _soilMoisture = val);
                      },
                    ),
                  ),

                  // 4. Secondary Telemetry Grid (Temperature, Last Irrigation, Field Condition)
                  Row(
                    children: [
                      // Days since irrigation
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Irrigated',
                                style: TextStyle(
                                    fontSize: 9.5, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _daysSinceIrrigation,
                                  isDense: true,
                                  isExpanded: true,
                                  items: [1, 2, 4, 7, 10, 14].map((d) {
                                    return DropdownMenuItem<int>(
                                      value: d,
                                      child: Text(
                                        '$d d ago',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _daysSinceIrrigation = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Temperature
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Temperature',
                                style: TextStyle(
                                    fontSize: 9.5, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<double>(
                                  value: _temperature,
                                  isDense: true,
                                  isExpanded: true,
                                  items: [24.0, 28.0, 32.0, 36.0, 40.0].map((t) {
                                    return DropdownMenuItem<double>(
                                      value: t,
                                      child: Text(
                                        '${t.toInt()}°C',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _temperature = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Field Condition
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Field Bed',
                                style: TextStyle(
                                    fontSize: 9.5, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _fieldCondition,
                                  isDense: true,
                                  isExpanded: true,
                                  items: _fieldConditions.map((c) {
                                    return DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _fieldCondition = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  // Helpful note
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: Colors.teal.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'AI correlates foliar symptoms with field moisture to prescribe irrigation.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImageScannerBox() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: AppConstants.defaultBorderRadius,
        border: Border.all(
          color: imageFile != null
              ? AppConstants.primaryColor
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: AppConstants.defaultBorderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: imageFile != null
                  ? Image.file(imageFile!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          activeMode == 0
                              ? Icons.add_a_photo_rounded
                              : activeMode == 1
                                  ? Icons.apple_rounded
                                  : Icons.grass_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeMode == 0
                              ? AppLocalizations.of(context)!.selectImageHint
                              : activeMode == 1
                                  ? "Select or capture fruit image"
                                  : "Select or capture weed image",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),

            // Pulsating Laser Scan Animation when analyzing
            if (loading)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Dark Overlay
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                      // Moving Laser Bar
                      Positioned(
                        top: _scanAnimation.value * 240,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.lightGreenAccent,
                                Colors.greenAccent,
                                Colors.transparent
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 3,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 🌟 Feature Showcase Component Card
  Widget _buildFeatureCard() {
    String headline = activeMode == 0
        ? '14 Crops & 38 Diseases Supported'
        : activeMode == 1
            ? '131 Fruits & Vegetables Supported'
            : '9 Farmland Weed Species Supported';

    String details = activeMode == 0
        ? 'AI model detects plant health & pathology for Tomato, Potato, Corn, Grape, Apple, Citrus, Pepper, Peach, Strawberry, Cherry, Soybean, Squash, Blueberry, and Raspberry.'
        : activeMode == 1
            ? 'Fruits-360 ResNet50 classifier identifies apples, bananas, citrus, berries, mangoes, grapes, tomatoes, and vegetables with instant nutritional overview.'
            : 'DeepWeeds MobileNetV2 classifier detects Chinee Apple, Lantana, Parkinsonia, Parthenium, Prickly Acacia, Rubber Vine, Siam Weed, Snake Weed & Negative control.';

    IconData badgeIcon = activeMode == 0
        ? Icons.verified_rounded
        : activeMode == 1
            ? Icons.eco_rounded
            : Icons.shield_rounded;

    Color badgeColor = activeMode == 0
        ? Colors.green.shade700
        : activeMode == 1
            ? Colors.orange.shade700
            : Colors.teal.shade700;

    return Card(
      elevation: 0,
      color: badgeColor.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(badgeIcon, color: badgeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  headline,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade800, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
