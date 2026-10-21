import 'package:dio/dio.dart';
import 'package:swara/core/audio/wav_recorder.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/network/api_exception.dart';

/// Component 3 on the Swara API (/api/c3). The server's Hybrid LinUCB chooses each
/// activity; the app posts what happened and the server returns the next step.
/// Every call throws [ApiException] on failure.
class TherapyApiService {
  static final ApiClient _api = ApiClient();

  static Future<Map<String, dynamic>> _call(
      Future<Response> Function() request) async {
    try {
      final res = await request();
      return res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static Future<Map<String, dynamic>> startSession(
          {required String childId, required int age, bool cameraOn = false}) =>
      _call(() => _api.post('/api/c3/sessions', data: {
            'childId': childId,
            'age': age,
            'language': 'si',
            'cameraOn': cameraOn
          }));

  /// 201 with `activity` and `item`, or 200 with `activity: null` once the planned time is used.
  static Future<Map<String, dynamic>> nextActivity(String sessionId,
          {List<String> excludeArmIds = const []}) =>
      _call(() => _api.post('/api/c3/sessions/$sessionId/next-activity', data: {
            if (excludeArmIds.isNotEmpty) 'excludeArmIds': excludeArmIds,
          }));

  static Future<Map<String, dynamic>> postResult(
          String sessionId, String attemptId, Map<String, dynamic> result) =>
      _call(() => _api.post(
          '/api/c3/sessions/$sessionId/activities/$attemptId/result',
          data: result));

  /// One recording of one target word → `{decision: match | mismatch | unclear, expected, heard, ...}`.
  static Future<Map<String, dynamic>> wordCheck(String sessionId,
      String attemptId, RecordedAudio audio, int wordIndex) async {
    final form = FormData.fromMap({
      'audio': await audio.toMultipart('word.wav'),
      'wordIndex': wordIndex,
    });
    return _call(() => _api.postMultipart(
        '/api/c3/sessions/$sessionId/activities/$attemptId/word-checks', form));
  }

  /// Reading / picture description: the whole recording → `{mode, decision: match | partial | mismatch | unclear, share, ...}`.
  static Future<Map<String, dynamic>> speechCheck(
      String sessionId, String attemptId, RecordedAudio audio) async {
    final form =
        FormData.fromMap({'audio': await audio.toMultipart('answer.wav')});
    return _call(() => _api.postMultipart(
        '/api/c3/sessions/$sessionId/activities/$attemptId/speech-check',
        form));
  }

  /// `{session, activitiesDone, pending}`: the session that can still be continued, or `{session: null}`.
  static Future<Map<String, dynamic>> activeSession(String childId) =>
      _call(() => _api.get('/api/c3/children/$childId/sessions/active'));

  static Future<Map<String, dynamic>> takeBreak(String sessionId,
          {String reason = 'low_engagement', int? durationSec}) =>
      _call(() => _api.post('/api/c3/sessions/$sessionId/breaks', data: {
            'reason': reason,
            if (durationSec != null) 'durationSec': durationSec,
          }));

  static Future<Map<String, dynamic>> complete(String sessionId) =>
      _call(() => _api.post('/api/c3/sessions/$sessionId/complete'));

  static Future<Map<String, dynamic>> questionnaire() =>
      _call(() => _api.get('/api/c3/questionnaire'));

  static Future<Map<String, dynamic>> submitQuestionnaire(
          String sessionId, Map<String, int> answers) =>
      _call(() => _api.post('/api/c3/sessions/$sessionId/questionnaire',
          data: {'answers': answers, 'language': 'si'}));

  static Future<Map<String, dynamic>> activities(int age) => _call(
      () => _api.get('/api/c3/activities', queryParameters: {'age': age}));

  static Future<Map<String, dynamic>> summary(String childId) =>
      _call(() => _api.get('/api/c3/children/$childId/summary'));

  /// Completed and active sessions, newest first, in the shape the history and
  /// engagement screens read (`resultSummary` with the TSS as the score out of 100).
  static Future<List<Map<String, dynamic>>> getTherapyHistory(
      String childId) async {
    final data = await _call(() => _api.get(
        '/api/c3/children/$childId/sessions',
        queryParameters: {'limit': 50}));
    final items = data['items'] is List ? data['items'] as List : const [];
    return [
      for (final raw in items.whereType<Map>())
        () {
          final session = Map<String, dynamic>.from(raw);
          final outcome = session['outcome'] is Map
              ? Map<String, dynamic>.from(session['outcome'] as Map)
              : null;
          final created =
              DateTime.tryParse(session['createdAt']?.toString() ?? '');
          final finished =
              DateTime.tryParse(session['completedAt']?.toString() ?? '');
          final completed = session['status'] == 'completed';
          return {
            'id': session['id'],
            'createdAt': session['createdAt'],
            // abandoned: left unfinished and closed by the server after the resume window.
            'status': switch (session['status']) {
              'completed' => 'Completed',
              'abandoned' => 'Not finished',
              _ => 'In progress'
            },
            if (completed && outcome != null)
              'resultSummary': {
                'activitiesCompleted': outcome['activitiesCompleted'] ?? 0,
                'activitiesSkipped': outcome['activitiesSkipped'] ?? 0,
                'activitiesTotal': (outcome['activitiesCompleted'] ?? 0) +
                    (outcome['activitiesSkipped'] ?? 0) +
                    (outcome['activitiesAbandoned'] ?? 0),
                'score': outcome['tss'],
                'scoreOutOf': 100,
                'engagement': outcome['meanEngagement'],
                if (created != null && finished != null)
                  'durationMinutes': finished.difference(created).inMinutes,
              },
          };
        }(),
    ];
  }
}
