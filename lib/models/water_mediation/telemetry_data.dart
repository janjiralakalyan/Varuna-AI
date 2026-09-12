import 'dart:math' as math;

Map<String, dynamic> _safeMap(dynamic raw) {
  if (raw == null) return {};
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
  return {};
}

enum CropStage {
  seedling,
  vegetative,
  floweringPanicle,
  grainFilling,
  maturity,
}

enum CanalReach {
  headReach,
  midReach,
  tailReach,
}

/// Real-time field telemetry parameters monitored by each farmer's agent
class FieldTelemetry {
  final double soilMoisturePercent; // e.g. 18.5% (Wilting point ~ 15%)
  final double cropWaterStressIndex; // CWSI 0.0 (Optimal) to 1.0 (Severe Stress)
  final double dailyEvapotranspirationMm;
  final double rootZoneDepthCm;
  final bool powerGridAvailable;
  final DateTime lastIrrigated;
  final double soilTemperatureC;

  FieldTelemetry({
    required this.soilMoisturePercent,
    required this.cropWaterStressIndex,
    required this.dailyEvapotranspirationMm,
    required this.rootZoneDepthCm,
    required this.powerGridAvailable,
    required this.lastIrrigated,
    required this.soilTemperatureC,
  });

  String get urgencyLevel {
    if (cropWaterStressIndex >= 0.75 || soilMoisturePercent < 18.0) {
      return 'CRITICAL';
    } else if (cropWaterStressIndex >= 0.50 || soilMoisturePercent < 22.0) {
      return 'HIGH';
    } else if (cropWaterStressIndex >= 0.30) {
      return 'MODERATE';
    }
    return 'LOW';
  }

  double get urgencyScore {
    final daysSince = DateTime.now().difference(lastIrrigated).inDays;
    double score = (cropWaterStressIndex * 60) + (math.min(daysSince, 10) * 4);
    return math.min(100.0, math.max(0.0, score));
  }
}

/// Profile of a farmer and their autonomous AI agent proxy
class FarmerAgentProfile {
  final String id;
  final String farmerName;
  final String agentName;
  final String cropName;
  final CropStage cropStage;
  final double landHoldingAcres;
  final CanalReach canalReach;
  final double canalDistanceKm;
  final double transmissionLossPercent;
  final double requestedHours;
  final FieldTelemetry telemetry;
  double allocatedHours;
  bool hasConsensus;
  // Dharani Land & Aadhaar Registry fields
  final String? aadhaarNumber;
  final String? aadhaarMasked;
  final String? pattadarPassbookNo;
  final String? khataNumber;
  final List<String>? surveyNumbers;
  final String? village;
  final String? mandal;
  final String? district;
  final String? soilType;

  FarmerAgentProfile({
    required this.id,
    required this.farmerName,
    required this.agentName,
    required this.cropName,
    required this.cropStage,
    required this.landHoldingAcres,
    required this.canalReach,
    required this.canalDistanceKm,
    required this.transmissionLossPercent,
    required this.requestedHours,
    required this.telemetry,
    this.allocatedHours = 0.0,
    this.hasConsensus = false,
    this.aadhaarNumber,
    this.aadhaarMasked,
    this.pattadarPassbookNo,
    this.khataNumber,
    this.surveyNumbers,
    this.village,
    this.mandal,
    this.district,
    this.soilType,
  });

