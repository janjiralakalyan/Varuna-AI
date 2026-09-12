import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/farming_domain.dart';

class FarmingDomainProvider with ChangeNotifier {
  static const String _boxName = 'farmingBox';
  static const String _activeKey = 'active_domain';
  static const String _selectedDomainsKey = 'selected_domains';

  FarmingDomainType _activeDomain = FarmingDomainType.crops;
  Set<FarmingDomainType> _userSelectedDomains = {FarmingDomainType.crops};

  FarmingDomainType get activeDomain => _activeDomain;
  Set<FarmingDomainType> get userSelectedDomains => _userSelectedDomains;

  FarmingDomainInfo get currentDomainInfo =>
      FarmingDomainInfo.getDomain(_activeDomain);

  FarmingDomainProvider() {
    _loadFromHive();
  }

  void _loadFromHive() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final String? savedActive = box.get(_activeKey) as String?;
        if (savedActive != null) {
          _activeDomain = FarmingDomainInfo.getDomainById(savedActive).type;
        }

        final List<dynamic>? savedList =
            box.get(_selectedDomainsKey) as List<dynamic>?;
        if (savedList != null && savedList.isNotEmpty) {
          _userSelectedDomains = savedList
              .map((id) => FarmingDomainInfo.getDomainById(id.toString()).type)
              .toSet();
        }
      }
    } catch (e) {
      debugPrint('Error loading farming domain: $e');
    }
  }

  Future<void> setActiveDomain(FarmingDomainType domain) async {
    _activeDomain = domain;
    _userSelectedDomains.add(domain);
    notifyListeners();

    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final info = FarmingDomainInfo.getDomain(domain);
        await box.put(_activeKey, info.id);
        await box.put(_selectedDomainsKey,
            _userSelectedDomains.map((d) => FarmingDomainInfo.getDomain(d).id).toList());
      }
    } catch (e) {
      debugPrint('Error saving active farming domain: $e');
    }
  }

  Future<void> toggleUserDomain(FarmingDomainType domain) async {
    if (_userSelectedDomains.contains(domain)) {
      if (_userSelectedDomains.length > 1) {
        _userSelectedDomains.remove(domain);
        if (_activeDomain == domain) {
          _activeDomain = _userSelectedDomains.first;
        }
      }
    } else {
      _userSelectedDomains.add(domain);
    }
    notifyListeners();

    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_activeKey, FarmingDomainInfo.getDomain(_activeDomain).id);
        await box.put(_selectedDomainsKey,
            _userSelectedDomains.map((d) => FarmingDomainInfo.getDomain(d).id).toList());
      }
    } catch (e) {
      debugPrint('Error saving user domains: $e');
    }
  }
}
