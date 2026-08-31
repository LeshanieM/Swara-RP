class AssessmentData {
  final int age;
  final String severity;
  final String stutteringType;
  final int stutteredWords;
  final int totalSyllables;
  final double stutterRate;
  final Component2Data component2;

  AssessmentData({
    required this.age,
    required this.severity,
    required this.stutteringType,
    required this.stutteredWords,
    required this.totalSyllables,
    required this.stutterRate,
    required this.component2,
  });

  factory AssessmentData.mock() {
    return AssessmentData(
      age: 10,
      severity: 'Moderate',
      stutteringType: 'Repetition',
      stutteredWords: 12,
      totalSyllables: 180,
      stutterRate: 6.7,
      component2: Component2Data(
        physicalBehaviorScore: 61,
        headMovement: 18,
        eyeBlink: 27,
        facialMovement: 12,
        handMovement: 9,
        bodyMovement: 6,
      ),
    );
  }
}

class Component2Data {
  final int physicalBehaviorScore;
  final int headMovement;
  final int eyeBlink;
  final int facialMovement;
  final int handMovement;
  final int bodyMovement;

  Component2Data({
    required this.physicalBehaviorScore,
    required this.headMovement,
    required this.eyeBlink,
    required this.facialMovement,
    required this.handMovement,
    required this.bodyMovement,
  });
}
