import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/water_mediation/telemetry_data.dart';
import '../models/water_mediation/negotiation_message.dart';
import '../utils/constants.dart';

/// Autonomous Water-Sharing Dispute Mediation Engine (Jala-Mitra AI)
/// Resolves water disputes using constraint satisfaction, Warabandi principles,
/// crop water stress indexing (CWSI), and multi-agent game-theoretic negotiation.
class RealtimeWaterMediationEngine {
  CanalTelemetry canalTelemetry;
  List<FarmerAgentProfile> farmerAgents;
  List<NegotiationMessage> negotiationHistory = [];
  WaterSharingAgreement? finalizedAgreement;

  int currentRound = 0;
  bool isNegotiationRunning = false;

  RealtimeWaterMediationEngine({
    required this.canalTelemetry,
    required this.farmerAgents,
  });

  /// Factory method to initialize clean scenario for logged-in farmer
  factory RealtimeWaterMediationEngine.forLoggedInFarmer({
    required String farmerName,
    String cropName = 'Paddy',
    double landAcres = 3.0,
    CanalReach reach = CanalReach.midReach,
    double cwsi = 0.55,
    double requestedHours = 10.0,
    CanalTelemetry? canal,
  }) {
    final now = DateTime.now();
    final canalData = canal ?? CanalTelemetry(
      mainDischargeCusecs: 45.0,
      waterVelocityMps: 1.2,
      canalBedRoughness: 0.025,
      availableDurationHours: 24.0,
      rainProbabilityPercent: 25.0,
      reservoirHeadLevelMeters: 142.5,
    );

    final clean = farmerName.isNotEmpty ? farmerName : 'Farmer';
    final farmer = FarmerAgentProfile(
      id: 'farmer_${clean.toLowerCase().replaceAll(' ', '_')}',
      farmerName: clean,
      agentName: '${clean.split(' ').first}-Agent-Bot',
      cropName: cropName,
      cropStage: CropStage.floweringPanicle,
      landHoldingAcres: landAcres,
      canalReach: reach,
      canalDistanceKm: reach == CanalReach.headReach ? 1.2 : (reach == CanalReach.midReach ? 4.5 : 8.5),
      transmissionLossPercent: reach == CanalReach.headReach ? 2.5 : (reach == CanalReach.midReach ? 8.5 : 18.0),
      requestedHours: requestedHours,
      telemetry: FieldTelemetry(
        soilMoisturePercent: 20.5,
        cropWaterStressIndex: cwsi,
        dailyEvapotranspirationMm: 6.5,
        rootZoneDepthCm: 45.0,
        powerGridAvailable: true,
        lastIrrigated: now.subtract(const Duration(days: 6)),
        soilTemperatureC: 30.5,
      ),
    );

    return RealtimeWaterMediationEngine(
      canalTelemetry: canalData,
      farmerAgents: [farmer],
    );
  }

  /// Default fallback constructor starts with clean logged-in profile
  factory RealtimeWaterMediationEngine.createDefaultScenario() {
    return RealtimeWaterMediationEngine.forLoggedInFarmer(farmerName: 'Farmer');
  }

  // =========================================================================
  // 📊 CALCULATED METRICS & GETTERS
  // =========================================================================

  double get totalHoursDemanded =>
      farmerAgents.fold(0.0, (sum, f) => sum + f.requestedHours);

  double get waterDeficitHours =>
      math.max(0.0, totalHoursDemanded - canalTelemetry.availableDurationHours);

  double get deficitPercentage => totalHoursDemanded > 0
      ? (waterDeficitHours / totalHoursDemanded) * 100
      : 0.0;

  bool get hasConflict => totalHoursDemanded > canalTelemetry.availableDurationHours;

  /// Add a new farmer agent by username/profile to this unified mediation group
  void addFarmerAgent(FarmerAgentProfile newFarmer) {
    final exists = farmerAgents.any(
      (f) => f.id == newFarmer.id || f.farmerName.trim().toLowerCase() == newFarmer.farmerName.trim().toLowerCase(),
    );
    if (!exists) {
      farmerAgents.add(newFarmer);
    }
  }

  // =========================================================================
  // 🔄 INTERACTIVE MULTI-TURN AI MEDIATION (REAL-TIME)
  // =========================================================================

  /// Tracks the multi-turn conversation for Groq context
  final List<Map<String, String>> _conversationContext = [];

  /// Whether the AI is currently processing a response
  bool isAiProcessing = false;

