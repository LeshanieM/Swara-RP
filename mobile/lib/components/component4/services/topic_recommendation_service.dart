import 'c4_api_service.dart';

/// Topic recommendations are selected and recorded by the authenticated Node API.
class TopicRecommendationService {
  TopicRecommendationService(this._api);
  final C4ApiService _api;

  Future<Map<String, dynamic>> generateTopic(String childId) => _api.nextTopic(childId);
}