  factory FarmerAgentProfile.fromAadhaarJson(Map<dynamic, dynamic> rawJson) {
    final json = _safeMap(rawJson);
    final land = _safeMap(json['land_details']);
    final crop = _safeMap(json['crop_details']);
    final canal = _safeMap(json['canal_irrigation_details']);

    // Map canal reach
    final reachStr = (canal['canal_reach'] ?? '').toString().toLowerCase();
    CanalReach reach = CanalReach.midReach;
    if (reachStr.contains('head')) {
      reach = CanalReach.headReach;
    } else if (reachStr.contains('tail')) {
      reach = CanalReach.tailReach;
    }

    // Map crop stage
    final stageStr = (crop['crop_stage'] ?? '').toString().toLowerCase();
    CropStage stage = CropStage.vegetative;
    if (stageStr.contains('flowering') || stageStr.contains('panicle')) {
      stage = CropStage.floweringPanicle;
    } else if (stageStr.contains('grain') || stageStr.contains('filling')) {
      stage = CropStage.grainFilling;
    } else if (stageStr.contains('seedling')) {
      stage = CropStage.seedling;
    } else if (stageStr.contains('matur')) {
      stage = CropStage.maturity;
    }

    final soilMoisture = (crop['soil_moisture_percent'] as num?)?.toDouble() ?? 20.0;
    final cwsi = (crop['crop_water_stress_index'] as num?)?.toDouble() ?? 0.50;
    final et = (crop['daily_evapotranspiration_mm'] as num?)?.toDouble() ?? 6.0;
    final rootDepth = (crop['root_zone_depth_cm'] as num?)?.toDouble() ?? 40.0;

    final name = (json['farmer_name'] ?? 'Farmer').toString();

    return FarmerAgentProfile(
      id: (json['farmer_id'] ?? 'farmer_${name.toLowerCase().replaceAll(' ', '_')}').toString(),
      farmerName: name,
      agentName: '${name.split(' ').first}-Agent-Bot',
      cropName: (crop['primary_crop'] ?? 'Paddy').toString(),
      cropStage: stage,
      landHoldingAcres: (land['total_extent_acres'] as num?)?.toDouble() ?? 3.0,
      canalReach: reach,
      canalDistanceKm: (canal['distance_from_regulator_km'] as num?)?.toDouble() ?? 3.5,
      transmissionLossPercent: (canal['transmission_seepage_loss_percent'] as num?)?.toDouble() ?? 8.0,
      requestedHours: (canal['requested_hours'] as num?)?.toDouble() ?? 12.0,
      telemetry: FieldTelemetry(
        soilMoisturePercent: soilMoisture,
        cropWaterStressIndex: cwsi,
        dailyEvapotranspirationMm: et,
        rootZoneDepthCm: rootDepth,
        powerGridAvailable: true,
        lastIrrigated: DateTime.now().subtract(const Duration(days: 6)),
        soilTemperatureC: 28.5,
      ),
      aadhaarNumber: json['aadhaar_number']?.toString(),
      aadhaarMasked: json['aadhaar_masked']?.toString(),
      pattadarPassbookNo: json['pattadar_passbook_no']?.toString(),
      khataNumber: json['khata_number']?.toString(),
      surveyNumbers: (land['survey_numbers'] as List?)?.map((s) => s.toString()).toList(),
      village: land['village']?.toString(),
      mandal: land['mandal']?.toString(),
      district: land['district']?.toString(),
      soilType: land['soil_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerName': farmerName,
      'agentName': agentName,
      'cropName': cropName,
      'cropStage': cropStage.name,
      'landHoldingAcres': landHoldingAcres,
      'canalReach': canalReach.name,
      'canalDistanceKm': canalDistanceKm,
      'transmissionLossPercent': transmissionLossPercent,
      'requestedHours': requestedHours,
      'allocatedHours': allocatedHours,
      'hasConsensus': hasConsensus,
      'soilMoisture': telemetry.soilMoisturePercent,
      'cwsi': telemetry.cropWaterStressIndex,
      'et': telemetry.dailyEvapotranspirationMm,
      'rootDepth': telemetry.rootZoneDepthCm,
      'soilTemp': telemetry.soilTemperatureC,
      'lastIrrigated': telemetry.lastIrrigated.toIso8601String(),
      'aadhaarMasked': aadhaarMasked,
      'pattadarPassbookNo': pattadarPassbookNo,
      'khataNumber': khataNumber,
      'village': village,
      'mandal': mandal,
      'district': district,
      'soilType': soilType,
    };
  }

  factory FarmerAgentProfile.fromJson(Map<dynamic, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);
    CanalReach reach = CanalReach.midReach;
    final rStr = (m['canalReach'] ?? '').toString().toLowerCase();
    if (rStr.contains('head')) {
      reach = CanalReach.headReach;
    } else if (rStr.contains('tail')) {
      reach = CanalReach.tailReach;
    }

    CropStage stage = CropStage.vegetative;
    final sStr = (m['cropStage'] ?? '').toString().toLowerCase();
    if (sStr.contains('flowering') || sStr.contains('panicle')) {
      stage = CropStage.floweringPanicle;
    } else if (sStr.contains('grain') || sStr.contains('filling')) {
      stage = CropStage.grainFilling;
    } else if (sStr.contains('seedling')) {
      stage = CropStage.seedling;
    } else if (sStr.contains('matur')) {
      stage = CropStage.maturity;
    }

    return FarmerAgentProfile(
      id: m['id']?.toString() ?? 'farmer_${(m['farmerName'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '_')}',
      farmerName: m['farmerName']?.toString() ?? 'Farmer',
      agentName: m['agentName']?.toString() ?? '${(m['farmerName'] ?? 'Farmer').toString().split(' ').first}-Agent-Bot',
      cropName: m['cropName']?.toString() ?? 'Paddy',
      cropStage: stage,
      landHoldingAcres: (m['landHoldingAcres'] as num?)?.toDouble() ?? 3.0,
      canalReach: reach,
      canalDistanceKm: (m['canalDistanceKm'] as num?)?.toDouble() ?? 4.0,
      transmissionLossPercent: (m['transmissionLossPercent'] as num?)?.toDouble() ?? 8.0,
      requestedHours: (m['requestedHours'] as num?)?.toDouble() ?? 10.0,
      allocatedHours: (m['allocatedHours'] as num?)?.toDouble() ?? 0.0,
      hasConsensus: m['hasConsensus'] == true,
      telemetry: FieldTelemetry(
        soilMoisturePercent: (m['soilMoisture'] as num?)?.toDouble() ?? 20.0,
        cropWaterStressIndex: (m['cwsi'] as num?)?.toDouble() ?? 0.55,
        dailyEvapotranspirationMm: (m['et'] as num?)?.toDouble() ?? 6.0,
        rootZoneDepthCm: (m['rootDepth'] as num?)?.toDouble() ?? 40.0,
        powerGridAvailable: true,
        lastIrrigated: DateTime.tryParse(m['lastIrrigated']?.toString() ?? '') ?? DateTime.now().subtract(const Duration(days: 6)),
        soilTemperatureC: (m['soilTemp'] as num?)?.toDouble() ?? 29.0,
      ),
      aadhaarMasked: m['aadhaarMasked']?.toString(),
      pattadarPassbookNo: m['pattadarPassbookNo']?.toString(),
      khataNumber: m['khataNumber']?.toString(),
      village: m['village']?.toString(),
      mandal: m['mandal']?.toString(),
      district: m['district']?.toString(),
      soilType: m['soilType']?.toString(),
    );
  }
}

