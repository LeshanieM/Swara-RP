import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/concomitant_assessment.dart';

final component2MockProvider = Provider<Component2MockService>((ref) {
  return Component2MockService();
});

final concomitantHistoryProvider = FutureProvider.family<List<ConcomitantAssessment>, String>((ref, childId) async {
  return [await ref.watch(component2MockProvider).getAssessmentResults('mock-id')];
});

final concomitantAssessmentProvider = FutureProvider.family<ConcomitantAssessment, String>((ref, id) async {
  return ref.watch(component2MockProvider).getAssessmentResults(id);
});

class Component2MockService {
  Future<ConcomitantAssessment> getAssessmentResults(String id) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return ConcomitantAssessment(
      id: id,
      childId: 'mock-child-id',
      taskType: 'Reading',
      duration: 120,
      analysisStatus: 'completed',
      physicalConcomitants: {
        'facialTension': {'score': 2, 'candidateEvents': 5, 'confidence': 0.85},
        'eyeMovements': {'score': 1, 'candidateEvents': 2, 'confidence': 0.70},
        'headMovements': {'score': 0, 'candidateEvents': 0, 'confidence': 0.95},
        'extremityMovements': {'score': 1, 'candidateEvents': 1, 'confidence': 0.65},
      },
      vocalAvoidanceIndicators: {
        'responseLatency': {'elevated': false, 'baseline': 1.0, 'timestamps': []},
        'wordSubstitution': [
          {'originalWord': 'cat', 'detectedAlternative': 'kitty', 'confidence': 0.75, 'timestamp': 45.0}
        ],
        'circumlocution': [
          {'utterance': 'the animal that purrs', 'confidence': 0.8, 'timestamp': 62.0}
        ],
        'acousticTension': {'summary': 'Normal pitch variation', 'candidateTimestamps': [], 'confidence': 0.9},
      },
      eventTimeline: [
        {'timestamp': 18.0, 'eventType': 'Facial movement', 'source': 'Component 2', 'details': 'Small mouth tension detected.', 'confidence': 0.85},
        {'timestamp': 31.0, 'eventType': 'Eye movement', 'source': 'Component 2', 'details': 'Rapid blinking detected.', 'confidence': 0.75},
        {'timestamp': 46.0, 'eventType': 'Facial movement', 'source': 'Component 2', 'details': 'Tension detected during speaking.', 'confidence': 0.82},
        {'timestamp': 62.0, 'eventType': 'Speaking pattern', 'source': 'Component 2', 'details': 'Possible change in normal speaking pattern.', 'confidence': 0.80},
      ],
      modelConfidence: 0.8,
      clinicianVerification: {},
      createdAt: DateTime.now(),
    );
  }
}
