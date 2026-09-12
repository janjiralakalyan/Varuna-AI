import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Persists notification into local Hive notificationsBox
  static Future<void> saveNotification({
    required String title,
    required String body,
    String type = 'community',
    List<String>? targetFarmers,
    Map<String, dynamic>? metadata,
  }) async {
    final item = {
      'id': 'notif_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'body': body,
      'type': type,
      'targetFarmers': targetFarmers ?? [],
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };

    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        await box.add(item);
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  /// Dispatches mediation invitation to backend server in real-time and saves to local storage
  static Future<Map<String, dynamic>> sendMediationInvitation({
    required String inviterName,
    required String recipientFarmerName,
    required String canalStation,
    required Map<String, dynamic> farmerData,
  }) async {
    final inviteId = 'inv_${DateTime.now().millisecondsSinceEpoch}';
    final item = {
      'id': inviteId,
      'title': '🌾 Water Mediation Invitation',
      'body': '$inviterName invited you to join real-time canal water arbitration for $canalStation. Registered Land & CWSI ready for audit.',
      'type': 'mediation_invitation',
      'targetFarmers': [recipientFarmerName],
      'inviterName': inviterName,
      'recipientFarmerName': recipientFarmerName,
      'canalStation': canalStation,
      'farmerData': farmerData,
      'status': 'pending', // 'pending' | 'accepted' | 'rejected'
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };

    // 1. Save locally in Hive
    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        await box.add(item);
      }
    } catch (e) {
      debugPrint('Error saving mediation invite to Hive: $e');
    }

    // 2. Dispatch to Backend Server in Real-Time
    try {
      final candidateUrls = [
        '${AppConstants.baseUrl}/api/water/invite',
        'http://11.11.1.108:8000/api/water/invite',
        'http://127.0.0.1:8000/api/water/invite',
        'http://10.0.2.2:8000/api/water/invite',
      ];
      for (final u in candidateUrls) {
        try {
          final res = await http.post(
            Uri.parse(u),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'inviter_name': inviterName,
              'recipient_farmer_name': recipientFarmerName,
              'canal_station': canalStation,
              'farmer_data': farmerData,
            }),
          ).timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) {
            debugPrint('✅ Real-time invitation dispatched to backend server via $u');
            break;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Backend sync error for invitation: $e');
    }

    // 3. Local notification trigger (only if receiver is active on this device)
    try {
      if (Hive.isBoxOpen('profileBox')) {
        final currentFarmer = (Hive.box('profileBox').get('name', defaultValue: '') ?? '').toString().toLowerCase().trim();
        final recipientClean = recipientFarmerName.toLowerCase().trim();
        if (currentFarmer.isNotEmpty && currentFarmer == recipientClean) {
          await showWaterMediationNotification(
            title: '🌾 Invitation from @$inviterName',
            body: '$inviterName invited you to canal mediation on $canalStation. Tap to Accept or Reject.',
            id: (DateTime.now().millisecondsSinceEpoch % 10000),
          );
        }
      }
    } catch (_) {}

    return item;
  }

  /// Sends a request from a farmer who wants to join an ongoing mediation
  static Future<Map<String, dynamic>> sendJoinRequest({
    required String requestingFarmerName,
    required String canalStation,
    required String canalLeadFarmer,
    required Map<String, dynamic> farmerData,
  }) async {
    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final item = {
      'id': requestId,
      'title': '🙋 Join Request from @$requestingFarmerName',
      'body': '$requestingFarmerName requested to join active water negotiation on $canalStation.',
      'type': 'mediation_invitation',
      'targetFarmers': [canalLeadFarmer],
      'inviterName': requestingFarmerName,
      'recipientFarmerName': canalLeadFarmer,
      'isJoinRequest': true,
      'canalStation': canalStation,
      'farmerData': farmerData,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    };

    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        await box.add(item);
      }
    } catch (e) {
      debugPrint('Error saving join request: $e');
    }

    return item;
  }

  /// Synchronizes incoming and outgoing invitations with backend in real time across devices
  static Future<List<Map<String, dynamic>>> syncInvitationsWithBackend(String farmerName) async {
    final clean = farmerName.trim().toLowerCase();
    if (clean.isEmpty) return [];

    try {
      final candidateUrls = [
        '${AppConstants.baseUrl}/api/water/invitations?farmer_name=${Uri.encodeComponent(farmerName)}',
        'http://11.11.1.108:8000/api/water/invitations?farmer_name=${Uri.encodeComponent(farmerName)}',
        'http://127.0.0.1:8000/api/water/invitations?farmer_name=${Uri.encodeComponent(farmerName)}',
        'http://10.0.2.2:8000/api/water/invitations?farmer_name=${Uri.encodeComponent(farmerName)}',
      ];

      for (final u in candidateUrls) {
        try {
          final res = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final incoming = data['incoming'] as List? ?? [];
            final sent = data['sent'] as List? ?? [];

            if (Hive.isBoxOpen('notificationsBox')) {
              final box = Hive.box('notificationsBox');

              // Process incoming invitations for this recipient
              for (final rawInv in incoming) {
                final inv = Map<String, dynamic>.from(rawInv as Map);
                final invId = inv['id']?.toString() ?? '';

                bool found = false;
                for (int i = 0; i < box.length; i++) {
                  final existing = box.getAt(i);
                  if (existing is Map && existing['id'] == invId) {
                    found = true;
                    if (existing['status'] != inv['status']) {
                      final updated = Map<String, dynamic>.from(existing);
                      updated['status'] = inv['status'];
                      await box.putAt(i, updated);
                    }
                    break;
                  }
                }

                // If this is a NEW incoming invitation for this recipient
                if (!found && inv['status'] == 'pending') {
                  final item = {
                    'id': invId,
                    'title': '🌾 Water Mediation Invitation',
                    'body': '${inv['inviterName']} invited you to join real-time canal water arbitration for ${inv['canalStation']}. Tap to Accept or Reject.',
                    'type': 'mediation_invitation',
                    'targetFarmers': [farmerName],
                    'inviterName': inv['inviterName'],
                    'recipientFarmerName': farmerName,
                    'canalStation': inv['canalStation'],
                    'farmerData': inv['farmerData'],
                    'status': 'pending',
                    'timestamp': inv['timestamp'] ?? DateTime.now().toIso8601String(),
                    'read': false,
                  };
                  await box.add(item);

                  // 🔔 FIRE REAL SYSTEM PUSH NOTIFICATION ON RECEIVER'S PHONE/SCREEN
                  await showWaterMediationNotification(
                    title: '🌾 Water Mediation Invitation',
                    body: '${inv['inviterName']} invited you to join canal mediation on ${inv['canalStation']}. Tap to Accept or Reject.',
                    id: (DateTime.now().millisecondsSinceEpoch % 10000),
                  );
                }
              }

              // Process sent invitations
              for (final rawInv in sent) {
                final inv = Map<String, dynamic>.from(rawInv as Map);
                final invId = inv['id']?.toString() ?? '';
                for (int i = 0; i < box.length; i++) {
                  final existing = box.getAt(i);
                  if (existing is Map && existing['id'] == invId) {
                    if (existing['status'] != inv['status']) {
                      final updated = Map<String, dynamic>.from(existing);
                      updated['status'] = inv['status'];
                      await box.putAt(i, updated);
                    }
                    break;
                  }
                }
              }
            }
            break;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error syncing invitations with backend: $e');
    }

    return getInvitationsForFarmer(farmerName);
  }

  /// Updates status of an invitation ('accepted' or 'rejected') locally and on backend server
  static Future<bool> updateInvitationStatus({
    required String inviteId,
    required String status,
    String? farmerName,
  }) async {
    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        for (int i = 0; i < box.length; i++) {
          final raw = box.getAt(i);
          if (raw is Map && raw['id'] == inviteId) {
            final updated = Map<String, dynamic>.from(raw);
            updated['status'] = status;
            updated['read'] = true;
            updated['respondedAt'] = DateTime.now().toIso8601String();
            await box.putAt(i, updated);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating invitation status in Hive: $e');
    }

    // Real-Time Server sync
    try {
      final candidateUrls = [
        '${AppConstants.baseUrl}/api/water/respond-invite',
        'http://11.11.1.108:8000/api/water/respond-invite',
        'http://127.0.0.1:8000/api/water/respond-invite',
        'http://10.0.2.2:8000/api/water/respond-invite',
      ];
      for (final u in candidateUrls) {
        try {
          final res = await http.post(
            Uri.parse(u),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'invite_id': inviteId,
              'status': status,
              'farmer_name': farmerName ?? '',
            }),
          ).timeout(const Duration(seconds: 3));
          if (res.statusCode == 200) break;
        } catch (_) {}
      }
    } catch (_) {}

    return true;
  }

  /// Returns INCOMING invitations strictly targeted to this farmer (the recipient who can Accept or Reject).
  /// Senders will NEVER receive Accept/Reject cards for invitations they sent!
  static List<Map<String, dynamic>> getInvitationsForFarmer(String farmerName) {
    final list = <Map<String, dynamic>>[];
    final clean = farmerName.trim().toLowerCase();
    if (clean.isEmpty) return list;

    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        for (int i = 0; i < box.length; i++) {
          final raw = box.getAt(i);
          if (raw is Map && raw['type'] == 'mediation_invitation') {
            final recipient = (raw['recipientFarmerName'] ?? '').toString().toLowerCase().trim();
            final inviter = (raw['inviterName'] ?? '').toString().toLowerCase().trim();
            final targetList = (raw['targetFarmers'] as List?)?.map((e) => e.toString().toLowerCase().trim()).toList() ?? [];
            // Strictly match recipient and ensure sender never receives Accept/Reject for their own invite
            if (inviter != clean && (recipient == clean || targetList.contains(clean))) {
              final map = Map<String, dynamic>.from(raw);
              map['hive_index'] = i;
              list.add(map);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading invitations from Hive: $e');
    }
    return list;
  }

  /// Returns OUTGOING invitations sent by this farmer to others (for tracking status without Accept/Reject buttons)
  static List<Map<String, dynamic>> getSentInvitationsByFarmer(String farmerName) {
    final list = <Map<String, dynamic>>[];
    final clean = farmerName.trim().toLowerCase();
    if (clean.isEmpty) return list;

    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        for (int i = 0; i < box.length; i++) {
          final raw = box.getAt(i);
          if (raw is Map && raw['type'] == 'mediation_invitation') {
            final inviter = (raw['inviterName'] ?? '').toString().toLowerCase().trim();
            final recipient = (raw['recipientFarmerName'] ?? '').toString().toLowerCase().trim();
            if (inviter == clean && recipient != clean) {
              final map = Map<String, dynamic>.from(raw);
              map['hive_index'] = i;
              list.add(map);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading sent invitations: $e');
    }
    return list;
  }

  /// Returns all accepted invitations involving this farmer (either as inviter or recipient)
  static List<Map<String, dynamic>> getAcceptedInvitationsForFarmer(String farmerName) {
    final list = <Map<String, dynamic>>[];
    final clean = farmerName.trim().toLowerCase();
    if (clean.isEmpty) return list;

    try {
      if (Hive.isBoxOpen('notificationsBox')) {
        final box = Hive.box('notificationsBox');
        for (int i = 0; i < box.length; i++) {
          final raw = box.getAt(i);
          if (raw is Map && raw['type'] == 'mediation_invitation' && raw['status'] == 'accepted') {
            final inviter = (raw['inviterName'] ?? '').toString().toLowerCase().trim();
            final recipient = (raw['recipientFarmerName'] ?? '').toString().toLowerCase().trim();
            if (inviter == clean || recipient == clean) {
              final map = Map<String, dynamic>.from(raw);
              map['hive_index'] = i;
              list.add(map);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading accepted invitations: $e');
    }
    return list;
  }

  static Future<void> showRiskAlert({
    required String title,
    required String body,
    int id = 1,
  }) async {
    await saveNotification(title: title, body: body, type: 'risk');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'risk_alerts',
      'Risk Alerts',
      channelDescription: 'Agricultural risk notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Broadcasts water mediation notifications and saves to persistent notification ledger
  static Future<void> showWaterMediationNotification({
    required String title,
    required String body,
    int id = 42,
  }) async {
    await saveNotification(title: title, body: body, type: 'water_mediation');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'water_mediation_channel',
      'Jala-Mitra Water Mediation',
      channelDescription: 'Real-time canal dispute and water sharing agreement notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF0E8345),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Parses the AI analysis text and fires a notification if risk is High/Critical.
  static Future<void> checkAndNotify({
    required String aiAnalysis,
    required String location,
    required String crop,
  }) async {
    final lower = aiAnalysis.toLowerCase();
    String? level;
    if (lower.contains('critical')) {
      level = '🚨 CRITICAL';
    } else if (lower.contains('high')) {
      level = '⚠️ HIGH';
    }
    if (level != null) {
      await showRiskAlert(
        title: '$level Risk — $crop in $location',
        body:
            'FarmerAI detected serious risks for your farm. Tap to view advice.',
      );
    }
  }

  static Future<void> showCommunityNotification({
    required String title,
    required String body,
    int id = 2,
  }) async {
    await saveNotification(title: title, body: body, type: 'community');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'community_alerts',
      'Community Alerts',
      channelDescription: 'Notifications for Farmers Community',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Shown when inquiry/contract status changes (accept, reject, counter, etc.)
  static Future<void> showContractNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    await saveNotification(title: title, body: body, type: 'contract');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'contract_updates',
      'Contract Updates',
      channelDescription:
          'Notifications about farmer–contractor contract status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2E7D32),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Shown when a new contractor listing is added to the platform
  static Future<void> showNewListingNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    await saveNotification(title: title, body: body, type: 'listing');
    await init();
    const androidDetails = AndroidNotificationDetails(
      'new_listings',
      'New Listings',
      channelDescription: 'Notifications when contractors post new services',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Real-time notification when a new government scheme is released for farmer's state
  static Future<void> showSchemeNotification({
    required String title,
    required String body,
    required String url,
    String? state,
    int? id,
  }) async {
    final notifId = id ?? (DateTime.now().millisecondsSinceEpoch % 100000);
    await saveNotification(
      title: title,
      body: body,
      type: 'scheme',
      metadata: {'url': url, 'state': state ?? ''},
    );
    await init();
    const androidDetails = AndroidNotificationDetails(
      'govt_schemes_channel',
      'Government Schemes Alerts',
      channelDescription:
          'Real-time notifications for newly announced central and state agricultural schemes',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1A237E),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      notifId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}