/// Real-time canal physical and hydrological telemetry
class CanalTelemetry {
  final double mainDischargeCusecs;
  final double waterVelocityMps;
  final double canalBedRoughness;
  final double availableDurationHours;
  final double rainProbabilityPercent;
  final double reservoirHeadLevelMeters;
  final ReservoirTelemetry? reservoir;
  final RainfallDatasetTelemetry? rainfallDataset;

  CanalTelemetry({
    required this.mainDischargeCusecs,
    required this.waterVelocityMps,
    required this.canalBedRoughness,
    required this.availableDurationHours,
    required this.rainProbabilityPercent,
    required this.reservoirHeadLevelMeters,
    this.reservoir,
    this.rainfallDataset,
  });

  double get totalAvailableCusecHours =>
      mainDischargeCusecs * availableDurationHours;

  CanalTelemetry copyWith({
    double? mainDischargeCusecs,
    double? waterVelocityMps,
    double? canalBedRoughness,
    double? availableDurationHours,
    double? rainProbabilityPercent,
    double? reservoirHeadLevelMeters,
    ReservoirTelemetry? reservoir,
    RainfallDatasetTelemetry? rainfallDataset,
  }) {
    return CanalTelemetry(
      mainDischargeCusecs: mainDischargeCusecs ?? this.mainDischargeCusecs,
      waterVelocityMps: waterVelocityMps ?? this.waterVelocityMps,
      canalBedRoughness: canalBedRoughness ?? this.canalBedRoughness,
      availableDurationHours:
          availableDurationHours ?? this.availableDurationHours,
      rainProbabilityPercent:
          rainProbabilityPercent ?? this.rainProbabilityPercent,
      reservoirHeadLevelMeters:
          reservoirHeadLevelMeters ?? this.reservoirHeadLevelMeters,
      reservoir: reservoir ?? this.reservoir,
      rainfallDataset: rainfallDataset ?? this.rainfallDataset,
    );
  }
}

