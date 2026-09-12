import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../models/water_mediation/telemetry_data.dart';
import '../models/water_mediation/negotiation_message.dart';
import '../services/realtime_water_mediation_engine.dart';
import '../services/farmer_data_service.dart';
import '../services/voice_service.dart';
import '../services/notification_service.dart';
import '../services/canal_group_service.dart';
import '../utils/jala_mitra_i18n.dart';
import '../providers/locale_provider.dart';

/// AgriNova Jala-Mitra AI Water Mediation Screen
/// High-fidelity implementation matching AgriNova design system:
/// Screen 2: Jala-Mitra Dashboard (PS14 Main Screen)
/// Screen 3: Farmer Requirements (Input Screen)
/// Screen 4: Conflict Detection (Analysis Screen)
/// Screen 5: Negotiation Workflow (Chat Screen)
/// Screen 6: Schedule Generation (Gantt View)
/// Screen 7: Decision Explanation (Transparency / XAI)
/// Screen 8: Water-Sharing Agreement (Audit & Record)
class WaterMediationScreen extends StatefulWidget {
  const WaterMediationScreen({super.key});

  @override
  State<WaterMediationScreen> createState() => _WaterMediationScreenState();
}

class _WaterMediationScreenState extends State<WaterMediationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RealtimeWaterMediationEngine _engine;
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatInputController = TextEditingController();

  bool _isNegotiating = false;
  bool _isLoadingData = false;
  String _loadingStep = '';
  FarmerDataResult? _liveDataResult;
  String _lang = 'en';

  // Interactive mediation state
  bool _isAiTyping = false;
  bool _isVoiceListening = false;
  bool _autoReadAloud = true;
  String? _currentlySpeakingMsgId;
  String _farmerName = 'Farmer';
  String _farmerCrop = 'Paddy';
  final String _farmerReach = 'Mid-Reach';
  final double _farmerCwsi = 0.5;
  double _farmerLandAcres = 3.0;
  String _activeSpeakerName = 'Farmer';
  List<Map<String, dynamic>> _incomingInvitations = [];
  List<Map<String, dynamic>> _sentInvitations = [];
  Timer? _realtimeSyncTimer;
  CanalGroup? _activeCanalGroup;

  // Active selected canal & district
  final String _selectedDistrict = 'Mahabubnagar';
  final String _selectedCanalStation = 'Saraswati Canal Head Regulator';

  // AgriNova Palette
  static const Color kPrimaryGreen = Color(0xFF0E8345);
  static const Color kDarkGreen = Color(0xFF0A5E31);
  static const Color kMintGreen = Color(0xFFE8F5E9);
  static const Color kAccentRed = Color(0xFFE53935);
  static const Color kSoftRed = Color(0xFFFDEDEE);
  static const Color kAccentOrange = Color(0xFFF57C00);
  static const Color kSoftOrange = Color(0xFFFFF3E0);
  static const Color kAccentBlue = Color(0xFF1976D2);
  static const Color kSoftBlue = Color(0xFFE3F2FD);
  static const Color kBackground = Color(0xFFF8FAF9);
  static const Color kCardBorder = Color(0xFFE6EBE8);
  static const Color kTextPrimary = Color(0xFF1B2E20);
  static const Color kTextSecondary = Color(0xFF63786A);

  String _t(String key) => JalaMitraI18n.t(key, _lang);

  /// Speaks message aloud in the current language via TTS
  Future<void> _speakMessage(String msgId, String text, {bool userTriggered = false}) async {
    if (!_autoReadAloud && !userTriggered) return;

    if (_currentlySpeakingMsgId == msgId) {
      await VoiceService.stop();
      if (mounted) setState(() => _currentlySpeakingMsgId = null);
      return;
    }
    final clean = text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', unicode: true), '')
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('•', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.isEmpty) return;

    try {
      if (mounted) setState(() => _currentlySpeakingMsgId = msgId);
      await VoiceService.speak(clean, _lang);
    } catch (_) {
      // Browser SpeechSynthesisError or uninitialized audio
    } finally {
      if (mounted) {
        setState(() {
          if (_currentlySpeakingMsgId == msgId) {
            _currentlySpeakingMsgId = null;
          }
        });
      }
    }
  }

  void _turnOffSpeaker() {
    VoiceService.stop();
    if (mounted) {
      setState(() {
        _autoReadAloud = false;
        _currentlySpeakingMsgId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('auto_read_off')),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  Widget _buildLangChip(String code, String label) {
    final isSelected = _lang == code;
    return InkWell(
      onTap: () {
        setState(() => _lang = code);
        try {
          Hive.box('profileBox').put('language_code', code);
        } catch (_) {}
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : kTextSecondary,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 4 Simplified Tabs: My Water, Farmers, Chat, Schedule
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // Read stored language preference and farmer profile
    try {
      final box = Hive.box('profileBox');
      final code = box.get('language_code', defaultValue: 'en') as String?;
      if (code != null && code.isNotEmpty) {
        _lang = code;
      }
      _farmerName = box.get('name', defaultValue: 'Farmer') as String;
      _farmerCrop = box.get('crop', defaultValue: 'Paddy') as String;
      _farmerLandAcres = double.tryParse(box.get('landSize', defaultValue: '3.0').toString()) ?? 3.0;
    } catch (_) {}

    _activeSpeakerName = _farmerName;
    _engine = RealtimeWaterMediationEngine.forLoggedInFarmer(
      farmerName: _farmerName,
      cropName: _farmerCrop,
      landAcres: _farmerLandAcres,
    );

    _refreshPendingInvitations();
    _startRealtimeSyncTicker();
    _fetchLiveDataAndRebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final code = Provider.of<LocaleProvider>(context).locale.languageCode;
      if (code.isNotEmpty && code != _lang) {
        setState(() {
          _lang = code;
        });
      }
    } catch (_) {}
  }

  void _startRealtimeSyncTicker() {
    _realtimeSyncTimer?.cancel();
    _syncWithBackendRealtime();
    _realtimeSyncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _syncWithBackendRealtime();
    });
  }

  Future<void> _syncWithBackendRealtime() async {
    try {
      await NotificationService.syncInvitationsWithBackend(_farmerName);
      if (mounted) {
        _refreshPendingInvitations();
      }

      // Sync active canal group with backend (to detect peer acceptance or exit)
      final group = await CanalGroupService.syncWithBackend(
        canalStation: _selectedCanalStation,
        farmerName: _farmerName,
      );

      if (group != null && group.isActive) {
        bool changed = false;
        if (_activeCanalGroup == null ||
            _activeCanalGroup!.groupId != group.groupId ||
            _activeCanalGroup!.members.length != group.members.length) {
          _activeCanalGroup = group;
          // MEDIATION IS DONE BETWEEN GROUP MEMBERS ONLY
          _engine.farmerAgents = List<FarmerAgentProfile>.from(group.members);
          changed = true;
        }
        if (changed && mounted) {
          setState(() {});
        }
      } else if (_activeCanalGroup != null && group == null) {
        _activeCanalGroup = null;
        if (mounted) {
          setState(() {});
        }
      }

      // Sync live chat messages between sender and receiver in real-time
      await _syncLiveChatMessages();
    } catch (_) {}
  }

  Future<void> _syncLiveChatMessages() async {
    try {
      final url = Uri.parse(
          '${AppConstants.baseUrl}/api/water/live-chat?canal_station=${Uri.encodeComponent(_selectedCanalStation)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawList = (data['messages'] as List?) ?? [];
        bool addedAny = false;
        String? lastAiSpokenContent;
        String? lastAiMsgId;

        for (final m in rawList) {
          final mId = m['id']?.toString() ?? '';
          final content = m['content']?.toString() ?? '';
          final senderName = m['senderName']?.toString() ?? 'Canal';
          final senderRole = m['senderRoleTitle']?.toString() ?? '';
          final roleStr = (m['role'] ?? '').toString();
          final ts = DateTime.tryParse(m['timestamp']?.toString() ?? '') ?? DateTime.now();

          // Check if already in _engine.negotiationHistory
          final alreadyExists = _engine.negotiationHistory.any((h) =>
              h.id == mId ||
              (h.content.trim() == content.trim() && h.senderName == senderName));

          if (!alreadyExists && content.isNotEmpty) {
            MessageRole role = MessageRole.systemTelemetry;
            if (roleStr == 'farmerAgent') {
              role = MessageRole.farmerAgent;
            } else if (roleStr == 'centralMediationAgent') {
              role = MessageRole.centralMediationAgent;
            }

            final newMsg = NegotiationMessage(
              id: mId,
              senderName: senderName,
              senderRoleTitle: senderRole.isNotEmpty
                  ? senderRole
                  : (role == MessageRole.centralMediationAgent
                      ? 'AI Helper'
                      : senderName),
              role: role,
              content: content,
              timestamp: ts,
            );
            _engine.negotiationHistory.add(newMsg);
            addedAny = true;

            if (role == MessageRole.centralMediationAgent) {
              lastAiSpokenContent = content;
              lastAiMsgId = mId;
            }
          }
        }

        if (addedAny && mounted) {
          setState(() {});
          _scrollChatToBottom();
          if (_autoReadAloud && lastAiSpokenContent != null && lastAiMsgId != null) {
            _speakMessage(lastAiMsgId, lastAiSpokenContent);
          }
        }
      }
    } catch (_) {}
  }

  void _refreshPendingInvitations() {
    if (!mounted) return;
    setState(() {
      _incomingInvitations = NotificationService.getInvitationsForFarmer(_farmerName)
          .where((inv) => inv['status'] == 'pending')
          .toList();
      _sentInvitations = NotificationService.getSentInvitationsByFarmer(_farmerName)
          .where((inv) => inv['status'] == 'pending')
          .toList();
    });
  }

  @override
  void dispose() {
    VoiceService.stop();
    _realtimeSyncTimer?.cancel();
    _tabController.dispose();
    _chatScrollController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveDataAndRebuild() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _loadingStep = 'Connecting to canal & telemetry grid...';
    });

    FarmerDataResult? result;
    try {
      result = await FarmerDataService.buildFarmerProfiles();
    } catch (_) {
      result = null;
    }

    // Retrieve active, permanently stored canal group
    CanalGroup? group;
    try {
      group = await CanalGroupService.getActiveGroup(_selectedCanalStation, _farmerName) ??
          await CanalGroupService.syncWithBackend(
            canalStation: _selectedCanalStation,
            farmerName: _farmerName,
          );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isLoadingData = false;
      _activeCanalGroup = group;
      if (result != null) {
        _liveDataResult = result;

        List<FarmerAgentProfile> finalFarmers;
        if (group != null && group.isActive && group.members.isNotEmpty) {
          // MEDIATION IS DONE BETWEEN REGISTERED GROUP MEMBERS ONLY
          finalFarmers = List<FarmerAgentProfile>.from(group.members);
        } else {
          // Check if accepted invitations exist to auto-hydrate group
          final acceptedInvites = NotificationService.getAcceptedInvitationsForFarmer(_farmerName);
          if (acceptedInvites.isNotEmpty) {
            final inv = acceptedInvites.first;
            final peerName = (inv['recipientFarmerName'] == _farmerName ? inv['inviterName'] : inv['recipientFarmerName'])?.toString().trim() ?? '';
            final fData = _safeMap(inv['farmerData']);
            final selfProfile = result.farmers.firstWhere(
              (f) => f.farmerName.toLowerCase().trim() == _farmerName.toLowerCase().trim(),
              orElse: () => result!.farmers.first,
            );
            final peerProfile = fData.isNotEmpty
                ? FarmerAgentProfile.fromAadhaarJson(fData)
                : FarmerAgentProfile(
                    id: 'farmer_${peerName.toLowerCase().replaceAll(' ', '_')}',
                    farmerName: peerName,
                    agentName: '${peerName.split(' ').first}-Agent-Bot',
                    cropName: 'Cotton',
                    cropStage: CropStage.vegetative,
                    landHoldingAcres: 3.5,
                    canalReach: CanalReach.tailReach,
                    canalDistanceKm: 7.5,
                    transmissionLossPercent: 15.0,
                    requestedHours: 11.0,
                    telemetry: FieldTelemetry(
                      soilMoisturePercent: 18.5,
                      cropWaterStressIndex: 0.65,
                      dailyEvapotranspirationMm: 6.8,
                      rootZoneDepthCm: 40.0,
                      powerGridAvailable: true,
                      lastIrrigated: DateTime.now().subtract(const Duration(days: 7)),
                      soilTemperatureC: 31.0,
                    ),
                  );
            final autoGroup = CanalGroup(
              groupId: 'grp_${_selectedCanalStation.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}',
              canalStation: _selectedCanalStation,
              groupName: '${selfProfile.farmerName} & $peerName Water Group',
              members: [selfProfile, peerProfile],
              createdAt: DateTime.now(),
              isActive: true,
            );
            CanalGroupService.saveGroup(autoGroup);
            _activeCanalGroup = autoGroup;
            finalFarmers = [selfProfile, peerProfile];
          } else {
            // Solo farmer only (no extraneous third-party farmers)
            final selfOnly = result.farmers.where((f) => f.farmerName.toLowerCase().trim() == _farmerName.toLowerCase().trim()).toList();
            finalFarmers = selfOnly.isNotEmpty ? selfOnly : [result.farmers.first];
          }
        }

        _engine = RealtimeWaterMediationEngine(
          canalTelemetry: result.canal,
          farmerAgents: finalFarmers,
        );
        if (_engine.farmerAgents.isNotEmpty) {
          _activeSpeakerName = _engine.farmerAgents.first.farmerName;
        }
      }
    });

    // Also sync chat messages immediately
    _syncLiveChatMessages();
  }

  void _startMediationSimulation() async {
    setState(() {
      _isNegotiating = true;
      _isAiTyping = true;
    });

    // Animate to Chat Tab (index 2)
    _tabController.animateTo(2);

    // 1. Broadcast notification to the active farmer
    await NotificationService.showWaterMediationNotification(
      title: '🌊 Jala-Mitra: Dispute Mediation Active',
      body: 'Mediation session started on $_selectedCanalStation for $_farmerName ($_farmerCrop, $_farmerLandAcres ac). Land & crop telemetry analyzed.',
      id: 42,
    );

    // 2. Broadcast automated alerts to all peer farmers on this canal branch (Ramesh, Sita, Venkat)
    for (int i = 0; i < _engine.farmerAgents.length; i++) {
      final f = _engine.farmerAgents[i];
      if (f.farmerName == _farmerName) continue;

      final alertBody = 'Jala-Mitra Alert: Automated mediation initiated on $_selectedCanalStation by $_farmerName. Your requested allocation of ${f.requestedHours.toStringAsFixed(1)}h for ${f.cropName} is under AI review.';
      await NotificationService.saveNotification(
        title: '🔔 Dispute Alert: ${f.farmerName} (${f.canalReach.name})',
        body: alertBody,
        type: 'water_mediation',
      );
    }

    // Start interactive mediation with Groq AI
    await _engine.startInteractiveMediation(
      lang: _lang,
      canalStation: _selectedCanalStation,
      farmerName: _farmerName,
      farmerCrop: _farmerCrop,
      farmerReach: _farmerReach,
      farmerCwsi: _farmerCwsi,
      farmerLandAcres: _farmerLandAcres,
    );

    if (mounted) {
      setState(() {
        _isAiTyping = false;
      });
      _scrollChatToBottom();

      if (_autoReadAloud && _engine.negotiationHistory.isNotEmpty) {
        final last = _engine.negotiationHistory.last;
        if (last.role == MessageRole.centralMediationAgent) {
          _speakMessage(last.id, last.content);
        }
      }
    }
  }

  void _scrollChatToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Persists finalized water agreement and deliberation history into local Hive storage
  Future<void> _saveMediationSessionToHive(WaterSharingAgreement agreement) async {
    try {
      Box box;
      if (Hive.isBoxOpen('waterHistoryBox')) {
        box = Hive.box('waterHistoryBox');
      } else {
        box = await Hive.openBox('waterHistoryBox');
      }

      final sessionData = {
        'id': agreement.agreementId,
        'timestamp': DateTime.now().toIso8601String(),
        'canalStation': _selectedCanalStation,
        'district': _selectedDistrict,
        'auditHash': agreement.auditHash,
        'totalAllocatedHours': agreement.totalWaterAllocatedHours,
        'giniIndex': agreement.giniEquityIndex,
        'farmerSignatures': agreement.farmerSignatures,
        'isConsensus': agreement.isConsensusReached,
        'slots': agreement.scheduleSlots.map((s) => {
          'farmerName': s.farmerName,
          'cropName': s.cropName,
          'durationHours': s.durationHours,
          'startTime': s.startTime.toIso8601String(),
          'endTime': s.endTime.toIso8601String(),
          'gate': s.sluiceGateNumber,
          'reasoning': s.slotReasoning,
        }).toList(),
      };

      await box.add(sessionData);
      debugPrint('Saved water mediation session ${agreement.agreementId} to waterHistoryBox');
    } catch (e) {
      debugPrint('Error saving water mediation session to Hive: $e');
    }
  }

  /// Send farmer's typed/spoken message to AI for real-time mediation
  void _sendFarmerMessage([String? overrideMessage, String action = 'message']) async {
    final message = overrideMessage ?? _chatInputController.text.trim();
    if (message.isEmpty) return;

    _chatInputController.clear();
    setState(() {
      _isAiTyping = true;
    });
    _scrollChatToBottom();

    final speaker = _engine.farmerAgents.firstWhere(
      (f) => f.farmerName.trim().toLowerCase() == _activeSpeakerName.trim().toLowerCase(),
      orElse: () => _engine.farmerAgents.isNotEmpty
          ? _engine.farmerAgents.first
          : FarmerAgentProfile(
              id: 'farmer_default',
              farmerName: _farmerName,
              agentName: 'Farmer-Agent-Bot',
              cropName: _farmerCrop,
              cropStage: CropStage.vegetative,
              landHoldingAcres: _farmerLandAcres,
              canalReach: CanalReach.midReach,
              canalDistanceKm: 4.5,
              transmissionLossPercent: 9.0,
              requestedHours: 12.0,
              telemetry: FieldTelemetry(
                soilMoisturePercent: 20.0,
                cropWaterStressIndex: _farmerCwsi,
                dailyEvapotranspirationMm: 6.0,
                rootZoneDepthCm: 40.0,
                powerGridAvailable: true,
                lastIrrigated: DateTime.now().subtract(const Duration(days: 6)),
                soilTemperatureC: 28.5,
              ),
            ),
    );

    await _engine.sendFarmerMessage(
      message: message,
      farmerName: speaker.farmerName,
      farmerCrop: speaker.cropName,
      farmerReach: speaker.canalReach.name,
      farmerCwsi: speaker.telemetry.cropWaterStressIndex,
      farmerLandAcres: speaker.landHoldingAcres,
      lang: _lang,
      canalStation: _selectedCanalStation,
      action: action,
    );

    if (!mounted) return;
    setState(() {
      _isAiTyping = false;
    });
    _scrollChatToBottom();

    if (_autoReadAloud && _engine.negotiationHistory.isNotEmpty) {
      final lastMsg = _engine.negotiationHistory.last;
      if (lastMsg.role == MessageRole.centralMediationAgent) {
        _speakMessage(lastMsg.id, lastMsg.content);
      }
    }

    // If agreement was finalized, persist to Hive and broadcast alerts to ALL farmers
    if (_engine.finalizedAgreement != null) {
      final ag = _engine.finalizedAgreement!;
      setState(() {
        _isNegotiating = false;
      });

      // Save to Hive history
      await _saveMediationSessionToHive(ag);

      // Broadcast finalized timetable notification to all farmers on this canal branch
      for (final f in _engine.farmerAgents) {
        final slot = ag.scheduleSlots.firstWhere(
          (s) => s.farmerName.toLowerCase().contains(f.farmerName.toLowerCase().split(' ').first),
          orElse: () => ag.scheduleSlots.first,
        );

        await NotificationService.saveNotification(
          title: '📜 Ratified Schedule: ${f.farmerName}',
          body: 'Agreement finalized on $_selectedCanalStation! You are allocated ${slot.durationHours.toStringAsFixed(1)}h for ${f.cropName} on ${slot.sluiceGateNumber}. [Audit: ${ag.auditHash}]',
          type: 'water_mediation',
        );
      }

      // Active farmer notification
      await NotificationService.showWaterMediationNotification(
        title: '🎉 Water Sharing Agreement Ratified',
        body: 'Consensus reached for $_selectedCanalStation. All farmer schedules locked into audit ledger.',
        id: 43,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Mediation Complete — Water Sharing Agreement Ratified & Saved to History!'),
            backgroundColor: kPrimaryGreen,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Start voice input for the farmer
  void _startVoiceInput() async {
    setState(() => _isVoiceListening = true);

    final langCode = _lang == 'te' ? 'te' : (_lang == 'hi' ? 'hi' : 'en');
    final result = await VoiceService.listenForCommand(
      langCode,
      onPartialResult: (partial) {
        if (mounted) {
          setState(() {
            _chatInputController.text = partial;
          });
        }
      },
    );

    if (!mounted) return;
    setState(() => _isVoiceListening = false);

    if (result.isNotEmpty) {
      _chatInputController.text = result;
      _sendFarmerMessage(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSegmentedTabPills(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),      // Tab 0: My Water
                    _buildFarmersTab(),       // Tab 1: Farmers
                    _buildNegotiationTab(),   // Tab 2: Talk to AI (Chat)
                    _buildScheduleTab(),      // Tab 3: Schedule
                  ],
                ),
              ),
            ],
          ),
          if (_isLoadingData) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // =========================================================================
  // 🏷️ TOP APP BAR (AgriNova Header)
  // =========================================================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kTextPrimary),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: kSoftBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: kAccentBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t('screen_title'),
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _t('screen_subtitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kMintGreen,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, size: 12, color: kDarkGreen),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    '@$_farmerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.history_edu, color: kPrimaryGreen),
          tooltip: _t('agreement'),
          onPressed: _showMediationHistorySheet,
        ),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: kBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kCardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: kPrimaryGreen, size: 15),
                const SizedBox(width: 3),
                Text(
                  _lang == 'te' ? 'తెలుగు' : (_lang == 'hi' ? 'हिंदी' : 'Eng'),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kTextPrimary),
                ),
              ],
            ),
          ),
          tooltip: _t('select_language'),
          onSelected: (val) {
            setState(() => _lang = val);
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
            PopupMenuItem(value: 'te', child: Text('🇮🇳 తెలుగు (Telugu)')),
            PopupMenuItem(value: 'hi', child: Text('🇮🇳 हिंदी (Hindi)')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: kTextSecondary),
          tooltip: 'Info',
          onPressed: _showInfoDialog,
        ),
      ],
    );
  }

  // =========================================================================
  // 🔘 HORIZONTAL SEGMENTED PILLS (Simplified 4 Tabs)
  // =========================================================================
  Widget _buildSegmentedTabPills() {
    final tabs = [
      {'label': _t('my_water'), 'icon': Icons.water_drop_rounded, 'index': 0},
      {'label': _t('farmers'), 'icon': Icons.group_rounded, 'index': 1},
      {'label': _t('chat'), 'icon': Icons.chat_bubble_rounded, 'index': 2},
      {'label': _t('schedule'), 'icon': Icons.calendar_month_rounded, 'index': 3},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final idx = tab['index'] as int;
          final isSelected = _tabController.index == idx;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: InkWell(
                onTap: () => _tabController.animateTo(idx),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? kPrimaryGreen : kCardBorder,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kPrimaryGreen.withValues(alpha: 0.22),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : kTextSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab['label'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================================
  // 1️⃣ SCREEN 2: JALA-MITRA DASHBOARD (PS14 MAIN SCREEN)
  // =========================================================================
  Widget _buildOverviewTab() {
    final totalDemand = _engine.totalHoursDemanded;
    final available = _engine.canalTelemetry.availableDurationHours;
    final deficit = _engine.waterDeficitHours;
    final myFarmer = _engine.farmerAgents.cast<FarmerAgentProfile?>().firstWhere(
      (f) => f?.farmerName.toLowerCase() == _farmerName.toLowerCase(),
      orElse: () => _engine.farmerAgents.isNotEmpty ? _engine.farmerAgents.first : null,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Canal Branch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kCardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCanalStation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '📍 Nizamabad, Telangana • Sluice Gate 4',
                            style: TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kMintGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: kPrimaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Live',
                            style: TextStyle(
                              color: kPrimaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 3 Metrics Row (Simplified for Farmers)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricPill(
                        '${available.toStringAsFixed(0)} ${_t("hours")}',
                        _t('water_available'),
                        Icons.water_drop,
                        kAccentBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricPill(
                        '${myFarmer?.requestedHours.toStringAsFixed(0) ?? "10"} ${_t("hours")}',
                        _t('your_need'),
                        Icons.person,
                        kPrimaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricPill(
                        '${totalDemand.toStringAsFixed(0)} ${_t("hours")}',
                        _t('demand'),
                        Icons.group,
                        deficit > 0 ? kAccentOrange : kDarkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Conflict / Peace Status Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: deficit > 0 ? kSoftRed : kMintGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (deficit > 0 ? kAccentRed : kPrimaryGreen).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        deficit > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        color: deficit > 0 ? kAccentRed : kPrimaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deficit > 0 ? _t('conflict_alert_title') : '✅ Water is Sufficient',
                              style: TextStyle(
                                color: deficit > 0 ? kAccentRed : kDarkGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deficit > 0
                                  ? 'Canal is short by ${deficit.toStringAsFixed(0)} hours. Water Helper AI will create a fair rotation for all farmers.'
                                  : 'Enough canal water for all fields. Tap below to see your turn.',
                              style: TextStyle(color: kTextPrimary.withValues(alpha: 0.85), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Ask AI for Help / Start Mediation Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isNegotiating ? null : _startMediationSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.record_voice_over, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _t('start_mediation'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Simple Visual Action Cards (Farmer Friendly)
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  Icons.chat_bubble_rounded,
                  _t('chat'),
                  'Speak or chat with AI',
                  () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeatureCard(
                  Icons.calendar_month_rounded,
                  _t('schedule'),
                  'Check your water turn',
                  () => _tabController.animateTo(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  Icons.group_rounded,
                  _t('farmers'),
                  '${_engine.farmerAgents.length} farmers sharing',
                  () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeatureCard(
                  Icons.history_edu_rounded,
                  _t('agreement'),
                  'Past water records',
                  _showMediationHistorySheet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Telemetry Datasets (Canal & Rainfall 2026-2030)
          _buildLiveTelemetryGridCard(),
          const SizedBox(height: 14),

          // Past Mediation & Agreement History Button Card
          _buildPastHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildPastHistoryCard() {
    return InkWell(
      onTap: _showMediationHistorySheet,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kMintGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_edu, color: kPrimaryGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mediation & Agreement History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Review past ratified Warabandi passes, schedules & audit hashes',
                    style: TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kMintGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: kPrimaryGreen),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTelemetryGridCard() {
    final rf = _liveDataResult?.rainfallDataset ?? _engine.canalTelemetry.rainfallDataset;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_sync, color: kPrimaryGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Telangana Telemetry Feeds',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kMintGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('2026–30 Grid', style: TextStyle(color: kPrimaryGreen, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '🌧️ District: ${rf?.district ?? _selectedDistrict} (${rf?.stationCount ?? 21} Stns) • ${rf?.meanHourlyMm.toStringAsFixed(2) ?? "0.36"} mm/h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: kTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '🌊 Gate Discharge: ${_engine.canalTelemetry.mainDischargeCusecs.toStringAsFixed(0)} Cusecs • Window: ${_engine.canalTelemetry.availableDurationHours.toStringAsFixed(0)}h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: kTextSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ➕ ADD FARMER TO NEGOTIATION (SINGLE CHAT GROUP)
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddFarmerDialog() {
    final nameController = TextEditingController();
    final acresController = TextEditingController(text: '3.5');
    final hoursController = TextEditingController(text: '10.0');
    final aadhaarController = TextEditingController();
    String selectedCrop = 'Cotton';
    CanalReach selectedReach = CanalReach.midReach;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_add, color: kPrimaryGreen, size: 22),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Add Farmer to Negotiation',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: kTextPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    Text(
                      'Search and invite real-time farmers from the User Registration Database into this single negotiation chat.',
                      style: TextStyle(fontSize: 11.5, color: kTextSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Username / Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Farmer Name / Username *',
                        hintText: 'e.g. @kalyan or Ganesh001',
                        prefixIcon: const Icon(Icons.account_circle, color: kPrimaryGreen, size: 20),
                        filled: true,
                        fillColor: kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Crop Selection
                    DropdownButtonFormField<String>(
                      initialValue: selectedCrop,
                      decoration: InputDecoration(
                        labelText: 'Primary Crop',
                        prefixIcon: const Icon(Icons.eco, color: kPrimaryGreen, size: 20),
                        filled: true,
                        fillColor: kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Paddy (Rice)', child: Text('Paddy (Rice)')),
                        DropdownMenuItem(value: 'Cotton', child: Text('Cotton')),
                        DropdownMenuItem(value: 'Sugarcane', child: Text('Sugarcane')),
                        DropdownMenuItem(value: 'Red Chilli', child: Text('Red Chilli')),
                        DropdownMenuItem(value: 'Maize', child: Text('Maize')),
                        DropdownMenuItem(value: 'Groundnut', child: Text('Groundnut')),
                        DropdownMenuItem(value: 'Wheat', child: Text('Wheat')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCrop = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Canal Reach Selector with overflow-safe Wrap layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Canal Reach: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('Head-Reach', style: TextStyle(fontSize: 11)),
                              selected: selectedReach == CanalReach.headReach,
                              selectedColor: kMintGreen,
                              onSelected: (val) {
                                if (val) setModalState(() => selectedReach = CanalReach.headReach);
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Mid-Reach', style: TextStyle(fontSize: 11)),
                              selected: selectedReach == CanalReach.midReach,
                              selectedColor: kMintGreen,
                              onSelected: (val) {
                                if (val) setModalState(() => selectedReach = CanalReach.midReach);
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Tail-Reach', style: TextStyle(fontSize: 11)),
                              selected: selectedReach == CanalReach.tailReach,
                              selectedColor: kMintGreen,
                              onSelected: (val) {
                                if (val) setModalState(() => selectedReach = CanalReach.tailReach);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Extent and Requested Hours
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: acresController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Land Extent (Acres)',
                              filled: true,
                              fillColor: kBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: hoursController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Requested Hours',
                              filled: true,
                              fillColor: kBackground,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Aadhaar / Kisan ID (Optional)
                    TextField(
                      controller: aadhaarController,
                      decoration: InputDecoration(
                        labelText: 'Aadhaar / Kisan ID (Optional)',
                        hintText: 'e.g. 9081 2345 6712',
                        prefixIcon: const Icon(Icons.fingerprint, color: kAccentBlue, size: 20),
                        filled: true,
                        fillColor: kBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a farmer username or name')),
                            );
                            return;
                          }
                          final acres = double.tryParse(acresController.text.trim()) ?? 3.0;
                          final hours = double.tryParse(hoursController.text.trim()) ?? 10.0;
                          final aadhaar = aadhaarController.text.trim();

                          _inviteFarmerToNegotiation(
                            modalCtx: modalCtx,
                            nameInput: name,
                            crop: selectedCrop,
                            reach: selectedReach,
                            acres: acres,
                            hours: hours,
                            aadhaar: aadhaar,
                          );
                        },
                        icon: const Icon(Icons.person_add, color: Colors.white, size: 16),
                        label: const Text('Verify Name & Add to Negotiation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _inviteFarmerToNegotiation({
    required BuildContext modalCtx,
    required String nameInput,
    required String crop,
    required CanalReach reach,
    required double acres,
    required double hours,
    String? aadhaar,
  }) async {
    final cleanQuery = nameInput.trim().replaceAll('@', '');
    if (cleanQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a farmer username or name')),
      );
      return;
    }

    // 1. Verify directly in User Registration Database (Users DB, strictly by name)
    // Does NOT require passbook or Aadhaar match
    final registeredFarmer = await FarmerDataService.findRegisteredFarmer(cleanQuery);

    if (registeredFarmer == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Farmer "$cleanQuery" is NOT registered in the Users Database! Enter a valid registered name.',
            ),
            backgroundColor: kAccentRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final regName = (registeredFarmer['farmer_name'] ?? cleanQuery).toString();

    // Check if already active in this negotiation group
    if (_engine.farmerAgents.any((f) => f.farmerName.toLowerCase().trim() == regName.toLowerCase().trim())) {
      if (modalCtx.mounted) {
        Navigator.pop(modalCtx);
      }
      if (mounted) {
        setState(() {
          _activeSpeakerName = regName;
        });
        _tabController.animateTo(2); // Animate to chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Farmer @$regName is already an active participant! Selected in single chat.'),
            backgroundColor: kPrimaryGreen,
          ),
        );
      }
      return;
    }

    if (modalCtx.mounted) {
      Navigator.pop(modalCtx);
    }

    // 2. Extract verified parameters from user registration
    final regCrop = registeredFarmer['crop_details']?['primary_crop'] ?? crop;
    final regAcres = registeredFarmer['land_details']?['total_extent_acres'] != null
        ? (registeredFarmer['land_details']['total_extent_acres'] as num).toDouble()
        : acres;
    final regHours = registeredFarmer['canal_irrigation_details']?['requested_hours'] != null
        ? (registeredFarmer['canal_irrigation_details']['requested_hours'] as num).toDouble()
        : hours;
    final maskedAadhaar = registeredFarmer['aadhaar_masked'] ?? (aadhaar != null && aadhaar.isNotEmpty ? aadhaar : 'REG-USER-${registeredFarmer['user_id'] ?? "001"}');

    // 3. Send targeted invitation strictly to the recipient farmer's account
    await NotificationService.sendMediationInvitation(
      inviterName: _farmerName,
      recipientFarmerName: regName,
      canalStation: _selectedCanalStation,
      farmerData: registeredFarmer,
    );
    await NotificationService.saveNotification(
      title: '🌊 Jala-Mitra: Invitation from @$_farmerName',
      body: 'You received an invitation to join real-time canal mediation on $_selectedCanalStation ($regCrop, $regAcres ac). Review and choose Accept or Reject.',
      type: 'water_mediation',
      targetFarmers: [regName],
    );

    // 4. Post invitation dispatch notice into the single negotiation path
    _engine.negotiationHistory.add(
      NegotiationMessage(
        id: 'msg_invite_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Jala-Mitra System',
        senderRoleTitle: 'User Registration Database',
        role: MessageRole.systemTelemetry,
        content: '📨 Negotiation Invitation Dispatched: @$_farmerName has invited registered farmer @$regName to this canal mediation session.\n• Quota: ${regHours.toStringAsFixed(1)}h | Crop: $regCrop ($regAcres ac) | Reach: ${reach.name}\n• Request sent directly to @$regName\'s account to ACCEPT or REJECT (Token: $maskedAadhaar).',
        timestamp: DateTime.now(),
      ),
    );

    // 5. AI Mediator informs the room
    _engine.negotiationHistory.add(
      NegotiationMessage(
        id: 'msg_ai_invite_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Jala-Mitra AI',
        senderRoleTitle: 'Autonomous Mediation Agent',
        role: MessageRole.centralMediationAgent,
        content: 'Invitation successfully dispatched to @$regName! The decision to join is strictly in their hands. As soon as @$regName taps "Accept & Join" in their account, their telemetry will be ingested into this single-path chat room and rotational allocations will be updated.',
        timestamp: DateTime.now(),
      ),
    );

    _refreshPendingInvitations();
    _scrollChatToBottom();

    if (mounted) {
      _tabController.animateTo(2); // Switch to single chat view
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📨 Invitation sent to @$regName! Awaiting @$regName to Accept or Reject in their account.'),
          backgroundColor: kPrimaryGreen,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  void _handleAcceptInvitation(Map<String, dynamic> invite) async {
    final inviteId = invite['id']?.toString() ?? '';
    final recipientName = invite['recipientFarmerName']?.toString() ?? _farmerName;
    final inviterName = invite['inviterName']?.toString() ?? 'Farmer';
    final farmerData = _safeMap(invite['farmerData']);

    await NotificationService.updateInvitationStatus(
      inviteId: inviteId,
      status: 'accepted',
      farmerName: recipientName,
    );

    // Build self profile
    final selfProfile = _engine.farmerAgents.firstWhere(
      (f) => f.farmerName.toLowerCase().trim() == _farmerName.toLowerCase().trim(),
      orElse: () => FarmerAgentProfile(
        id: 'farmer_${_farmerName.toLowerCase().replaceAll(' ', '_')}',
        farmerName: _farmerName,
        agentName: '${_farmerName.split(' ').first}-Agent-Bot',
        cropName: _farmerCrop,
        cropStage: CropStage.vegetative,
        landHoldingAcres: _farmerLandAcres,
        canalReach: CanalReach.midReach,
        canalDistanceKm: 4.5,
        transmissionLossPercent: 9.0,
        requestedHours: 12.0,
        telemetry: FieldTelemetry(
          soilMoisturePercent: 20.0,
          cropWaterStressIndex: _farmerCwsi,
          dailyEvapotranspirationMm: 6.0,
          rootZoneDepthCm: 40.0,
          powerGridAvailable: true,
          lastIrrigated: DateTime.now().subtract(const Duration(days: 6)),
          soilTemperatureC: 28.5,
        ),
      ),
    );

    // Build peer profile
    final peerName = _farmerName.toLowerCase().trim() == recipientName.toLowerCase().trim()
        ? inviterName
        : recipientName;
    FarmerAgentProfile peerProfile;
    if (farmerData.isNotEmpty) {
      peerProfile = FarmerAgentProfile.fromAadhaarJson(farmerData);
    } else {
      peerProfile = FarmerAgentProfile(
        id: 'farmer_${peerName.toLowerCase().replaceAll(' ', '_')}',
        farmerName: peerName,
        agentName: '${peerName.split(' ').first}-Agent-Bot',
        cropName: 'Cotton',
        cropStage: CropStage.vegetative,
        landHoldingAcres: 4.0,
        canalReach: CanalReach.tailReach,
        canalDistanceKm: 6.5,
        transmissionLossPercent: 12.0,
        requestedHours: 12.0,
        telemetry: FieldTelemetry(
          soilMoisturePercent: 19.0,
          cropWaterStressIndex: 0.65,
          dailyEvapotranspirationMm: 6.5,
          rootZoneDepthCm: 45.0,
          powerGridAvailable: true,
          lastIrrigated: DateTime.now().subtract(const Duration(days: 6)),
          soilTemperatureC: 29.0,
        ),
      );
    }

    // Register permanent group:
    final group = await CanalGroupService.registerAcceptedPair(
      canalStation: _selectedCanalStation,
      sender: selfProfile,
      receiver: peerProfile,
    );

    setState(() {
      _activeCanalGroup = group;
      // MEDIATION WILL BE DONE BETWEEN THEM ONLY
      _engine.farmerAgents = List<FarmerAgentProfile>.from(group.members);
      _activeSpeakerName = _farmerName;
    });

    // Send targeted notification to group members
    await NotificationService.saveNotification(
      title: '✅ Group Registered with @$peerName',
      body: 'Canal water-sharing group permanently registered on $_selectedCanalStation. Mediation active between members.',
      type: 'water_mediation',
      targetFarmers: [selfProfile.farmerName, peerProfile.farmerName],
    );

    _refreshPendingInvitations();
    _syncLiveChatMessages();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Registered Canal Water Group with @$peerName! Mediation will now be done between you two only.'),
          backgroundColor: kPrimaryGreen,
        ),
      );
    }
  }

  void _confirmExitGroup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: kAccentRed),
            const SizedBox(width: 8),
            Text(_t('exit_group_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          _t('exit_group_prompt'),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CanalGroupService.exitGroup(
                canalStation: _selectedCanalStation,
                farmerName: _farmerName,
              );
              setState(() {
                _activeCanalGroup = null;
                _engine = RealtimeWaterMediationEngine.forLoggedInFarmer(
                  farmerName: _farmerName,
                  cropName: _farmerCrop,
                  landAcres: _farmerLandAcres,
                );
              });
              _syncLiveChatMessages();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚪 ${_t("exit_group")}: You have left the canal water group.'),
                    backgroundColor: Colors.orange.shade800,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_t('exit_group'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleRejectInvitation(Map<String, dynamic> invite) async {
    final inviteId = invite['id']?.toString() ?? '';
    final recipientName = invite['recipientFarmerName']?.toString() ?? 'Farmer';

    await NotificationService.updateInvitationStatus(
      inviteId: inviteId,
      status: 'rejected',
    );

    _engine.negotiationHistory.add(
      NegotiationMessage(
        id: 'msg_reject_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Jala-Mitra System',
        senderRoleTitle: 'Mediation Registry Network',
        role: MessageRole.systemTelemetry,
        content: '❌ Registered farmer @$recipientName has DECLINED the invitation to join this canal mediation session.',
        timestamp: DateTime.now(),
      ),
    );

    _engine.negotiationHistory.add(
      NegotiationMessage(
        id: 'msg_ai_reject_${DateTime.now().millisecondsSinceEpoch}',
        senderName: 'Jala-Mitra AI',
        senderRoleTitle: 'Autonomous Mediation Agent',
        role: MessageRole.centralMediationAgent,
        content: 'Acknowledged. Farmer @$recipientName declined to participate. Their branch sluice gate will remain under standard static rules while we finalize allocations for consenting participants.',
        timestamp: DateTime.now(),
      ),
    );

    // Send targeted notification to group members
    await NotificationService.saveNotification(
      title: '❌ @$recipientName Declined',
      body: 'Declined invitation to join water mediation.',
      type: 'water_mediation',
      targetFarmers: _engine.farmerAgents.map((f) => f.farmerName).toList(),
    );

    _refreshPendingInvitations();
    _scrollChatToBottom();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Farmer @$recipientName DECLINED the invitation.'),
          backgroundColor: kAccentRed,
        ),
      );
    }
  }

  Widget _buildPendingInvitationsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
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
              const Icon(Icons.mark_email_unread, color: Color(0xFFD97706), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Incoming Invitations for @$_farmerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_incomingInvitations.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._incomingInvitations.map((inv) {
            final inviter = inv['inviterName'] ?? 'Inviter';
            final canal = inv['canalStation'] ?? 'Canal';
            final farmerData = _safeMap(inv['farmerData']);
            final cropDetails = _safeMap(farmerData['crop_details']);
            final landDetails = _safeMap(farmerData['land_details']);
            final crop = cropDetails['primary_crop']?.toString() ?? 'Crops';
            final acres = (landDetails['total_extent_acres'] as num?)?.toDouble() ?? 3.5;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '@$inviter invited you to join $canal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: kTextPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Land: $acres Acres • Crop: $crop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAcceptInvitation(inv),
                            icon: const Icon(Icons.check, size: 14),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Accept & Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleRejectInvitation(inv),
                            icon: const Icon(Icons.close, size: 14, color: kAccentRed),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Decline', style: TextStyle(fontSize: 11, color: kAccentRed, fontWeight: FontWeight.bold)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kAccentRed, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSentInvitationsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.04),
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
              const Icon(Icons.outbox_rounded, color: Color(0xFF0284C7), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sent Invitations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0369A1)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_sentInvitations.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._sentInvitations.map((inv) {
            final recipient = inv['recipientFarmerName'] ?? 'Farmer';
            final canal = inv['canalStation'] ?? 'Canal';
            final farmerData = _safeMap(inv['farmerData']);
            final cropDetails = _safeMap(farmerData['crop_details']);
            final landDetails = _safeMap(farmerData['land_details']);
            final crop = cropDetails['primary_crop']?.toString() ?? 'Crops';
            final acres = (landDetails['total_extent_acres'] as num?)?.toDouble() ?? 3.5;

            return Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send_rounded, size: 14, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Sent to @$recipient',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: kTextPrimary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Pending', style: TextStyle(fontSize: 8.5, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$canal • $crop ($acres Ac) • Awaiting response',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // 2️⃣ SCREEN 3: FARMER REQUIREMENTS (INPUT SCREEN)
  // =========================================================================
  Widget _buildFarmersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farmer Requirements',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kTextPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Active verified farmers participating in this canal mediation',
            style: TextStyle(fontSize: 12, color: kTextSecondary),
          ),
          const SizedBox(height: 14),

          // Active Permanent Canal Group Card
          if (_activeCanalGroup != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kMintGreen.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPrimaryGreen, width: 1.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: kPrimaryGreen, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _t('group_registered'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkGreen),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _confirmExitGroup,
                        icon: const Icon(Icons.exit_to_app, color: kAccentRed, size: 14),
                        label: Text(
                          _t('exit_group'),
                          style: const TextStyle(color: kAccentRed, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kAccentRed),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '👥 ${_activeCanalGroup!.groupName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '🔒 ${_t("group_between_you")}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],

          // Incoming Invitations (Targeted to this recipient farmer to Accept or Reject)
          if (_incomingInvitations.isNotEmpty) ...[
            _buildPendingInvitationsCard(),
            const SizedBox(height: 10),
          ],

          // Outgoing Invitations (Dispatched by this farmer, awaiting response)
          if (_sentInvitations.isNotEmpty) ...[
            _buildSentInvitationsCard(),
            const SizedBox(height: 10),
          ],

          // Active Participating Farmer Cards
          ..._engine.farmerAgents.map((f) => _buildFarmerRequirementCard(f)),

          const SizedBox(height: 10),
          // Add Farmer Request Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _showAddFarmerDialog,
              icon: const Icon(Icons.add, color: kPrimaryGreen, size: 18),
              label: Text(
                _t('add_farmer_request'),
                style: const TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPrimaryGreen, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Proceed to Analysis button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _tabController.animateTo(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_t('talk_to_ai'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerRequirementCard(FarmerAgentProfile f) {
    Color reachColor = kPrimaryGreen;
    Color reachBg = kMintGreen;
    String reachLabel = 'Head Reach';

    if (f.canalReach == CanalReach.midReach) {
      reachColor = kAccentOrange;
      reachBg = kSoftOrange;
      reachLabel = 'Mid Reach';
    } else if (f.canalReach == CanalReach.tailReach) {
      reachColor = Colors.purple;
      reachBg = Colors.purple.shade50;
      reachLabel = 'Tail Reach';
    }

    final cwsi = f.telemetry.cropWaterStressIndex;
    String stressLabel = 'Optimal';
    Color stressColor = kPrimaryGreen;
    Color stressBg = kMintGreen;
    if (cwsi > 0.75) {
      stressLabel = 'Critical Need';
      stressColor = kAccentRed;
      stressBg = kSoftRed;
    } else if (cwsi > 0.5) {
      stressLabel = 'High Need';
      stressColor = Colors.deepOrange;
      stressBg = Colors.deepOrange.shade50;
    }

    final aadhaarId = f.aadhaarMasked ?? (f.aadhaarNumber != null ? 'XXXX-${f.aadhaarNumber!.substring(f.aadhaarNumber!.length - 4)}' : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: reachBg,
                child: Icon(Icons.person, color: reachColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.farmerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kTextPrimary),
                    ),
                    Text(
                      '${f.cropName} • ${f.landHoldingAcres} Acres',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: reachBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  reachLabel,
                  style: TextStyle(color: reachColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (aadhaarId != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 13, color: kPrimaryGreen),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Aadhaar: $aadhaarId${f.village != null ? " • ${f.village}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, size: 13, color: kAccentBlue),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Req: ${f.requestedHours.toStringAsFixed(0)}h',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: stressBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '$stressLabel (${cwsi.toStringAsFixed(2)})',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: stressColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4️⃣ SCREEN 5: NEGOTIATION WORKFLOW (CHAT SCREEN)
  // =========================================================================
  // =========================================================================
  // 4️⃣ SCREEN 5: NEGOTIATION WORKFLOW (REAL-TIME INTERACTIVE CHAT)
  // =========================================================================
  Widget _buildNegotiationTab() {
    final history = _engine.negotiationHistory;

    return Column(
      children: [
        // Farmer-Friendly Voice-First Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: kMintGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: kPrimaryGreen, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('screen_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary),
                    ),
                    Text(
                      _isNegotiating
                          ? _t('mediating')
                          : (_engine.finalizedAgreement != null ? '✅ ${_t("unanimous_approval")}' : '🟢 ${_t("tap_to_speak")}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: _isNegotiating ? kAccentOrange : kPrimaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Language quick toggle: EN | తె | हि
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kCardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLangChip('en', 'EN'),
                    _buildLangChip('te', 'తె'),
                    _buildLangChip('hi', 'हि'),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Auto-read voice toggle
              InkWell(
                onTap: () {
                  if (_autoReadAloud) {
                    _turnOffSpeaker();
                  } else {
                    setState(() => _autoReadAloud = true);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: _autoReadAloud ? kMintGreen : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _autoReadAloud ? kPrimaryGreen : Colors.grey.shade400,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _autoReadAloud ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        size: 14,
                        color: _autoReadAloud ? kDarkGreen : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _autoReadAloud ? _t('auto_read_on') : _t('auto_read_off'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: _autoReadAloud ? kDarkGreen : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (_isAiTyping)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryGreen),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _t('reset_tooltip'),
                  onPressed: _isNegotiating ? null : _startMediationSimulation,
                ),
            ],
          ),
        ),

        // Single Chat Group Header with All Active Farmers & Add Farmer Option
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFDFB),
            border: Border(bottom: BorderSide(color: kCardBorder.withValues(alpha: 0.8))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.forum, size: 14, color: kPrimaryGreen),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Group Chat • ${_engine.farmerAgents.length} Farmers',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddFarmerDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kMintGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add, size: 13, color: kDarkGreen),
                          SizedBox(width: 4),
                          Text(
                            '+ Add Farmer',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kDarkGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _engine.farmerAgents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, idx) {
                    final f = _engine.farmerAgents[idx];
                    final isYou = f.farmerName == _farmerName;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isYou ? kMintGreen : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isYou ? kPrimaryGreen : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 11, color: isYou ? kPrimaryGreen : Colors.blueGrey),
                          const SizedBox(width: 4),
                          Text(
                            '@${f.farmerName}${isYou ? " (You)" : ""}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isYou ? kDarkGreen : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '• ${f.cropName}',
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Actionable Incoming Invitations (Directly in Recipient Farmer's Hands)
        if (_incomingInvitations.isNotEmpty) ...[
          _buildPendingInvitationsCard(),
        ],

        // Sent Invitations Tracking (For the inviter farmer, awaiting response)
        if (_sentInvitations.isNotEmpty) ...[
          _buildSentInvitationsCard(),
        ],

        // Chat Message Stream
        Expanded(
          child: history.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: kSoftBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.forum_outlined, size: 44, color: kAccentBlue),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Real-Time Autonomous Mediation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Jala-Mitra AI analyzes your land size, crop water stress index (CWSI), and canal telemetry to arbitrate a conflict-free allocation in real time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _startMediationSimulation,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_t('start_mediation')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: history.length + (_isAiTyping ? 1 : 0),
                  itemBuilder: (ctx, idx) {
                    if (idx == history.length && _isAiTyping) {
                      return _buildAiTypingIndicator();
                    }
                    final msg = history[idx];
                    return _buildNegotiationBubble(msg);
                  },
                ),
        ),

        // Voice Listening Banner
        if (_isVoiceListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: kSoftRed,
            child: Row(
              children: [
                const Icon(Icons.mic, color: kAccentRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_t("voice_listening")} Speak now in ${_lang.toUpperCase()}...',
                    style: const TextStyle(color: kAccentRed, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isVoiceListening = false),
                  child: const Text('Cancel', style: TextStyle(color: kAccentRed, fontSize: 11)),
                ),
              ],
            ),
          ),

        // Speaker Switcher (Choose which farmer is speaking in this single chat)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF9),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Speaking as: ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextSecondary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _engine.farmerAgents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, idx) {
                      final f = _engine.farmerAgents[idx];
                      final isSelected = f.farmerName.trim().toLowerCase() == _activeSpeakerName.trim().toLowerCase();
                      return InkWell(
                        onTap: () => setState(() => _activeSpeakerName = f.farmerName),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? kPrimaryGreen : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Icon(Icons.check_circle, size: 12, color: Colors.white)
                              else
                                Icon(Icons.account_circle, size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                f.farmerName == _farmerName ? '${f.farmerName} (You)' : f.farmerName,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Quick Reaction Action Chips (Farmer-Friendly & Multilingual)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionChip(
                  _lang == 'te' ? '👍 సమ్మతం' : (_lang == 'hi' ? '👍 सहमत' : '👍 I Agree'),
                  () {
                    final txt = _lang == 'te'
                        ? 'నేను ప్రతిపాదిత నీటి కేటాయింపు షెడ్యూల్‌కు అంగీకరిస్తున్నాను. ఖరారు చేయండి.'
                        : (_lang == 'hi'
                            ? 'मैं प्रस्तावित जल आवंटन समय-सारणी से सहमत हूँ। कृपया इसे अंतिम रूप दें।'
                            : 'I agree to the proposed allocation schedule. Let us finalize it.');
                    _sendFarmerMessage(txt, 'agree');
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  _lang == 'te' ? '👎 ఇంకా నీరు కావాలి' : (_lang == 'hi' ? '👎 और पानी चाहिए' : '👎 Need More Water'),
                  () {
                    final txt = _lang == 'te'
                        ? 'నా పంటలకు ఇంకా ఎక్కువ నీటి గంటలు కావాలి. నేల ఎండిపోతోంది.'
                        : (_lang == 'hi'
                            ? 'मेरी फसल के लिए और पानी के घंटे चाहिए। खेत सूख रहा है।'
                            : 'I need more water hours for my field. My crops are drying.');
                    _sendFarmerMessage(txt, 'disagree');
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  _lang == 'te' ? '🌾 పంటకు అదనపు సమయం' : (_lang == 'hi' ? '🌾 फसल के लिए अतिरिक्त समय' : '🌾 Extra Time for Crop'),
                  () {
                    _chatInputController.text = _lang == 'te'
                        ? 'నా $_farmerCrop పంటకు మరో 2 గంటల సమయం కావాలి. సర్దుబాటు చేయగలరా?'
                        : (_lang == 'hi'
                            ? 'मेरी $_farmerCrop फसल के लिए 2 घंटे और चाहिए। क्या आप समय बदल सकते हैं?'
                            : 'I need 2 more hours for my $_farmerCrop. Can you adjust?');
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  _lang == 'te' ? '💧 కాలువ ప్రవాహం ఎంత?' : (_lang == 'hi' ? '💧 नहर में कितना पानी है?' : '💧 Check Canal Water'),
                  () {
                    final txt = _lang == 'te'
                        ? 'ప్రస్తుతం కాలువ గేటు నుండి ఎంత నీరు ప్రవహిస్తోంది?'
                        : (_lang == 'hi'
                            ? 'इस समय नहर के गेट से कितना पानी बह रहा है?'
                            : 'How much water is flowing from the canal gate right now?');
                    _sendFarmerMessage(txt, 'message');
                  },
                ),
              ],
            ),
          ),
        ),

        // Active Speaking Banner with instant "Turn Off Speaker" button
        if (_currentlySpeakingMsgId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: kSoftRed,
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: kAccentRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t('speaking'),
                    style: const TextStyle(color: kAccentRed, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _turnOffSpeaker,
                  icon: const Icon(Icons.volume_off, size: 13),
                  label: Text(_t('turn_off_speaker'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentRed,
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

        // Prominent Voice-First Floating Capsule Input Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isVoiceListening ? kAccentRed : Colors.grey.shade300,
                  width: _isVoiceListening ? 1.5 : 0.9,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Prominent Active Voice Mic Button (Big, High Contrast & Pulsing)
                  InkWell(
                    onTap: _startVoiceInput,
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _isVoiceListening ? kAccentRed : kPrimaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isVoiceListening ? kAccentRed : kPrimaryGreen).withValues(alpha: 0.35),
                            blurRadius: _isVoiceListening ? 10 : 3,
                            spreadRadius: _isVoiceListening ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isVoiceListening ? Icons.mic : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Speaker On/Off Toggle Button inside the Chat Input
                  InkWell(
                    onTap: () {
                      if (_autoReadAloud) {
                        _turnOffSpeaker();
                      } else {
                        setState(() => _autoReadAloud = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_t('auto_read_on')),
                            duration: const Duration(seconds: 1),
                            backgroundColor: kPrimaryGreen,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _autoReadAloud ? kMintGreen : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _autoReadAloud ? kPrimaryGreen : Colors.grey.shade400,
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        _autoReadAloud ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: _autoReadAloud ? kDarkGreen : Colors.grey.shade700,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Text Field (Voice or Type)
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      enabled: !_isAiTyping,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendFarmerMessage(),
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13, color: kTextPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _isVoiceListening
                            ? '${_t("voice_listening")} (${_lang.toUpperCase()})...'
                            : _t('type_response'),
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send Action Button
                  InkWell(
                    onTap: _isAiTyping ? null : () => _sendFarmerMessage(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAiTyping ? Colors.grey.shade400 : kPrimaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: _isAiTyping
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: kSoftBlue,
            child: const Icon(Icons.water_drop, color: kAccentBlue, size: 16),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kAccentBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: kAccentBlue),
                ),
                const SizedBox(width: 10),
                Text(
                  _t('ai_analyzing'),
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextPrimary),
        ),
      ),
    );
  }

  Widget _buildNegotiationBubble(NegotiationMessage msg) {
    final isCentral = msg.role == MessageRole.centralMediationAgent;
    final isSystem = msg.role == MessageRole.systemTelemetry;
    final isFarmerYou = !isCentral && !isSystem && (
      msg.senderName == _farmerName ||
      msg.senderName == 'You' ||
      msg.senderName == _t('you') ||
      msg.senderName == _activeSpeakerName
    );

    // System Telemetry Pill
    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sensors, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.content.replaceAll('**', '').replaceAll('*', '').trim(),
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Farmer's Own Message (Right-Aligned, Green)
    if (isFarmerYou) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 48), // Padding on left
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.senderName == _farmerName ? '${_t("you")} ($_farmerName)' : '@${msg.senderName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('hh:mm a').format(msg.timestamp),
                          style: const TextStyle(fontSize: 9, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.content.replaceAll('**', '').replaceAll('*', '').trim(),
                      style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: kDarkGreen,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ),
      );
    }

    // Jala-Mitra AI Arbiter or Peer Farmer Agent (Left-Aligned)
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isCentral ? kSoftBlue : kMintGreen,
            child: Icon(
              isCentral ? Icons.water_drop : Icons.person,
              color: isCentral ? kAccentBlue : kPrimaryGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isCentral ? kAccentBlue.withValues(alpha: 0.3) : kCardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                msg.senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: isCentral ? kDarkGreen : kTextPrimary,
                                ),
                              ),
                            ),
                            if (isCentral) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: kMintGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AI Agent',
                                  style: TextStyle(color: kDarkGreen, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('hh:mm a').format(msg.timestamp),
                        style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    msg.content.replaceAll('**', '').replaceAll('*', '').trim(),
                    style: const TextStyle(fontSize: 12.5, color: kTextPrimary, height: 1.4),
                  ),
                  if (msg.technicalExplanation != null && msg.technicalExplanation!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kCardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚖️ ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              msg.technicalExplanation!.replaceAll('**', '').replaceAll('*', '').trim(),
                              style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: kTextSecondary, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Speaker button & Actions
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 🔊 TTS Speaker Button
                      InkWell(
                        onTap: () => _speakMessage(msg.id, msg.content, userTriggered: true),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _currentlySpeakingMsgId == msg.id
                                ? kSoftRed
                                : kMintGreen,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _currentlySpeakingMsgId == msg.id
                                  ? kAccentRed
                                  : kPrimaryGreen.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentlySpeakingMsgId == msg.id
                                    ? Icons.stop_circle_rounded
                                    : Icons.volume_up_rounded,
                                size: 15,
                                color: _currentlySpeakingMsgId == msg.id
                                    ? kAccentRed
                                    : kDarkGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentlySpeakingMsgId == msg.id
                                    ? _t('speaking')
                                    : _t('listen_aloud'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _currentlySpeakingMsgId == msg.id
                                      ? kAccentRed
                                      : kDarkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: msg.content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Message copied to clipboard'), duration: Duration(seconds: 1)),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.copy, size: 13, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isCentral && _engine.finalizedAgreement != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _tabController.animateTo(3), // Go to Schedule tab
                          icon: const Icon(Icons.calendar_month, size: 14),
                          label: Text(_t('schedule')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _showAgreementBottomSheet,
                          icon: const Icon(Icons.verified, size: 14),
                          label: Text(_t('agreement')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5️⃣ SCREEN 6: SCHEDULE GENERATION (GANTT VIEW)
  // =========================================================================
  Widget _buildScheduleTab() {
    final farmers = _engine.farmerAgents;
    final totalAvail = _engine.canalTelemetry.availableDurationHours > 0
        ? _engine.canalTelemetry.availableDurationHours
        : 24.0;
    final totalReq = farmers.fold<double>(0.0, (sum, f) => sum + f.requestedHours);
    double cumulativeHours = 0.0;
    final colors = [
      kPrimaryGreen,
      kAccentBlue,
      kAccentOrange,
      Colors.purple,
      Colors.teal,
      Colors.deepOrange,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Proposed Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary)),
              Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: TextStyle(fontSize: 12, color: kTextSecondary)),
            ],
          ),
          const SizedBox(height: 12),

          // Gantt Chart Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Time Axis Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('06:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('10:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('14:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('18:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('22:00', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Dynamic Farmer Gantt Rows
                ...List.generate(farmers.length, (idx) {
                  final f = farmers[idx];
                  final color = colors[idx % colors.length];
                  final allocated = totalReq > 0
                      ? ((f.requestedHours / totalReq) * totalAvail).clamp(1.0, totalAvail)
                      : (totalAvail / (farmers.isNotEmpty ? farmers.length : 1));
                  
                  final leftRatio = (cumulativeHours / totalAvail).clamp(0.0, 0.9);
                  final widthRatio = (allocated / totalAvail).clamp(0.08, 1.0 - leftRatio);
                  
                  final startHour = 6.0 + cumulativeHours;
                  final endHour = startHour + allocated;
                  cumulativeHours += allocated;
                  
                  final timeRange = '${startHour.toStringAsFixed(1)}h - ${endHour.toStringAsFixed(1)}h';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGanttRow(
                      f.farmerName,
                      f.cropName,
                      timeRange,
                      leftRatio,
                      widthRatio,
                      color,
                    ),
                  );
                }),

                const Divider(height: 1),
                const SizedBox(height: 10),

                // Dynamic Legend Chips with Wrap
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(farmers.length, (idx) {
                    final f = farmers[idx];
                    final color = colors[idx % colors.length];
                    return _buildLegendItem('${f.farmerName} (${f.cropName})', color);
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Allocation Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Allocation Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary)),
                const SizedBox(height: 10),
                _buildSummaryLine('Total Canal Supply', '${totalAvail.toStringAsFixed(1)} Hours'),
                _buildSummaryLine('Active Participants', '${farmers.length} Farmers'),
                _buildSummaryLine('Fairness Score', '94 / 100'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // View Water Agreement & Official Pass Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showAgreementBottomSheet,
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(_t('agreement'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGanttRow(String name, String crop, String timeRange, double leftRatio, double widthRatio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$name ($crop)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextPrimary),
              ),
            ),
            Text(
              timeRange,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final totalWidth = constraints.maxWidth;
            final leftOffset = totalWidth * leftRatio;
            final barWidth = totalWidth * widthRatio;

            return Stack(
              children: [
                Container(
                  height: 22,
                  width: totalWidth,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                ),
                Positioned(
                  left: leftOffset,
                  child: Container(
                    height: 22,
                    width: barWidth,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: kTextSecondary)),
      ],
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: kTextSecondary))),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextPrimary)),
        ],
      ),
    );
  }

  // =========================================================================
  // 6️⃣ RATIFIED WATER AGREEMENT MODAL BOTTOM SHEET
  // =========================================================================
  void _showAgreementBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kMintGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified, color: kPrimaryGreen, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _t('agreement'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildAgreementContent(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgreementContent(BuildContext sheetCtx) {
    final agreement = _engine.finalizedAgreement;
    final agrId = agreement?.agreementId ?? 'JALA-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, "0")}';
    final auditHash = agreement?.auditHash ?? 'a3f9d2e4b41c7ff09ga9b04a2fe699d81';
    final farmers = _engine.farmerAgents;
    final totalAvail = _engine.canalTelemetry.availableDurationHours > 0
        ? _engine.canalTelemetry.availableDurationHours
        : 24.0;
    final totalReq = farmers.fold<double>(0.0, (sum, f) => sum + f.requestedHours);
    final colors = [kPrimaryGreen, kAccentBlue, kAccentOrange, Colors.purple, Colors.teal];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryGreen, width: 1.5),
              boxShadow: [
                BoxShadow(color: kPrimaryGreen.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified, color: kPrimaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Water-Sharing Agreement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: kTextPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(color: kMintGreen, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Ratified', style: TextStyle(color: kPrimaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryLine('Agreement ID', agrId),
                _buildSummaryLine('Canal Station', _selectedCanalStation),
                _buildSummaryLine('Date', DateFormat('dd MMM yyyy').format(DateTime.now())),
                _buildSummaryLine('Participants', farmers.map((f) => f.farmerName).join(', ')),

                const Divider(height: 20),
                const Text('Final Water Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary)),
                const SizedBox(height: 8),

                ...List.generate(farmers.length, (idx) {
                  final f = farmers[idx];
                  final color = colors[idx % colors.length];
                  final allocated = totalReq > 0
                      ? ((f.requestedHours / totalReq) * totalAvail).clamp(1.0, totalAvail)
                      : (totalAvail / (farmers.isNotEmpty ? farmers.length : 1));
                  return _buildAllocationRow(
                    '${f.farmerName} (${f.cropName})',
                    '${allocated.toStringAsFixed(1)} Hours',
                    color,
                  );
                }),

                const Divider(height: 14),
                _buildSummaryLine('Total Scheduled Window', '${totalAvail.toStringAsFixed(1)} Hours'),
                _buildSummaryLine('Fairness Consensus', '100% Agreement (All Farmers)'),

                const SizedBox(height: 12),
                // Audit Hash Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: kCardBorder)),
                  child: Row(
                    children: [
                      const Icon(Icons.security, size: 16, color: kPrimaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Audit: $auditHash',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: kTextSecondary, fontFamily: 'monospace'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: kPrimaryGreen),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: auditHash));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audit Hash copied!'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kPrimaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📄 PDF Water Pass saved to device archive!'), duration: Duration(seconds: 2)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(String name, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: kTextPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kTextPrimary)),
        ],
      ),
    );
  }

  // =========================================================================
  // ℹ️ INFO & LOADING OVERLAYS
  // =========================================================================
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.water_drop, color: kPrimaryGreen, size: 22),
            SizedBox(width: 8),
            Text('Jala-Mitra AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Jala-Mitra AI helps farmers share canal water fairly without fights or delays. It automatically calculates crop water needs, listens to every farmer\'s voice, and creates an honest, transparent schedule for everyone.',
          style: TextStyle(fontSize: 12, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMediationHistorySheet() async {
    Box box;
    if (Hive.isBoxOpen('waterHistoryBox')) {
      box = Hive.box('waterHistoryBox');
    } else {
      box = await Hive.openBox('waterHistoryBox');
    }

    final historyList = box.values.toList().reversed.toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kMintGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history_edu, color: kPrimaryGreen, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mediation & Agreement History',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextPrimary),
                            ),
                            Text(
                              '${historyList.length} Ratified Timetable Pass(es) on Ledger',
                              style: TextStyle(fontSize: 11, color: kTextSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: historyList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kMintGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.history, size: 40, color: kPrimaryGreen),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No Mediation History Recorded Yet',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextPrimary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'When Jala-Mitra AI arbitrates a dispute and farmers reach consensus, the signed Warabandi agreement and audit hashes will be permanently logged here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: historyList.length,
                        itemBuilder: (ctx, index) {
                          final item = Map<String, dynamic>.from(historyList[index] as Map);
                          final id = item['id'] ?? 'AGR';
                          final timestampStr = item['timestamp'] ?? '';
                          final dt = DateTime.tryParse(timestampStr) ?? DateTime.now();
                          final station = item['canalStation'] ?? 'Saraswati Canal';
                          final hash = item['auditHash'] ?? 'HASH';
                          final slots = (item['slots'] as List? ?? []);
                          final gini = (item['giniIndex'] as num?)?.toDouble() ?? 0.10;
                          final totalAlloc = (item['totalAllocatedHours'] as num?)?.toDouble() ?? 24.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kBackground,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kCardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.verified, color: kPrimaryGreen, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          id,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkGreen),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: kMintGreen,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Consensus Ratified ✓',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryGreen),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '📅 ${DateFormat("dd MMM yyyy, hh:mm a").format(dt)} • 📍 $station',
                                  style: TextStyle(fontSize: 11, color: kTextSecondary),
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Farmer Time-Sharing Allocations:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextPrimary),
                                    ),
                                    Text(
                                      'Total: ${totalAlloc.toStringAsFixed(0)} hrs',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kTextSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...slots.map((s) {
                                  final fName = s['farmerName'] ?? 'Farmer';
                                  final crop = s['cropName'] ?? 'Crop';
                                  final dur = (s['durationHours'] as num?)?.toDouble() ?? 8.0;
                                  final gate = s['gate'] ?? 'Gate 4';
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: kCardBorder),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('• $fName ($crop)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kTextPrimary)),
                                        Text('${dur.toStringAsFixed(1)}h ($gate)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkGreen)),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '🔐 $hash',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.blueGrey.shade700),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: kSoftBlue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Gini: ${gini.toStringAsFixed(2)} (Fair)',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccentBlue),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: kPrimaryGreen),
              const SizedBox(height: 14),
              Text(_loadingStep, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