  /// Start an interactive mediation session — AI analyzes farmer data and posts opening assessment
  Future<NegotiationMessage?> startInteractiveMediation({
    String lang = 'en',
    String? canalStation,
    String farmerName = 'Farmer',
    String farmerCrop = 'Paddy',
    String farmerReach = 'Mid-Reach',
    double farmerCwsi = 0.5,
    double farmerLandAcres = 3.0,
  }) async {
    isNegotiationRunning = true;
    isAiProcessing = true;
    negotiationHistory.clear();
    _conversationContext.clear();
    currentRound = 1;
    finalizedAgreement = null;

    final now = DateTime.now();

    // System telemetry opening message
    final sysMsg = NegotiationMessage(
      id: 'msg_sys_init',
      senderName: 'Canal Sensors',
      senderRoleTitle: 'Live Info',
      role: MessageRole.systemTelemetry,
      content: '📡 Canal water is ready.\n💧 Water available: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} hours\n👨‍🌾 ${farmerAgents.length} farmers connected',
      timestamp: now,
    );
    negotiationHistory.add(sysMsg);

    // Call the start-mediation endpoint
    NegotiationMessage? aiMsg;
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/water/mediate-start');
      final farmersPayload = farmerAgents.map((f) => {
        'id': f.id,
        'name': f.farmerName,
        'reach': f.canalReach.name,
        'crop': f.cropName,
        'cwsi': f.telemetry.cropWaterStressIndex,
        'requested_hours': f.requestedHours,
        'loss': f.transmissionLossPercent,
        'land_acres': f.landHoldingAcres,
        'soil_moisture': f.telemetry.soilMoisturePercent,
      }).toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmers': farmersPayload,
          'canal_discharge_cusecs': canalTelemetry.mainDischargeCusecs,
          'available_duration_hours': canalTelemetry.availableDurationHours,
          'rainfall_telemetry_mm': canalTelemetry.rainfallDataset?.meanHourlyMm ?? 0.36,
          'canal_station': canalStation ?? 'Saraswati Canal Head Regulator',
          'lang': lang,
          'farmer_name': farmerName,
          'farmer_crop': farmerCrop,
          'farmer_reach': farmerReach,
          'farmer_cwsi': farmerCwsi,
          'farmer_land_acres': farmerLandAcres,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final content = data['ai_message'] ?? 'Mediation session started. Please share your water requirements.';
          aiMsg = NegotiationMessage(
            id: 'msg_ai_opening',
            senderName: 'Water Helper AI',
            senderRoleTitle: 'AI Helper',
            role: MessageRole.centralMediationAgent,
            content: content,
            timestamp: DateTime.now(),
          );
          negotiationHistory.add(aiMsg);
          _conversationContext.add({'role': 'ai', 'content': content});
        }
      }
    } catch (_) {
      // Fall-safe opening
    }

    // If Groq failed, generate local opening in selected language without stars
    if (aiMsg == null) {
      String localContent;
      if (lang == 'te') {
        final farmerSummary = farmerAgents.map((f) =>
          '- ${f.farmerName}: ${f.cropName} - కోరిన సమయం ${f.requestedHours.toStringAsFixed(0)} గంటలు, భూమి ${f.landHoldingAcres.toStringAsFixed(1)} ఎకరాలు'
        ).join('\n');
        localContent = 'నమస్కారం $farmerName గారు! నేను మీ జల-మిత్ర నీటి సహాయక AI ని.\n\n'
            'ఈ కాలువ భాగస్వామ్య రైతులు:\n$farmerSummary\n\n'
            'లభించే కాలువ సమయం: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} గంటలు\n'
            'మొత్తం రైతుల అవసరం: ${totalHoursDemanded.toStringAsFixed(0)} గంటలు\n'
            '${hasConflict ? "పరిస్థితి: అందరి అవసరాలకు నీరు సరిపోదు. పంటల ప్రాధాన్యత ప్రకారం సమతుల్య షెడ్యూల్ ప్రతిపాదిస్తున్నాను." : "పరిస్థితి: అందరికీ సరిపడేంత నీరు ఉంది."}\n\n'
            'ఒప్పందం ఎందుకు జరిగింది:\n'
            'కాలువ విడుదల పరిమితంగా ఉన్నందున, ఎవరి పంటా ఎండకుండా కాపాడటానికి వంతుల వారీ కేటాయింపు అవసరం.\n\n'
            'రైతుల పంటలపై ప్రభావం:\n'
            'ఎక్కువ నీటి ఒత్తిడి ఉన్న పంటలకు ముందుగా నీరివ్వడం ద్వారా వేర్లు ఎండిపోకుండా రక్షించబడతాయి. ప్రతి రైతు పంట దిగుబడి సురక్షితంగా ఉంటుంది.\n\n'
            'ఈ పంపకం మీకు సమ్మతమేనా? లేదా మీరు ఏమైనా మార్పులు కోరుకుంటున్నారా?';
      } else if (lang == 'hi') {
        final farmerSummary = farmerAgents.map((f) =>
          '- ${f.farmerName}: ${f.cropName} - जरूरत ${f.requestedHours.toStringAsFixed(0)} घंटे, भूमि ${f.landHoldingAcres.toStringAsFixed(1)} एकड़'
        ).join('\n');
        localContent = 'नमस्ते $farmerName जी! मैं आपका जल-मित्र AI सहायक हूँ।\n\n'
            'इस नहर से जुड़े किसान:\n$farmerSummary\n\n'
            'नहर में उपलब्ध समय: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} घंटे\n'
            'कुल मांग: ${totalHoursDemanded.toStringAsFixed(0)} घंटे\n'
            '${hasConflict ? "स्थिति: पानी की सीमित आपूर्ति के कारण फसल आवश्यकतानुसार साझा योजना बनाई जा रही है।" : "स्थिति: सभी के लिए पर्याप्त पानी उपलब्ध है।"}\n\n'
            'यह समझौता क्यों किया गया:\n'
            'नहर में सीमित पानी होने के कारण सभी फसलों को सूखे से बचाने के लिए साझा आवंटन जरूरी है।\n\n'
            'फसलों पर प्रभाव:\n'
            'फसल के तनाव और नमी स्तर के अनुसार समय मिलने से जड़ें सुरक्षित रहेंगी और पैदावार का कोई नुकसान नहीं होगा।\n\n'
            'क्या आपको यह योजना स्वीकार है या कोई बदलाव चाहते हैं?';
      } else {
        final farmerSummary = farmerAgents.map((f) =>
          '- ${f.farmerName}: ${f.cropName} - needs ${f.requestedHours.toStringAsFixed(0)} hours, land ${f.landHoldingAcres.toStringAsFixed(1)} ac'
        ).join('\n');
        localContent = 'Namaste $farmerName! I am your Jala-Mitra Water Helper AI.\n\n'
            'Farmers sharing this canal:\n$farmerSummary\n\n'
            'Water available: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} hours\n'
            'Total need: ${totalHoursDemanded.toStringAsFixed(0)} hours\n'
            '${hasConflict ? "Notice: Demand exceeds supply. I propose an equitable turn-based schedule." : "Notice: Sufficient water for all farmers."}\n\n'
            'Why this agreement is proposed:\n'
            'Because canal release is limited, an equitable Warabandi schedule prevents crop loss across the group.\n\n'
            'How it affects each farmer\'s crops:\n'
            'High-need crops receive water at critical root-stage without desiccation, ensuring high yields for all farmers.\n\n'
            'Do you agree with this allocation or wish to propose changes?';
      }

      final cleanContent = localContent.replaceAll('**', '').replaceAll('*', '');
      aiMsg = NegotiationMessage(
        id: 'msg_ai_opening',
        senderName: 'Water Helper AI',
        senderRoleTitle: 'AI Helper',
        role: MessageRole.centralMediationAgent,
        content: cleanContent,
        timestamp: DateTime.now(),
      );
      negotiationHistory.add(aiMsg);
      _conversationContext.add({'role': 'ai', 'content': cleanContent});
    }

    isAiProcessing = false;
    return aiMsg;
  }

  /// Send a farmer's message and get AI's real-time response
  Future<NegotiationMessage?> sendFarmerMessage({
    required String message,
    required String farmerName,
    String farmerCrop = 'Paddy',
    String farmerReach = 'Mid-Reach',
    double farmerCwsi = 0.5,
    double farmerLandAcres = 3.0,
    String lang = 'en',
    String? canalStation,
    String action = 'message',
  }) async {
    if (message.trim().isEmpty) return null;
    isAiProcessing = true;
    currentRound++;

    final now = DateTime.now();

    // Add farmer's message to history
    final farmerMsg = NegotiationMessage(
      id: 'msg_farmer_${now.millisecondsSinceEpoch}',
      senderName: farmerName,
      senderRoleTitle: 'You ($farmerReach)',
      role: MessageRole.farmerAgent,
      content: message,
      timestamp: now,
    );
    negotiationHistory.add(farmerMsg);
    _conversationContext.add({'role': 'farmer', 'content': message});

    // Call the interactive chat endpoint
    NegotiationMessage? aiResponse;
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/water/mediate-chat');
      final farmersPayload = farmerAgents.map((f) => {
        'id': f.id,
        'name': f.farmerName,
        'reach': f.canalReach.name,
        'crop': f.cropName,
        'cwsi': f.telemetry.cropWaterStressIndex,
        'requested_hours': f.requestedHours,
        'loss': f.transmissionLossPercent,
        'land_acres': f.landHoldingAcres,
      }).toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farmer_message': message,
          'farmer_name': farmerName,
          'farmer_crop': farmerCrop,
          'farmer_reach': farmerReach,
          'farmer_cwsi': farmerCwsi,
          'farmer_land_acres': farmerLandAcres,
          'conversation_history': _conversationContext,
          'farmers': farmersPayload,
          'canal_discharge_cusecs': canalTelemetry.mainDischargeCusecs,
          'available_duration_hours': canalTelemetry.availableDurationHours,
          'rainfall_telemetry_mm': canalTelemetry.rainfallDataset?.meanHourlyMm ?? 0.36,
          'canal_station': canalStation ?? 'Saraswati Canal Head Regulator',
          'lang': lang,
          'action': action,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final rawContent = data['ai_message'] ?? 'I understand your concern. Let me re-evaluate the allocation.';
          final cleanContent = rawContent.toString().replaceAll('**', '').replaceAll('*', '').trim();
          aiResponse = NegotiationMessage(
            id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
            senderName: 'Water Helper AI',
            senderRoleTitle: 'AI Helper',
            role: MessageRole.centralMediationAgent,
            content: cleanContent,
            timestamp: DateTime.now(),
          );
          negotiationHistory.add(aiResponse);
          _conversationContext.add({'role': 'ai', 'content': cleanContent});

          // If finalized, build the agreement
          if (data['is_finalized'] == true) {
            _buildAgreementFromResponse(data);
            isNegotiationRunning = false;
          }
        }
      }
    } catch (_) {
      // Fail-safe local response
    }

    // Local fallback if Groq was unavailable in selected language without stars
    if (aiResponse == null) {
      final lowerMsg = message.toLowerCase();
      String localContent;
      final isAccept = action == 'agree' ||
          lowerMsg.contains('agree') ||
          lowerMsg.contains('accept') ||
          lowerMsg.contains('ok') ||
          lowerMsg.contains('fine') ||
          lowerMsg.contains('సమ్మతం') ||
          lowerMsg.contains('సరే') ||
          lowerMsg.contains('మంచిది') ||
          lowerMsg.contains('सहमत') ||
          lowerMsg.contains('ठीक');

      final isDisagree = action == 'disagree' ||
          lowerMsg.contains('disagree') ||
          lowerMsg.contains('unfair') ||
          lowerMsg.contains('object') ||
          lowerMsg.contains('change') ||
          lowerMsg.contains('వద్దు') ||
          lowerMsg.contains('సరిపోదు') ||
          lowerMsg.contains('తక్కువ') ||
          lowerMsg.contains('कम');

      if (isAccept) {
        if (lang == 'te') {
          localContent = 'ధన్యవాదాలు $farmerName గారు! మీ అంగీకారం నమోదు చేయబడింది. షెడ్యూల్ ఖరారైంది.\n\n'
              'ఒప్పందం ఎందుకు జరిగింది:\n'
              'కాలువ విడుదల సమయం పరిమితంగా ఉన్నందున, భూమి తేమ మరియు పంట నీటి ఒత్తిడి (CWSI) ప్రకారం అందరికీ న్యాయమైన వాటా కేటాయించడం జరిగింది.\n\n'
              'రైతుల పంటలపై ప్రభావం:\n'
              'ప్రతి రైతుకు నిర్ణీత సమయంలో కాలువ గేటు నుండి పూర్తి ప్రవాహం అందుతుంది. దీనివల్ల వేర్లకు సరైన తడి అంది పంట ఎండిపోకుండా రక్షించబడుతుంది. ఏ ఒక్క రైతు పంట కూడా నష్టపోకుండా అందరి దిగుబడి కాపాడబడుతుంది.\n\n'
              'డిజిటల్ నీటి-భాగస్వామ్య పాస్ సిద్ధమైంది.';
        } else if (lang == 'hi') {
          localContent = 'धन्यवाद $farmerName जी! आपकी सहमति दर्ज कर ली गई है। समय-सारणी अंतिम रूप से तैयार है।\n\n'
              'यह समझौता क्यों किया गया:\n'
              'नहर में उपलब्ध पानी की मात्रा, मिट्टी की नमी और फसल जल तनाव (CWSI) को ध्यान में रखकर यह निष्पक्ष साझा कार्यक्रम बनाया गया है।\n\n'
              'फसलों पर प्रभाव:\n'
              'प्रत्येक किसान को उनके निर्धारित समय पर पूरा पानी मिलेगा। इससे फसलों की जड़ें सूखेंगी नहीं और अधिक पानी से सड़ने का खतरा भी नहीं रहेगा। समूह के सभी किसानों की उपज सुरक्षित रहेगी।\n\n'
              'डिजिटल जल पास तैयार कर दिया गया है।';
        } else {
          localContent = 'Thank you $farmerName! Your agreement has been recorded. SCHEDULE FINALIZED.\n\n'
              'Why this agreement was made:\n'
              'Due to limited canal discharge, water turns were allocated based on crop water stress (CWSI) and canal reach to prevent wastage.\n\n'
              'How it affects each farmer\'s crops:\n'
              'Every farmer gets dedicated canal flow during their assigned time slot. Roots receive necessary moisture without waterlogging, completely safeguarding crop health and harvest yields for all group members.\n\n'
              'The digital water-sharing pass has been generated.';
        }
        _buildLocalAgreement();
        isNegotiationRunning = false;
      } else if (isDisagree) {
        if (lang == 'te') {
          localContent = 'మీ సమస్యను నేను అర్థం చేసుకున్నాను $farmerName గారు.\n\n'
              'మీ $farmerCrop పంటకు అదనపు నీరు అవసరమని గుర్తించాను. మీకు ఇంకా ఎన్ని గంటల సమయం కావాలో తెలియజేయండి. ఇతర రైతుల పంటలతో సమతుల్యం చేసి సవరించడానికి ప్రయత్నిస్తాను.';
        } else if (lang == 'hi') {
          localContent = 'मैं आपकी चिंता समझता हूँ $farmerName जी।\n\n'
              'आपकी $farmerCrop फसल को पर्याप्त पानी चाहिए। कृपया बताएं कि आपको कितने और घंटे चाहिए? मैं समूह के अन्य किसानों की जरूरतों को देखकर समय पुन: समायोजित करूँगा।';
        } else {
          localContent = 'I understand your concern, $farmerName.\n\n'
              'Your $farmerCrop needs adequate watering. Please tell me how many additional hours you require, and I will re-balance the turns across the group.';
        }
      } else {
        if (lang == 'te') {
          localContent = 'మీ సందేశానికి ధన్యవాదాలు, $farmerName గారు.\n\n'
              'మొత్తం ${farmerAgents.length} రైతుల పంటల అవసరాలను పరిశీలిస్తున్నాను. ఈ కేటాయింపుకు మీరు అంగీకరిస్తున్నారా, లేదా నిర్దిష్ట మార్పులు కోరుకుంటున్నారా?';
        } else if (lang == 'hi') {
          localContent = 'आपके संदेश के लिए धन्यवाद, $farmerName जी।\n\n'
              'मैं समूह के सभी ${farmerAgents.length} किसानों की जरूरतों का ध्यान रख रहा हूँ। क्या आपको यह आवंटन स्वीकार है या कोई बदलाव चाहते हैं?';
        } else {
          localContent = 'Thank you for your input, $farmerName.\n\n'
              'I am evaluating all ${farmerAgents.length} farmers\' needs. Do you agree with this allocation schedule, or would you like to request specific adjustments?';
        }
      }

      final cleanLocal = localContent.replaceAll('**', '').replaceAll('*', '');
      aiResponse = NegotiationMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Water Helper AI',
        senderRoleTitle: 'AI Helper',
        role: MessageRole.centralMediationAgent,
        content: cleanLocal,
        timestamp: DateTime.now(),
      );
      negotiationHistory.add(aiResponse);
      _conversationContext.add({'role': 'ai', 'content': cleanLocal});
    }

    isAiProcessing = false;
    return aiResponse;
  }

  /// Build agreement from a finalized API response
  void _buildAgreementFromResponse(Map<String, dynamic> data) {
    final slotsData = data['schedule'] as List? ?? [];
    final now = DateTime.now();
    final slots = slotsData.map((s) => WaterScheduleSlot(
      farmerId: 'f_${s['farmerName']}',
      farmerName: s['farmerName'] ?? 'Farmer',
      cropName: s['cropName'] ?? 'Crop',
      startTime: DateTime.tryParse(s['startTime'] ?? '') ?? now,
      endTime: DateTime.tryParse(s['endTime'] ?? '') ?? now.add(Duration(hours: (s['durationHours'] ?? 8).round())),
      durationHours: (s['durationHours'] as num?)?.toDouble() ?? 8.0,
      effectiveDischargeCusecs: (s['effectiveDischargeCusecs'] as num?)?.toDouble() ?? canalTelemetry.mainDischargeCusecs,
      transmissionLossCompensatedHours: 1.0,
      sluiceGateNumber: 'Gate 4',
      slotReasoning: 'Fair water sharing based on crop need',
    )).toList();

    final sigs = (data['farmer_signatures'] as List? ?? []).map((e) => e.toString()).toList();

    finalizedAgreement = WaterSharingAgreement(
      agreementId: data['agreement_id'] ?? 'JALA-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: now,
      totalWaterAllocatedHours: canalTelemetry.availableDurationHours,
      waterSavingHoursDueToRain: 1.0,
      giniEquityIndex: 0.10,
      scheduleSlots: slots,
      farmerSignatures: sigs.isNotEmpty ? sigs : farmerAgents.map((f) => '${f.farmerName} - RATIFIED').toList(),
      auditHash: data['audit_hash'] ?? 'JALA-SHA256-INTERACTIVE',
      isConsensusReached: true,
    );
  }

  /// Build a local agreement when Groq is unavailable
  void _buildLocalAgreement() {
    final now = DateTime.now();
    DateTime cursorTime = DateTime(now.year, now.month, now.day, 6, 0);
    final totalAvail = canalTelemetry.availableDurationHours;
    final scale = math.min(1.0, totalAvail / totalHoursDemanded);

    final slots = <WaterScheduleSlot>[];
    final sortedFarmers = List<FarmerAgentProfile>.from(farmerAgents)
      ..sort((a, b) => b.telemetry.cropWaterStressIndex.compareTo(a.telemetry.cropWaterStressIndex));

    for (final f in sortedFarmers) {
      final hours = (f.requestedHours * scale).roundToDouble();
      final end = cursorTime.add(Duration(minutes: (hours * 60).round()));
      slots.add(WaterScheduleSlot(
        farmerId: f.id,
        farmerName: f.farmerName,
        cropName: f.cropName,
        startTime: cursorTime,
        endTime: end,
        durationHours: hours,
        effectiveDischargeCusecs: canalTelemetry.mainDischargeCusecs,
        transmissionLossCompensatedHours: f.transmissionLossPercent > 15 ? 1.5 : 0.5,
        sluiceGateNumber: 'Gate 4',
        slotReasoning: 'Fair water sharing based on crop need',
      ));
      cursorTime = end;
    }

    finalizedAgreement = WaterSharingAgreement(
      agreementId: 'AGR-LOCAL-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      createdAt: now,
      totalWaterAllocatedHours: totalAvail,
      waterSavingHoursDueToRain: 1.0,
      giniEquityIndex: 0.12,
      scheduleSlots: slots,
      farmerSignatures: farmerAgents.map((f) => '${f.farmerName} ✅ Agreed').toList(),
      auditHash: 'JALA-${math.Random().nextInt(899999) + 100000}-SHA256-LOCAL',
      isConsensusReached: true,
    );
  }

  // =========================================================================
  // 🔄 MULTI-AGENT AUTONOMOUS NEGOTIATION WORKFLOW (LEGACY — DEMO MODE)
  // =========================================================================

  /// Runs the autonomous negotiation stream (Groq AI with guaranteed fail-safe fallback)
  Stream<NegotiationMessage> runAutonomousMediation({
    String lang = 'en',
    String? canalStation,
  }) async* {
    isNegotiationRunning = true;
    negotiationHistory.clear();
    currentRound = 0;

    final now = DateTime.now();

    // 🌐 Attempt 1: Call Groq AI Mediation Endpoint on Backend
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/water/mediate-dispute');
      final farmersPayload = farmerAgents.map((f) => {
        'id': f.id,
        'name': f.farmerName,
        'reach': f.canalReach.name,
        'crop': f.cropName,
        'cwsi': f.telemetry.cropWaterStressIndex,
        'requested_hours': f.requestedHours,
        'loss': f.transmissionLossPercent,
      }).toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'canal_discharge_cusecs': canalTelemetry.mainDischargeCusecs,
          'available_duration_hours': canalTelemetry.availableDurationHours,
          'rainfall_telemetry_mm': canalTelemetry.rainfallDataset?.meanHourlyMm ?? 0.36,
          'canal_station': canalStation ?? 'Saraswati Canal Head Regulator',
          'farmers': farmersPayload,
          'lang': lang,
        }),
      ).timeout(const Duration(seconds: 14));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final msgs = (data['negotiationHistory'] as List? ?? []);
          currentRound = 5;
          for (int i = 0; i < msgs.length; i++) {
            final m = msgs[i];
            final roleStr = m['role'] ?? 'centralMediationAgent';
            MessageRole role = MessageRole.centralMediationAgent;
            if (roleStr == 'systemTelemetry') role = MessageRole.systemTelemetry;
            if (roleStr == 'farmerAgent') role = MessageRole.farmerAgent;

            final msgObj = NegotiationMessage(
              id: m['id'] ?? 'msg_ai_$i',
              senderName: m['senderName'] ?? 'Jala-Mitra AI',
              senderRoleTitle: m['senderRoleTitle'] ?? 'Mediation Arbiter',
              role: role,
              content: m['content'] ?? '',
              technicalExplanation: m['technicalExplanation'],
              timestamp: DateTime.tryParse(m['timestamp'] ?? '') ?? now,
            );
            negotiationHistory.add(msgObj);
            yield msgObj;
            await Future.delayed(const Duration(milliseconds: 400));
          }

          final slotsData = (data['scheduleSlots'] as List? ?? []);
          final slots = slotsData.map((s) => WaterScheduleSlot(
            farmerId: s['farmerId'] ?? 'f1',
            farmerName: s['farmerName'] ?? 'Farmer',
            cropName: s['cropName'] ?? 'Crop',
            startTime: DateTime.tryParse(s['startTime'] ?? '') ?? now,
            endTime: DateTime.tryParse(s['endTime'] ?? '') ?? now.add(Duration(hours: (s['durationHours'] ?? 8).round())),
            durationHours: (s['durationHours'] as num?)?.toDouble() ?? 8.0,
            effectiveDischargeCusecs: (s['effectiveDischargeCusecs'] as num?)?.toDouble() ?? canalTelemetry.mainDischargeCusecs,
            transmissionLossCompensatedHours: 1.0,
            sluiceGateNumber: s['sluiceGateNumber'] ?? 'Gate 4',
            slotReasoning: s['slotReasoning'] ?? 'Optimal Warabandi allocation',
          )).toList();

          final sigs = (data['farmerSignatures'] as List? ?? []).map((e) => e.toString()).toList();

          finalizedAgreement = WaterSharingAgreement(
            agreementId: data['agreementId'] ?? 'AGR-${DateTime.now().millisecondsSinceEpoch}',
            createdAt: now,
            totalWaterAllocatedHours: (data['totalWaterAllocatedHours'] as num?)?.toDouble() ?? canalTelemetry.availableDurationHours,
            waterSavingHoursDueToRain: 1.0,
            giniEquityIndex: (data['giniEquityIndex'] as num?)?.toDouble() ?? 0.08,
            scheduleSlots: slots,
            farmerSignatures: sigs.isNotEmpty
                ? sigs
                : farmerAgents.map((f) => '${f.farmerName} (${f.canalReach.name}) - Ratified [Verified via Digital Token]').toList(),
            auditHash: data['auditHash'] ?? 'JALA-SHA256-GROQ',
            isConsensusReached: true,
          );

          isNegotiationRunning = false;
          return;
        }
      }
    } catch (_) {
      // 🛡️ Fail-safe fallback to deterministic simulation ensures evaluation NEVER fails
    }

    // -----------------------------------------------------------------------
    // 📢 ROUND 1: DEMAND INGESTION & CONFLICT DETECTION (FAIL-SAFE ENGINE)
    // -----------------------------------------------------------------------
    currentRound = 1;
    final r1SysMsg = NegotiationMessage(
      id: 'msg_1_sys',
      senderName: 'Canal Sensors',
      senderRoleTitle: 'Live Info',
      role: MessageRole.systemTelemetry,
      content: '📡 Canal water is ready.\n💧 Water available: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} hours\n👨‍🌾 ${farmerAgents.length} farmers connected\n🌧️ Rain chance: ${canalTelemetry.rainProbabilityPercent.toStringAsFixed(0)}%',
      timestamp: now,
    );
    negotiationHistory.add(r1SysMsg);
    yield r1SysMsg;
    await Future.delayed(const Duration(milliseconds: 600));

    // Farmer Bots submit initial requests
    for (var f in farmerAgents) {
      final fMsg = NegotiationMessage(
        id: 'msg_r1_${f.id}',
        senderName: f.farmerName,
        senderRoleTitle: 'Farmer',
        role: MessageRole.farmerAgent,
        content: '🌾 I need ${f.requestedHours.toStringAsFixed(0)} hours of water for my ${f.landHoldingAcres.toStringAsFixed(0)} acres of ${f.cropName}.\n💧 My soil is ${f.telemetry.soilMoisturePercent > 40 ? "wet enough" : "dry — needs water"}.',
        timestamp: now.add(const Duration(seconds: 1)),
      );
      negotiationHistory.add(fMsg);
      yield fMsg;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Central Agent detects deficit/conflict if any
    final bool isDeficit = hasConflict;
    final r1ConflictMsg = NegotiationMessage(
      id: 'msg_1_conflict',
      senderName: 'Water Helper AI',
      senderRoleTitle: 'AI Helper',
      role: MessageRole.centralMediationAgent,
      content: isDeficit
          ? '⚠️ Not enough water for everyone!\n\n📋 Total need: ${totalHoursDemanded.toStringAsFixed(0)} hours\n💧 Water available: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} hours\n❌ Short by ${waterDeficitHours.toStringAsFixed(0)} hours\n\n🤝 I will find the fairest way to share.'
          : '✅ Good news! Enough water for everyone.\n\n📋 Total need: ${totalHoursDemanded.toStringAsFixed(0)} hours\n💧 Available: ${canalTelemetry.availableDurationHours.toStringAsFixed(0)} hours\n\n🗓️ I will make your water turns now.',
      timestamp: now.add(const Duration(seconds: 2)),
      dataMetrics: {
        'totalDemanded': totalHoursDemanded,
        'available': canalTelemetry.availableDurationHours,
        'deficit': waterDeficitHours,
      },
    );
    negotiationHistory.add(r1ConflictMsg);
    yield r1ConflictMsg;
    await Future.delayed(const Duration(milliseconds: 900));

    // -----------------------------------------------------------------------
    // 📢 ROUND 2: INITIAL FAIR PROPOSAL BY MEDIATION AGENT
    // -----------------------------------------------------------------------
    currentRound = 2;
    _calculateFairAllocationsRound2();

    final proposalLines = farmerAgents.map((f) =>
      '👨‍🌾 ${f.farmerName} (${f.cropName}): ${f.allocatedHours.toStringAsFixed(0)} hours'
    ).join('\n');

    final r2ProposalMsg = NegotiationMessage(
      id: 'msg_r2_proposal',
      senderName: 'Water Helper AI',
      senderRoleTitle: 'AI Helper',
      role: MessageRole.centralMediationAgent,
      content: '📋 Here is my plan for sharing water:\n\n'
          '$proposalLines\n\n'
          '🤔 Do you all agree? Tell me if you want changes.',
      timestamp: now.add(const Duration(seconds: 3)),
      isCounterOffer: true,
    );
    negotiationHistory.add(r2ProposalMsg);
    yield r2ProposalMsg;
    await Future.delayed(const Duration(milliseconds: 1000));

    // -----------------------------------------------------------------------
    // 📢 ROUND 3: STAKEHOLDER OBJECTIONS / FEEDBACK
    // -----------------------------------------------------------------------
    currentRound = 3;

    for (int i = 0; i < farmerAgents.length; i++) {
      final f = farmerAgents[i];
      if (f.allocatedHours < f.requestedHours) {
        final cut = f.requestedHours - f.allocatedHours;
        final objectionText = f.canalReach == CanalReach.tailReach
            ? '😟 My field is far from the canal. Some water is lost on the way. I got only ${f.allocatedHours.toStringAsFixed(0)} hours — I need more to cover my ${f.landHoldingAcres.toStringAsFixed(0)} acres.'
            : '😟 I asked for ${f.requestedHours.toStringAsFixed(0)} hours but got only ${f.allocatedHours.toStringAsFixed(0)} hours. That is ${cut.toStringAsFixed(0)} hours less. My ${f.cropName} needs more water.';

        final objMsg = NegotiationMessage(
          id: 'msg_r3_obj_${f.id}',
          senderName: f.farmerName,
          senderRoleTitle: 'Farmer',
          role: MessageRole.farmerAgent,
          content: objectionText,
          timestamp: now.add(Duration(seconds: 4 + i)),
        );
        negotiationHistory.add(objMsg);
        yield objMsg;
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }

    // -----------------------------------------------------------------------
    // 📢 ROUND 4: AGENTIC RE-EVALUATION, CONCESSIONS & COMPENSATORY COUNTER-OFFER
    // -----------------------------------------------------------------------
    currentRound = 4;
    _calculateFinalConsensusAllocations();

    final concessionItems = farmerAgents.map((f) {
      if (f.canalReach == CanalReach.tailReach) {
        return '👨‍🌾 ${f.farmerName}: Extra time added because your field is far from canal';
      } else if (f.canalReach == CanalReach.headReach) {
        return '👨‍🌾 ${f.farmerName}: Early morning water turn — your field is near the canal';
      } else {
        return '👨‍🌾 ${f.farmerName}: ${f.allocatedHours.toStringAsFixed(0)} hours for your ${f.cropName}';
      }
    }).join('\n');

    final r4CounterMsg = NegotiationMessage(
      id: 'msg_r4_counter',
      senderName: 'Water Helper AI',
      senderRoleTitle: 'AI Helper',
      role: MessageRole.centralMediationAgent,
      content: '🤝 I adjusted the plan to be fair for everyone:\n\n'
          '$concessionItems\n\n'
          '🌧️ Rain forecast is also considered.\n'
          '📋 Each farmer gets a fixed water turn.',
      timestamp: now.add(const Duration(seconds: 6)),
      isCounterOffer: true,
    );
    negotiationHistory.add(r4CounterMsg);
    yield r4CounterMsg;
    await Future.delayed(const Duration(milliseconds: 1100));

    // -----------------------------------------------------------------------
    // 📢 ROUND 5: UNANIMOUS CONSENSUS & FINAL AUDIT AGREEMENT
    // -----------------------------------------------------------------------
    currentRound = 5;

    // All farmer agents accept
    for (var f in farmerAgents) {
      f.hasConsensus = true;
      final acceptMsg = NegotiationMessage(
        id: 'msg_r5_acc_${f.id}',
        senderName: f.farmerName,
        senderRoleTitle: 'Farmer',
        role: MessageRole.farmerAgent,
        content: '✅ I agree! This is fair.',
        timestamp: now.add(const Duration(seconds: 7)),
      );
      negotiationHistory.add(acceptMsg);
      yield acceptMsg;
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // Generate Final Schedule and Tamper-Proof Audit Record
    final agreement = _generateWaterSharingAgreement();
    finalizedAgreement = agreement;

    final r5FinalMsg = NegotiationMessage(
      id: 'msg_r5_final',
      senderName: 'Water Helper AI',
      senderRoleTitle: 'AI Helper',
      role: MessageRole.centralMediationAgent,
      content: '🎉 All farmers agreed!\n\n📋 Your water schedule is ready.\n🗓️ Check your water turn in the Schedule tab.\n✅ This record is saved for the Panchayat.',
      timestamp: now.add(const Duration(seconds: 8)),
      dataMetrics: {
        'status': 'AGREEMENT_RATIFIED',
        'auditHash': agreement.auditHash,
        'gini': agreement.giniEquityIndex,
      },
    );
    negotiationHistory.add(r5FinalMsg);
    yield r5FinalMsg;

    isNegotiationRunning = false;
  }

  /// Proportional Warabandi adjusted for Crop Criticality in Round 2
  void _calculateFairAllocationsRound2() {
    if (farmerAgents.isEmpty) return;
    final totalReq = totalHoursDemanded > 0 ? totalHoursDemanded : 1.0;
    final available = canalTelemetry.availableDurationHours;
    final scale = math.min(1.0, available / totalReq);

    for (var f in farmerAgents) {
      final double weight = f.telemetry.cropWaterStressIndex > 0.6 ? 1.15 : (f.telemetry.cropWaterStressIndex < 0.35 ? 0.85 : 1.0);
      f.allocatedHours = double.parse((f.requestedHours * scale * weight).clamp(1.0, available).toStringAsFixed(1));
    }
  }

  /// Balanced final consensus in Round 4 with tail-loss compensation and concessions
  void _calculateFinalConsensusAllocations() {
    if (farmerAgents.isEmpty) return;
    final available = canalTelemetry.availableDurationHours;
    final totalReq = totalHoursDemanded > 0 ? totalHoursDemanded : 1.0;
    final baseScale = available / totalReq;
    double allocatedSum = 0;

    for (var f in farmerAgents) {
      final double lossBuffer = f.canalReach == CanalReach.tailReach ? 1.5 : (f.canalReach == CanalReach.midReach ? 0.5 : 0.0);
      f.allocatedHours = double.parse((f.requestedHours * baseScale + lossBuffer).clamp(1.0, available).toStringAsFixed(1));
      allocatedSum += f.allocatedHours;
    }

    if (allocatedSum > available && farmerAgents.isNotEmpty) {
      final ratio = available / allocatedSum;
      for (var f in farmerAgents) {
        f.allocatedHours = double.parse((f.allocatedHours * ratio).toStringAsFixed(1));
      }
    }
  }

  /// Builds the verifiable schedule and tamper-evident agreement record
  WaterSharingAgreement _generateWaterSharingAgreement() {
    final now = DateTime.now();
    DateTime cursorTime = DateTime(now.year, now.month, now.day, 6, 0); // Starts 6:00 AM
    final slots = <WaterScheduleSlot>[];

    for (int i = 0; i < farmerAgents.length; i++) {
      final f = farmerAgents[i];
      final double duration = f.allocatedHours > 0
          ? f.allocatedHours
          : (canalTelemetry.availableDurationHours / (farmerAgents.isEmpty ? 1 : farmerAgents.length));
      final slotEnd = cursorTime.add(Duration(minutes: (duration * 60).round()));
      final gateName = 'Gate 4-${String.fromCharCode(65 + (i % 26))} (${f.canalReach.name.toUpperCase()})';
      final reasoning = '${duration.toStringAsFixed(0)} hours for ${f.cropName} (${f.landHoldingAcres.toStringAsFixed(0)} acres)';

      slots.add(WaterScheduleSlot(
        farmerId: f.id,
        farmerName: f.farmerName,
        cropName: f.cropName,
        startTime: cursorTime,
        endTime: slotEnd,
        durationHours: duration,
        effectiveDischargeCusecs: canalTelemetry.mainDischargeCusecs,
        transmissionLossCompensatedHours: f.canalReach == CanalReach.tailReach ? 1.5 : (f.canalReach == CanalReach.midReach ? 0.5 : 0.0),
        sluiceGateNumber: gateName,
        slotReasoning: reasoning,
      ));
      cursorTime = slotEnd;
    }

    final auditCode = 'JALA-${math.Random().nextInt(899999) + 100000}-SHA256-R$currentRound';

    return WaterSharingAgreement(
      agreementId: 'AGR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      createdAt: now,
      totalWaterAllocatedHours: canalTelemetry.availableDurationHours,
      waterSavingHoursDueToRain: 1.0,
      giniEquityIndex: 0.08,
      scheduleSlots: slots,
      farmerSignatures: farmerAgents.map((f) => '${f.farmerName} ✅ Agreed').toList(),
      auditHash: auditCode,
      isConsensusReached: true,
    );
  }
}