/// Official Government of India Reservoir & Dam Telemetry (data.gov.in)
class ReservoirTelemetry {
  final String reservoirName;
  final double fullDepthMeters;
  final double fullDepthFeet;
  final double capacityMcum;
  final double capacityMcft;
  final double highestLevelMeters;
  final String highestLevelDate;
  final double lowestLevelMeters;
  final String lowestLevelDate;
  final double totalWaterReleasedTmc;

  ReservoirTelemetry({
    required this.reservoirName,
    required this.fullDepthMeters,
    required this.fullDepthFeet,
    required this.capacityMcum,
    required this.capacityMcft,
    required this.highestLevelMeters,
    required this.highestLevelDate,
    required this.lowestLevelMeters,
    required this.lowestLevelDate,
    required this.totalWaterReleasedTmc,
  });

  /// Storage level percentage relative to Full Reservoir Depth (FRL)
  double get storagePercentage => fullDepthMeters > 0
      ? ((highestLevelMeters / fullDepthMeters) * 100).clamp(0.0, 100.0)
      : 0.0;

  factory ReservoirTelemetry.fromJson(Map<String, dynamic> json) {
    return ReservoirTelemetry(
      reservoirName: json['name_of_the_reservoir']?.toString() ?? 'Mettur Dam',
      fullDepthMeters: double.tryParse(
              json['full_reservoir_depth_in_metres']?.toString() ?? '') ??
          36.58,
      fullDepthFeet: double.tryParse(
              json['full_reservoir_depth_in_feet']?.toString() ?? '') ??
          120.0,
      capacityMcum: double.tryParse(
              json['capacity___f_r_l_in_m_cum']?.toString() ?? '') ??
          2647.0,
      capacityMcft: double.tryParse(
              json['capacity___f_r_l_in_m_cft']?.toString() ?? '') ??
          93470.0,
      highestLevelMeters: double.tryParse(
              json['highest_level_reached_metres']?.toString() ?? '') ??
          34.48,
      highestLevelDate:
          json['highest_level_reached_date']?.toString() ?? '18.08.2014',
      lowestLevelMeters: double.tryParse(
              json['lowest_level_reached_metres']?.toString() ?? '') ??
          9.82,
      lowestLevelDate:
          json['lowest_level_reached_date']?.toString() ?? '07.05.2014',
      totalWaterReleasedTmc: double.tryParse(
              json['total_water_released_in_tmc']?.toString() ?? '') ??
          178.67,
    );
  }

  /// Default fallback (Mettur Reservoir — Major South Indian Irrigation Basin)
  factory ReservoirTelemetry.defaultMettur() {
    return ReservoirTelemetry(
      reservoirName: 'Mettur Dam & Reservoir',
      fullDepthMeters: 36.58,
      fullDepthFeet: 120.0,
      capacityMcum: 2647.0,
      capacityMcft: 93470.0,
      highestLevelMeters: 34.48,
      highestLevelDate: '18.08.2014',
      lowestLevelMeters: 9.82,
      lowestLevelDate: '07.05.2014',
      totalWaterReleasedTmc: 178.67,
    );
  }
}

