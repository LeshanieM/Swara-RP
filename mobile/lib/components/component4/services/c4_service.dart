import 'package:dio/dio.dart';
import 'package:swara/core/audio/wav_recorder.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/network/api_exception.dart';

/// Component 4 on the Swara API (/api/c4): topic bank, onboarding profile, sessions,
/// the recording upload, and the background sample analysis. Throws [ApiException].
class C4Service {
  static final ApiClient _api = ApiClient();

  static Future<Map<String, dynamic>> _call(Future<Response> Function() request) async {
    try {
      final res = await request();
      return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static Future<Map<String, dynamic>> categories(int age) =>
      _call(() => _api.get('/api/c4/catalog/categories', queryParameters: {'age': age}));

  /// The child's profile, or null before onboarding.
  static Future<Map<String, dynamic>?> profile(String childId) async {
    try {
      return await _call(() => _api.get('/api/c4/children/$childId/profile'));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveProfile(String childId, int age, List<String> rankedCategories) =>
      _call(() => _api.put('/api/c4/children/$childId/profile', data: {
            'age': age,
            'language': 'si',
            'rankedCategories': rankedCategories,
          }));

  /// [mode] is `personalised` or `fixed` (the fixed topic sequence, the control for the topic study).
  static Future<Map<String, dynamic>> startSession(String childId, {String mode = 'personalised'}) =>
      _call(() => _api.post('/api/c4/sessions', data: {'childId': childId, 'mode': mode}));

  /// How many C4 sessions the child has started.
  static Future<int> sessionCount(String childId) async {
    final res = await _call(() => _api.get('/api/c4/children/$childId/sessions', queryParameters: {'limit': 1}));
    return (res['total'] as num?)?.toInt() ?? 0;
  }

  /// The parent checklist for the child's age band: `{ageBand, items: [{id, text: {si, en}}], ...}`.
  static Future<Map<String, dynamic>> checklist(int age) =>
      _call(() => _api.get('/api/c4/catalog/checklist', queryParameters: {'age': age}));

  /// Parent mode. Sets the child's starting level from the yes answers.
  static Future<Map<String, dynamic>> submitChecklist(String childId, Map<String, bool> answers) =>
      _call(() => _api.post('/api/c4/children/$childId/checklist', data: {
            'respondent': 'parent',
            'answers': [for (final e in answers.entries) {'itemId': e.key, 'answer': e.value}],
          }));

  /// Parent mode. Saves a corrected transcript as a new version and re-measures the sample.
  static Future<Map<String, dynamic>> editTranscript(String sampleId, String text) =>
      _call(() => _api.put('/api/c4/samples/$sampleId/transcript',
          data: {'text': text, 'kind': 'corrected', 'editedBy': 'parent'}));

  /// Parent mode. [decision] is `confirm` or `override` (then [band] is below / stable / gaining).
  static Future<Map<String, dynamic>> confirmBand(String sampleId, String decision, {String? band}) =>
      _call(() => _api.post('/api/c4/samples/$sampleId/band-confirmation', data: {
            'by': 'parent',
            'decision': decision,
            if (band != null) 'band': band,
          }));

  static Future<Map<String, dynamic>> nextPrompt(String sessionId) =>
      _call(() => _api.post('/api/c4/sessions/$sessionId/next-prompt'));

  /// The child didn't understand the follow-up question: log it and move to the next one.
  static Future<Map<String, dynamic>> skipFollowUp(String sessionId) =>
      _call(() => _api.post('/api/c4/sessions/$sessionId/skips', data: {'kind': 'follow_up', 'reason': 'did_not_understand'}));

  static Future<Map<String, dynamic>> anotherTopic(String sessionId) =>
      _call(() => _api.post('/api/c4/sessions/$sessionId/skips', data: {'kind': 'main_prompt'}));

  /// Uploads the answer; returns the sample id (analysed in the background).
  static Future<String> uploadRecording(String sessionId, RecordedAudio audio) async {
    final form = FormData.fromMap({'audio': await audio.toMultipart('answer.wav')});
    final res = await _call(() => _api.postMultipart('/api/c4/sessions/$sessionId/recordings', form));
    return res['sampleId'] as String;
  }

  static Future<Map<String, dynamic>> sample(String sampleId) => _call(() => _api.get('/api/c4/samples/$sampleId'));

  static Future<Map<String, dynamic>> progress(String childId) =>
      _call(() => _api.get('/api/c4/children/$childId/progress'));

  static Future<Map<String, dynamic>> summary(String childId) =>
      _call(() => _api.get('/api/c4/children/$childId/summary'));
}
