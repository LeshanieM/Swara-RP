class ChildModel {
  final String id;
  final String childId;
  final String firstName;
  final int age;
  final String? gender;
  final DateTime? dateOfBirth;
  final List<String> interests;
  final String? severity;
  final String? stutterType;
  final String? parentId;
  final String? therapistId;
  final double? supportIndicator;
  final double? communicationScore;
  final String? assignedTheme;

  const ChildModel({
    required this.id,
    required this.childId,
    required this.firstName,
    required this.age,
    this.gender,
    this.dateOfBirth,
    required this.interests,
    this.severity,
    this.stutterType,
    this.parentId,
    this.therapistId,
    this.supportIndicator,
    this.communicationScore,
    this.assignedTheme,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['_id'] ?? json['id'] ?? '',
      childId: json['childId'] ?? '',
      firstName: json['firstName'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      interests: List<String>.from(json['interests'] ?? []),
      severity: json['severity'],
      stutterType: json['stutterType'],
      parentId: json['parentId'],
      therapistId: json['therapistId'],
      supportIndicator: (json['supportIndicator'] as num?)?.toDouble(),
      communicationScore: (json['communicationScore'] as num?)?.toDouble(),
      assignedTheme: json['assignedTheme'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'childId': childId,
        'firstName': firstName,
        'age': age,
        'gender': gender,
        'interests': interests,
        'severity': severity,
        'stutterType': stutterType,
        'parentId': parentId,
        'therapistId': therapistId,
        'supportIndicator': supportIndicator,
        'communicationScore': communicationScore,
      };

  String get displayName => firstName;

  String get severityDisplay => severity ?? 'Not Assessed';

  String get stutterTypeDisplay => stutterType ?? 'Not Assessed';
}
