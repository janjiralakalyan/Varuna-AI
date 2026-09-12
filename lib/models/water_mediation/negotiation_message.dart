enum MessageRole {
  centralMediationAgent, // Jala-Mitra AI
  farmerAgent, // Specific farmer's autonomous bot
  systemTelemetry, // IoT Event / Sensor Alert
}

enum ProposalStatus {
  submitted,
  underReview,
  objected,
  counterProposed,
  accepted,
  finalized,
}

/// A structured multi-agent negotiation message
class NegotiationMessage {
  final String id;
  final String senderName;
  final String senderRoleTitle;
  final String? senderAvatar;
  final MessageRole role;
  final String content;
  final String? technicalExplanation;
  final DateTime timestamp;
  final ProposalStatus? status;
  final Map<String, dynamic>? dataMetrics;
  final Map<String, dynamic>? metadata;
  final bool? isCounterOffer;

  NegotiationMessage({
    required this.id,
    required this.senderName,
    this.senderRoleTitle = '',
    this.senderAvatar,
    required this.role,
    required this.content,
    this.technicalExplanation,
    required this.timestamp,
    this.status,
    this.dataMetrics,
    this.metadata,
    this.isCounterOffer,
  });
}

/// A generated schedule slot for a farmer along the canal branch
class WaterScheduleSlot {
  final String farmerId;
  final String farmerName;
  final String cropName;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final double effectiveDischargeCusecs;
  final double transmissionLossCompensatedHours;
  final String sluiceGateNumber;
  final String slotReasoning;

  WaterScheduleSlot({
    required this.farmerId,
    required this.farmerName,
    required this.cropName,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.effectiveDischargeCusecs,
    required this.transmissionLossCompensatedHours,
    required this.sluiceGateNumber,
    required this.slotReasoning,
  });
}

/// Tamper-evident digital water agreement and audit certificate
class WaterSharingAgreement {
  final String agreementId;
  final DateTime createdAt;
  final double totalWaterAllocatedHours;
  final double waterSavingHoursDueToRain;
  final double giniEquityIndex;
  final List<WaterScheduleSlot> scheduleSlots;
  final List<String> farmerSignatures;
  final String auditHash;
  final bool isConsensusReached;

  WaterSharingAgreement({
    required this.agreementId,
    required this.createdAt,
    required this.totalWaterAllocatedHours,
    required this.waterSavingHoursDueToRain,
    required this.giniEquityIndex,
    required this.scheduleSlots,
    required this.farmerSignatures,
    required this.auditHash,
    required this.isConsensusReached,
  });
}
