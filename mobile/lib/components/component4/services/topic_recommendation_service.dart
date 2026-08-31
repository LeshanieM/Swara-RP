import '../models/communication_assessment.dart';
import '../models/communication_topic.dart';
import '../mock/component4_mock_data.dart';

class TopicRecommendationService {
  Future<CommunicationTopic> generateTopic(CommunicationAssessment assessment) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network/processing delay

    if (assessment.age <= 7) {
      return Component4MockData.mockTopics.firstWhere((t) => t.id == 't_animal');
    } else if (assessment.age <= 10) {
      return Component4MockData.mockTopics.firstWhere((t) => t.id == 't_zoo');
    } else {
      return Component4MockData.mockTopics.firstWhere((t) => t.id == 't_adventure');
    }
  }
}
