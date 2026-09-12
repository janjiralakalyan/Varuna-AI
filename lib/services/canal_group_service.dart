import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/water_mediation/telemetry_data.dart';

/// Represents an authoritative, registered farmer group for a canal branch.
/// Stored permanently on device and backend until manually exited.
class CanalGroup {
  final String groupId;
  final String canalStation;
  final String groupName;
  final List<FarmerAgentProfile> members;
  final DateTime createdAt;
  final bool isActive;

  CanalGroup({
    required this.groupId,
    required this.canalStation,
    required this.groupName,
    required this.members,
    required this.createdAt,
    this.isActive = true,
  });

  bool hasMember(String name) {
    final clean = name.trim().toLowerCase();
    return members.any((m) => m.farmerName.trim().toLowerCase() == clean);
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'canalStation': canalStation,
      'groupName': groupName,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory CanalGroup.fromJson(Map<dynamic, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    final rawMembers = (m['members'] as List?) ?? [];
    return CanalGroup(
      groupId: m['groupId']?.toString() ?? 'grp_${DateTime.now().millisecondsSinceEpoch}',
      canalStation: m['canalStation']?.toString() ?? 'Saraswati Canal Head Regulator',
      groupName: m['groupName']?.toString() ?? 'Canal Water Sharing Group',
      members: rawMembers.map((rm) => FarmerAgentProfile.fromJson(rm as Map)).toList(),
      createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: m['isActive'] != false,
    );
  }
}

class CanalGroupService {
  static const String _boxName = 'canalGroupBox';

  static Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  static String _keyForStation(String canalStation) {
    return 'group_${canalStation.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
  }

  /// Retrieves the active, permanently stored group for the canal station if farmer is a member.
  static Future<CanalGroup?> getActiveGroup(String canalStation, String farmerName) async {
    try {
      final box = await _getBox();
      final key = _keyForStation(canalStation);
      final raw = box.get(key);

      if (raw != null && raw is Map) {
        final group = CanalGroup.fromJson(raw);
        if (group.isActive && group.hasMember(farmerName)) {
          return group;
        }
      }
    } catch (e) {
      debugPrint('Error getting active canal group: $e');
    }
    return null;
  }

  /// Permanently saves or updates the canal group both locally and on backend
  static Future<void> saveGroup(CanalGroup group) async {
    try {
      final box = await _getBox();
      final key = _keyForStation(group.canalStation);
      await box.put(key, group.toJson());
      debugPrint('Saved permanent canal group ${group.groupId} for ${group.canalStation}');
    } catch (e) {
      debugPrint('Error saving canal group to Hive: $e');
    }

    // Sync to backend server
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/water/group/create-or-update');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'group_id': group.groupId,
          'canal_station': group.canalStation,
          'group_name': group.groupName,
          'is_active': group.isActive,
          'members': group.members.map((m) => m.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  /// Creates a group from an accepted mediation invitation (e.g. Sender + Receiver)
  static Future<CanalGroup> registerAcceptedPair({
    required String canalStation,
    required FarmerAgentProfile sender,
    required FarmerAgentProfile receiver,
  }) async {
    final existing = await getActiveGroup(canalStation, sender.farmerName) ??
        await getActiveGroup(canalStation, receiver.farmerName);

    List<FarmerAgentProfile> members;
    String groupId;
    if (existing != null && existing.isActive) {
      groupId = existing.groupId;
      members = List<FarmerAgentProfile>.from(existing.members);
      if (!members.any((m) => m.farmerName.toLowerCase() == sender.farmerName.toLowerCase())) {
        members.add(sender);
      }
      if (!members.any((m) => m.farmerName.toLowerCase() == receiver.farmerName.toLowerCase())) {
        members.add(receiver);
      }
    } else {
      groupId = 'grp_${canalStation.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
      members = [sender, receiver];
    }

    final group = CanalGroup(
      groupId: groupId,
      canalStation: canalStation,
      groupName: '${sender.farmerName} & ${receiver.farmerName} Water Group',
      members: members,
      createdAt: DateTime.now(),
      isActive: true,
    );

    await saveGroup(group);
    return group;
  }

  /// Manually exits a farmer from the canal group. The group remains deactivated for them.
  static Future<bool> exitGroup({
    required String canalStation,
    required String farmerName,
  }) async {
    try {
      final box = await _getBox();
      final key = _keyForStation(canalStation);
      final raw = box.get(key);

      if (raw != null && raw is Map) {
        final group = CanalGroup.fromJson(raw);
        // Remove member or deactivate if <= 1 member remaining
        final remaining = group.members
            .where((m) => m.farmerName.trim().toLowerCase() != farmerName.trim().toLowerCase())
            .toList();

        final updated = CanalGroup(
          groupId: group.groupId,
          canalStation: group.canalStation,
          groupName: group.groupName,
          members: remaining,
          createdAt: group.createdAt,
          isActive: remaining.length >= 2,
        );

        if (updated.isActive) {
          await box.put(key, updated.toJson());
        } else {
          await box.delete(key);
        }
      }
    } catch (e) {
      debugPrint('Error exiting canal group locally: $e');
    }

    // Notify backend
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/water/group/exit');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'canal_station': canalStation,
          'farmer_name': farmerName,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return true;
  }

  /// Syncs canal group from backend to stay in sync with peers
  static Future<CanalGroup?> syncWithBackend({
    required String canalStation,
    required String farmerName,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/water/group?canal_station=${Uri.encodeComponent(canalStation)}&farmer_name=${Uri.encodeComponent(farmerName)}');
      final res = await http.get(url).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && data['group'] != null) {
          final group = CanalGroup.fromJson(data['group']);
          final box = await _getBox();
          final key = _keyForStation(canalStation);
          if (group.isActive && group.hasMember(farmerName)) {
            await box.put(key, group.toJson());
            return group;
          } else {
            await box.delete(key);
            return null;
          }
        }
      }
    } catch (_) {}

    return getActiveGroup(canalStation, farmerName);
  }
}
