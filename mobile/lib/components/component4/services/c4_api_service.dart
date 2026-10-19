import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Authenticated client for the existing Node C4 routes.
class C4ApiService {
  C4ApiService(this._api);
  final ApiClient _api;
  static const String _base = '/api/communication/c4';

  Future<Map<String, dynamic>> preferences(String childId) async =>
      Map<String, dynamic>.from((await _api.get('$_base/$childId/preferences')).data);

  Future<Map<String, dynamic>> savePreferences(String childId, List<String> rankedInterests) async =>
      Map<String, dynamic>.from((await _api.put('$_base/$childId/preferences', data: {'rankedInterests': rankedInterests})).data);

  Future<Map<String, dynamic>> nextTopic(String childId, {int? seed, String? languageProgress, String? tssTrend}) async =>
      Map<String, dynamic>.from((await _api.post('$_base/$childId/topics/next', data: {
        if (seed != null) 'seed': seed,
        if (languageProgress != null) 'languageProgress': languageProgress,
        if (tssTrend != null) 'tssTrend': tssTrend,
      })).data);

  Future<Map<String, dynamic>> startSession(String childId, String topicId) async =>
      Map<String, dynamic>.from((await _api.post('$_base/sessions', data: {'childId': childId, 'topicId': topicId})).data);

  Future<List<dynamic>> topics(String ageBand, {bool approvedOnly = false}) async =>
      List<dynamic>.from((await _api.get('$_base/topics', queryParameters: {
        'ageBand': ageBand,
        if (approvedOnly) 'approvedOnly': 'true',
      })).data);

  Future<Map<String, dynamic>> followUps(String sessionId) async =>
      Map<String, dynamic>.from((await _api.get('$_base/sessions/$sessionId/followups')).data);

  Future<Map<String, dynamic>> skip(String sessionId, {String? topicId, int? followUpIndex}) async =>
      Map<String, dynamic>.from((await _api.post('$_base/sessions/$sessionId/skip', data: {
        if (topicId != null) 'topicId': topicId,
        if (followUpIndex != null) 'followUpIndex': followUpIndex,
      })).data);

  Future<Map<String, dynamic>> complete(String sessionId, {bool earlyCompletion = false}) async =>
      Map<String, dynamic>.from((await _api.post('$_base/sessions/$sessionId/complete', data: {'earlyCompletion': earlyCompletion})).data);

  Future<Map<String, dynamic>> analyzeRecording(String sessionId, String audioPath) async {
    final form = FormData.fromMap({'audio': await MultipartFile.fromFile(audioPath)});
    return Map<String, dynamic>.from((await _api.postMultipart('$_base/sessions/$sessionId/analyze', form)).data);
  }

  Future<Map<String, dynamic>> correctTranscript(String sessionId, String transcript) async =>
      Map<String, dynamic>.from((await _api.put('$_base/sessions/$sessionId/transcript', data: {'transcript': transcript})).data);

  Future<List<dynamic>> sessions(String childId) async =>
      List<dynamic>.from((await _api.get('$_base/$childId/sessions')).data);

  Future<Map<String, dynamic>> export(String childId) async =>
      Map<String, dynamic>.from((await _api.get('$_base/$childId/export')).data);
}