/// 💧 Real Telemetry Rainfall Dataset: Telangana & SW Telangana (2026 - 2030)
class RainfallDatasetTelemetry {
  final String district;
  final String state;
  final String forecastPeriod;
  final int stationCount;
  final double meanHourlyMm;
  final double maxHourlyMm;
  final double totalTelemetryMm;
  final List<RainfallStationRecord> sampleStations;
  final List<String> allDistricts;

  RainfallDatasetTelemetry({
    required this.district,
    required this.state,
    required this.forecastPeriod,
    required this.stationCount,
    required this.meanHourlyMm,
    required this.maxHourlyMm,
    required this.totalTelemetryMm,
    required this.sampleStations,
    required this.allDistricts,
  });

  factory RainfallDatasetTelemetry.fromJson(dynamic rawJson) {
    final json = _safeMap(rawJson);
    final list = json['sample_stations'] as List? ?? [];
    final stations = list
        .map((i) => RainfallStationRecord.fromJson(_safeMap(i)))
        .toList();
    final dists = (json['all_districts'] as List? ?? [])
        .map((e) => e.toString())
        .toList();

    return RainfallDatasetTelemetry(
      district: json['district']?.toString() ?? 'NALGONDA',
      state: json['state']?.toString() ?? 'Telangana',
      forecastPeriod: json['forecast_period']?.toString() ??
          '2026 - 2030 (SW Telangana & Telangana Telemetry)',
      stationCount: int.tryParse(json['station_count']?.toString() ?? '1') ?? 1,
      meanHourlyMm:
          double.tryParse(json['mean_hourly_mm']?.toString() ?? '4.0') ?? 4.0,
      maxHourlyMm:
          double.tryParse(json['max_hourly_mm']?.toString() ?? '257.0') ?? 257.0,
      totalTelemetryMm:
          double.tryParse(json['total_telemetry_mm']?.toString() ?? '1004.5') ??
              1004.5,
      sampleStations: stations,
      allDistricts: dists.isNotEmpty
          ? dists
          : [
              'NALGONDA',
              'MAHBUBNAGAR',
              'NAGARKURNOOL',
              'WANAPARTHY',
              'JOGULAMBA(GADWAL)'
            ],
    );
  }

  factory RainfallDatasetTelemetry.defaultNalgonda() {
    return RainfallDatasetTelemetry(
      district: 'NALGONDA',
      state: 'Telangana',
      forecastPeriod: '2026 - 2030 (SW Telangana & Telangana Telemetry)',
      stationCount: 22,
      meanHourlyMm: 4.07,
      maxHourlyMm: 257.0,
      totalTelemetryMm: 1004.5,
      sampleStations: [
        RainfallStationRecord(
          station: 'NALGONDA TELEMETRY 1',
          tehsil: 'Nalgonda',
          village: 'Nalgonda South',
          rainfallMm: 39.0,
          time: '19-02-2026 23:00',
        ),
      ],
      allDistricts: [
        'NALGONDA',
        'MAHBUBNAGAR',
        'NAGARKURNOOL',
        'WANAPARTHY',
        'JOGULAMBA(GADWAL)',
        'NIRMAL',
        'SIDDIPET',
        'ADILABAD',
        'KARIMNAGAR'
      ],
    );
  }
}

class RainfallStationRecord {
  final String station;
  final String tehsil;
  final String village;
  final double rainfallMm;
  final String time;

  RainfallStationRecord({
    required this.station,
    required this.tehsil,
    required this.village,
    required this.rainfallMm,
    required this.time,
  });

  factory RainfallStationRecord.fromJson(Map<String, dynamic> json) {
    return RainfallStationRecord(
      station: json['station']?.toString() ?? '',
      tehsil: json['tehsil']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      rainfallMm:
          double.tryParse(json['rainfall_mm']?.toString() ?? '0') ?? 0.0,
      time: json['time']?.toString() ?? '',
    );
  }
}
