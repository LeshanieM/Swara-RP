import 'c4_api_service.dart';

/// C4 analysis client. Results come from a persisted backend session; no local mock is returned.
class CommunicationScoreService {
  CommunicationScoreService(this._api);
  final C4ApiService _api;

  Future<Map<String, dynamic>> analyzeRecording(String sessionId, String recordingPath) =>
      _api.analyzeRecording(sessionId, recordingPath);

  Future<Map<String, dynamic>> correctTranscript(String sessionId, String transcript) =>
      _api.correctTranscript(sessionId, transcript);
}
