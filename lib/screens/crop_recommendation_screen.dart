import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/voice_service.dart';

class CropRecommendationScreen extends StatefulWidget {
  final List<dynamic>? data;
  final String? soil;
  final String? season;
  final String? rainfall;
  final String? district;
  
  const CropRecommendationScreen({
    super.key,
    this.data,
    this.soil,
    this.season,
    this.rainfall,
    this.district,
  });

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen>
    with SingleTickerProviderStateMixin {
  
  late List<Map<String, dynamic>> predictions;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  String? _currentlySpeakingCrop;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    predictions = widget.data != null 
        ? List<Map<String, dynamic>>.from(widget.data!) 
        : [];
        
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    VoiceService.stop();
    _controller.dispose();
    super.dispose();
  }

  String cropImage(String crop) {
    return 'assets/crops/${crop.toLowerCase().trim()}.jpg';
  }

  String _t(String key) {
    final lang = Localizations.localeOf(context).languageCode;
    final dict = {
      'water_requirements': {'en': 'Crop Water Requirements', 'te': 'పంట నీటి అవసరాలు', 'hi': 'फसल जल आवश्यकता'},
      'total_water_need': {'en': 'Total Need', 'te': 'మొత్తం నీరు', 'hi': 'कुल आवश्यकता'},
      'critical_stages': {'en': 'Critical Growth Stages', 'te': 'కీలక దశలు', 'hi': 'महत्वपूर्ण अवस्थाएं'},
      'irrigation_method': {'en': 'Irrigation Technique', 'te': 'సాగునీటి విధానం', 'hi': 'सिंचाई विधि'},
      'rainfall_water_balance': {'en': 'Rainfall & Water Balance', 'te': 'వర్షపాతం & నీటి సమతుల్యత', 'hi': 'वर्षा एवं जल संतुलन'},
      'rainfall_coverage': {'en': 'Rainfall Coverage', 'te': 'వర్షపాత భర్తీ', 'hi': 'वर्षा पूर्ति'},
      'ai_suitability': {'en': 'AI Suitability Explanation', 'te': 'AI పంట అనుకూలత విశ్లేషణ', 'hi': 'AI फसल उपयुक्तता विश्लेषण'},
      'listen': {'en': 'Listen to AI', 'te': 'వినండి', 'hi': 'सुनें'},
      'turn_off_speaker': {'en': 'Turn Off Speaker', 'te': 'స్పీకర్ ఆపండి', 'hi': 'स्पीकर बंद करें'},
      'speaking': {'en': 'Speaking...', 'te': 'వివరిస్తోంది...', 'hi': 'बोल रहा है...'},
      'farm_conditions_title': {'en': 'Farm Parameters Evaluated', 'te': 'పరిశీలించిన వివరాలు', 'hi': 'मूल्यांकन किए गए पैरामीटर'},
    };
    return dict[key]?[lang] ?? dict[key]?['en'] ?? key;
  }

