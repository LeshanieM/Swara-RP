class ConcomitantAssessment {
  final String id;
  final String childId;
  final String? speechAssessmentId;
  final String taskType;
  final int duration;
  final String analysisStatus;
  final Map<String, dynamic> physicalConcomitants;
  final Map<String, dynamic> vocalAvoidanceIndicators;
  final List<dynamic> eventTimeline;
  final double modelConfidence;
  final Map<String, dynamic> clinicianVerification;
  final DateTime createdAt;

  ConcomitantAssessment({
    required this.id,
    required this.childId,
    this.speechAssessmentId,
    required this.taskType,
    required this.duration,
    required this.analysisStatus,
    required this.physicalConcomitants,
    required this.vocalAvoidanceIndicators,
    required this.eventTimeline,
    required this.modelConfidence,
    required this.clinicianVerification,
    required this.createdAt,
  });

  factory ConcomitantAssessment.fromJson(Map<String, dynamic> json) {
    return ConcomitantAssessment(
      id: json['_id'] ?? '',
      childId: json['childId'] is Map ? json['childId']['_id'] : (json['childId'] ?? ''),
      speechAssessmentId: json['speechAssessmentId'] is Map ? json['speechAssessmentId']['_id'] : json['speechAssessmentId'],
      taskType: json['taskType'] ?? 'Unknown',
      duration: json['duration'] ?? 0,
      analysisStatus: json['analysisStatus'] ?? 'pending',
      physicalConcomitants: json['physicalConcomitants'] ?? {},
      vocalAvoidanceIndicators: json['vocalAvoidanceIndicators'] ?? {},
      eventTimeline: json['eventTimeline'] ?? [],
      modelConfidence: (json['modelConfidence'] as num?)?.toDouble() ?? 0.0,
      clinicianVerification: json['clinicianVerification'] ?? {},
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