  void _toggleSpeech(String crop, String text) async {
    if (_isSpeaking && _currentlySpeakingCrop == crop) {
      await _turnOffSpeaker();
      return;
    }
    final lang = Localizations.localeOf(context).languageCode;
    await VoiceService.stop();
    if (!mounted) return;
    setState(() {
      _isSpeaking = true;
      _currentlySpeakingCrop = crop;
    });

    await VoiceService.speak(text, lang);

    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _currentlySpeakingCrop = null;
      });
    }
  }

  Future<void> _turnOffSpeaker() async {
    await VoiceService.stop();
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _currentlySpeakingCrop = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Speaker turned off"),
          duration: Duration(milliseconds: 1200),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Top Recommended Crops'),
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off, color: Colors.amber),
              tooltip: _t('turn_off_speaker'),
              onPressed: _turnOffSpeaker,
            ),
        ],
      ),
      body: VoiceWrapper(
        screenTitle: AppLocalizations.of(context)!.cropRecommendation,
        textToRead: predictions.isEmpty 
            ? "No recommendations found." 
            : "Found ${predictions.length} recommended crops with complete water requirements and rainfall telemetry analysis.",
        child: predictions.isEmpty 
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grass_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No recommendations found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        )
      : SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Global Speaking Active Bar
                if (_isSpeaking)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${_t('speaking')} (${_currentlySpeakingCrop ?? ''})",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _turnOffSpeaker,
                          icon: const Icon(Icons.volume_off_rounded, size: 14),
                          label: Text(_t('turn_off_speaker'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Farm Conditions Summary Chips
                if (widget.soil != null || widget.season != null || widget.rainfall != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        Text(
                          _t('farm_conditions_title'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.soil != null)
                              _buildParamChip(Icons.landscape_rounded, "${widget.soil} Soil", Colors.brown),
                            if (widget.season != null)
                              _buildParamChip(Icons.wb_sunny_rounded, "${widget.season} Season", Colors.orange),
                            if (widget.rainfall != null)
                              _buildParamChip(Icons.water_drop_rounded, "${widget.rainfall} Rainfall", Colors.blue),
                            if (widget.district != null)
                              _buildParamChip(Icons.location_on_rounded, widget.district!, Colors.teal),
                          ],
                        ),
                      ],
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                  child: Text(
                    "Best crops suited for your parameters with water & rainfall analysis:",
                    style: TextStyle(fontSize: 14.5, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ...predictions.map(_cropCard),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParamChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color.shade900),
          ),
        ],
      ),
    );
  }

  Widget _cropCard(Map<String, dynamic> item) {
    final crop = item['crop']?.toString() ?? 'Crop';
    final confidence = (item['confidence'] as num?)?.toDouble() ?? 80.0;
    final rank = item['rank'] ?? 1;
    final desc = item['description']?.toString() ?? '';

    final waterReq = (item['water_requirement'] as Map?)?.cast<String, dynamic>() ?? {};
    final rfAnalysis = (item['rainfall_analysis'] as Map?)?.cast<String, dynamic>() ?? {};
    final aiExplanation = item['ai_suitability_explanation']?.toString() ?? desc;

    final isThisCropSpeaking = _isSpeaking && _currentlySpeakingCrop == crop;

    // Define medal colors based on rank
    Color rankColor = AppConstants.primaryColor;
    if (rank == 1) rankColor = Colors.amber.shade700;
    if (rank == 2) rankColor = Colors.blueGrey.shade600;
    if (rank == 3) rankColor = Colors.brown.shade600;

    // Coverage percentage for progress bar
    final coveragePct = (rfAnalysis['coverage_pct'] as num?)?.toDouble() ?? 100.0;
    final clampedCoverage = (coveragePct / 150.0).clamp(0.0, 1.0);

    Color coverageColor = Colors.green.shade600;
    if (coveragePct < 65.0) {
      coverageColor = Colors.deepOrange.shade600;
    } else if (coveragePct < 95.0) {
      coverageColor = Colors.amber.shade700;
    }

    return Card(
      elevation: 3.5,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: AppConstants.defaultBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Header Row: Rank Badge & Match Score
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: rankColor.withValues(alpha: 0.12),
                         shape: BoxShape.circle,
                       ),
                       child: Icon(Icons.emoji_events_rounded, color: rankColor, size: 20),
                     ),
                     const SizedBox(width: 10),
                     Text(
                         "Rank $rank - ${crop.toUpperCase()}",
                         style: TextStyle(
                           fontSize: 17.5,
                           fontWeight: FontWeight.bold,
                           color: rankColor,
                          ),
                     ),
                   ],
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(
                     color: rankColor.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                   ),
                   child: Text(
                     "${confidence.toStringAsFixed(1)}% Match",
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 12.5,
                       color: rankColor,
                     ),
                   ),
                 ),
               ],
             ),
              const SizedBox(height: 14),

              // Crop Image
              ClipRRect(
                  borderRadius: AppConstants.defaultBorderRadius,
                  child: Image.asset(
                    cropImage(crop),
                     width: double.infinity,
                     height: 150,
                     fit: BoxFit.cover,
                     errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 130,
                          color: Colors.grey.shade100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.grass_rounded, size: 44, color: Colors.grey.shade300),
                              const SizedBox(height: 6),
                              Text(crop, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                     },
                   ),
              ),

              const SizedBox(height: 16),

              // Match Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                    value: confidence / 100,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade200,
                    color: rankColor,
                ),
              ),

              const SizedBox(height: 18),

              // 💧 1. CROP WATER REQUIREMENTS BOX
              if (waterReq.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, color: Color(0xFF1976D2), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _t('water_requirements'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              waterReq['category']?.toString() ?? 'Standard Demand',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // Water need metric
                      Row(
                        children: [
                          const Text(
                            "Total Requirement: ",
                            style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            waterReq['range_mm']?.toString() ?? '500 - 650 mm',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Critical Stages
                      if (waterReq['critical_stages'] != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Critical Stages: ",
                              style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: Text(
                                waterReq['critical_stages'].toString(),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),

                      // Recommended Method
                      if (waterReq['irrigation_method'] != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Best Technique: ",
                              style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: Text(
                                waterReq['irrigation_method'].toString(),
                                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              // 🌧️ 2. RAINFALL TELEMETRY & WATER BALANCE
              if (rfAnalysis.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.teal.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_sync_rounded, color: Color(0xFF00796B), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _t('rainfall_water_balance'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: coverageColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rfAnalysis['status_title']?.toString() ?? 'Evaluated',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: coverageColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Coverage progress bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_t('rainfall_coverage')}: ${coveragePct.toStringAsFixed(0)}%",
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            "Est. Rain: ${(rfAnalysis['estimated_rainfall_mm'] as num?)?.toStringAsFixed(0) ?? '750'} mm",
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: clampedCoverage,
                          minHeight: 7,
                          backgroundColor: Colors.grey.shade200,
                          color: coverageColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Irrigation balance advice
                      if (rfAnalysis['advice'] != null)
                        Text(
                          rfAnalysis['advice'].toString(),
                          style: const TextStyle(fontSize: 12.5, height: 1.35, color: Colors.black87),
                        ),
                    ],
                  ),
                ),

              // 🤖 3. AI SUITABILITY EXPLANATION CARD (STAR-FREE + VOICE SPEAKER)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50.withValues(alpha: 0.7), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.35), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Card Header with Speaker Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppConstants.primaryColor, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "AI Suitability Analysis",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),

                        // Prominent Audio Read Aloud / Turn Off Speaker Button
                        ElevatedButton.icon(
                          onPressed: () => _toggleSpeech(crop, aiExplanation),
                          icon: Icon(
                            isThisCropSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            size: 14,
                          ),
                          label: Text(
                            isThisCropSpeaking ? _t('turn_off_speaker') : _t('listen'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isThisCropSpeaking ? Colors.red.shade600 : AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Clean Star-Free Explanation
                    Text(
                      aiExplanation,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Colors.black87,
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

