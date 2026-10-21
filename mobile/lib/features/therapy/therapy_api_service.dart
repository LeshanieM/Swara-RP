import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/storage/storage_service.dart';

/// The outcome of one defined-answer speech prompt.
///
/// `could_not_recognize` is deliberately distinct from `mismatch`: an
/// uncertain transcription must never be presented as a wrong child answer.
class SpeechVerificationResult {
  final String status;
  final String recognizedText;
  final double? confidence;
  final double? similarity;
  final String? message;

  const SpeechVerificationResult({
    required this.status,
    this.recognizedText = '',
    this.confidence,
    this.similarity,
    this.message,
  });

  bool get isMatch => status == 'match';
  bool get isUncertain => status == 'could_not_recognize';
}

class TherapyApiService {
  static const String activeSessionStorageKey = 'c3_active_session_id';
  static String get baseUrl => '${AppConstants.baseUrl}/api/c3';

  static String _sessionKey(String userId) =>
      '${activeSessionStorageKey}_$userId';

  static Future<String?> _currentUserId() async {
    final userJson = await StorageService.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      final userId = user['id']?.toString();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> getActiveSessionId() async {
    final userId = await _currentUserId();
    if (userId == null) return null;
    return await StorageService.getString(_sessionKey(userId));
  }

  static Future<String?> getOrCreateActiveSessionId() async {
    final existing = await getActiveSessionId();
    if (existing != null && existing.isNotEmpty) return existing;
    final started = await startSession();
    if (started) {
      return await getActiveSessionId();
    }
    return null;
  }

  static Future<bool> startSession() async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final response = await http.post(
        Uri.parse('$baseUrl/therapy-sessions'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'modelVersion': 'linucb_v3',
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = data['data'] as Map<String, dynamic>?;
        final sessionId = session?['sessionId']?.toString();
        if (sessionId == null || sessionId.isEmpty) return false;
        await StorageService.saveString(_sessionKey(userId), sessionId);
        return true;
      }
    } catch (e) {
      debugPrint('TherapyApiService startSession Error: $e');
    }
    return false;
  }

  static Future<bool> recordActivityResult({
    String? sessionId,
    required String activityId,
    int? targetOpportunities,
    int? successfulOpportunities,
    double? completionFraction,
    int? durationSeconds,
    bool completed = true,
    bool skipped = false,
    String? parentDifficultyFeedback,
    int? parentHelpLevel,
    double? engagementScore,
    String engagementMode = 'logs_only',
  }) async {
    try {
      final activeSessionId = sessionId ?? await getOrCreateActiveSessionId();
      if (activeSessionId == null) return false;

      final payload = <String, dynamic>{
        'activityId': activityId,
        'completed': completed,
        'skipped': skipped,
        'engagementMode': engagementMode,
      };

      if (targetOpportunities != null) {
        payload['targetOpportunities'] = targetOpportunities;
      }
      if (successfulOpportunities != null) {
        payload['successfulOpportunities'] = successfulOpportunities;
      }
      if (completionFraction != null) {
        payload['completionFraction'] = completionFraction;
      }
      if (durationSeconds != null) {
        payload['durationSeconds'] = durationSeconds;
      }
      if (parentDifficultyFeedback != null) {
        payload['parentDifficultyFeedback'] = parentDifficultyFeedback;
      }
      if (parentHelpLevel != null) {
        payload['parentHelpLevel'] = parentHelpLevel;
      }
      if (engagementScore != null) {
        payload['engagementScore'] = engagementScore;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/therapy-sessions/$activeSessionId/activity-result'),
        headers: await _authHeaders(),
        body: jsonEncode(payload),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('TherapyApiService recordActivityResult Error: $e');
      return false;
    }
  }

  static Future<bool> completeActiveSession({
    required Map<String, dynamic> resultSummary,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final sessionId = await StorageService.getString(_sessionKey(userId));
      if (sessionId == null || sessionId.isEmpty) return false;
      final response = await http.post(
        Uri.parse('$baseUrl/therapy-sessions/$sessionId/complete'),
        headers: await _authHeaders(),
        body: jsonEncode({'resultSummary': resultSummary}),
      );
      if (response.statusCode != 200) return false;
      await StorageService.remove(_sessionKey(userId));
      return true;
    } catch (e) {
      debugPrint('TherapyApiService completeActiveSession Error: $e');
      return false;
    }
  }

  static Future<bool> submitParentQuestionnaire({
    String? sessionId,
    required Map<String, int> responses,
  }) async {
    try {
      final activeSessionId = sessionId ?? await getActiveSessionId();
      if (activeSessionId == null) return false;
      final response = await http.post(
        Uri.parse('$baseUrl/therapy-sessions/$activeSessionId/questionnaire'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'version': 'prime_o_adapt_v1',
          'responses': responses,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('TherapyApiService submitQuestionnaire Error: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getTherapyHistory() async {
    try {
      if (await _currentUserId() == null) return [];
      final response = await http.get(
        Uri.parse('$baseUrl/therapy-sessions/history/account'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('TherapyApiService getTherapyHistory Error: $e');
    }
    return [];
  }

  static Future<bool> uploadAudio(String filePath) async {
    if (kIsWeb) {
      // In web browser mode, multipart audio from local paths is simulated/logs-only
      debugPrint('[TherapyApiService] Audio recording stored in memory (Web mode): $filePath');
      return true;
    }
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/speech/analyze'),
      );
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));
      request.fields['ownerId'] = userId;

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Upload Audio Error: $e');
      return false;
    }
  }

  /// Sends a single response for transcription and local-target verification.
  /// The server stores text-only verification metadata; neither layer persists
  /// the raw child audio after this request completes.
  static Future<SpeechVerificationResult> verifySpeechResponse({
    required String audioPath,
    required String activityId,
    required String promptId,
    required List<String> expectedAnswers,
    String? sessionId,
  }) async {
    if (kIsWeb) {
      return const SpeechVerificationResult(
        status: 'could_not_recognize',
        message: 'වචනය පරීක්ෂා කිරීම සඳහා ජංගම යෙදුම භාවිතා කරන්න.',
      );
    }
    try {
      final activeSessionId = sessionId ?? await getOrCreateActiveSessionId();
      if (activeSessionId == null) {
        return const SpeechVerificationResult(
          status: 'could_not_recognize',
          message: 'සැසිය ආරම්භ කළ නොහැකි විය. නැවත උත්සාහ කරන්න.',
        );
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/therapy-sessions/$activeSessionId/speech-verification'),
      );
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll({
        'activityId': activityId,
        'promptId': promptId,
        'expectedAnswers': jsonEncode(expectedAnswers),
      });
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final decoded = body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (response.statusCode == 200 && data != null) {
        return SpeechVerificationResult(
          status: data['status']?.toString() ?? 'could_not_recognize',
          recognizedText: data['recognizedText']?.toString() ?? '',
          confidence: (data['confidence'] as num?)?.toDouble(),
          similarity: (data['similarity'] as num?)?.toDouble(),
        );
      }
      return SpeechVerificationResult(
        status: 'could_not_recognize',
        message: decoded['message']?.toString() ??
            'හඬ හඳුනාගත නොහැකි විය. නැවත උත්සාහ කරන්න.',
      );
    } catch (error) {
      debugPrint('TherapyApiService verifySpeechResponse Error: $error');
      return const SpeechVerificationResult(
        status: 'could_not_recognize',
        message: 'හඬ පරීක්ෂා කළ නොහැකි විය. නැවත උත්සාහ කරන්න.',
      );
    }
  }

  static Future<Map<String, dynamic>?> fetchClinicalContext({
    bool cameraOn = false,
    String? activityType,
    double? parentHelpLevel,
  }) async {
    try {
      final queryParams = <String, String>{
        'cameraOn': cameraOn.toString(),
        if (activityType != null) 'activityType': activityType,
        if (parentHelpLevel != null) 'parentHelpLevel': parentHelpLevel.toString(),
      };
      final uri = Uri.parse('$baseUrl/recommendations/context')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _authHeaders());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('TherapyApiService fetchClinicalContext Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchSharedLinUcbState() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recommendations/shared-state'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('TherapyApiService fetchSharedLinUcbState Error: $e');
    }
    return null;
  }

  static Future<bool> syncLinUcbState({
    required List<Map<String, dynamic>> armUpdates,
    Map<String, dynamic>? sharedDelta,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations/sync'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'armUpdates': armUpdates,
          'sharedDelta': sharedDelta,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('TherapyApiService syncLinUcbState Error: $e');
      return false;
    }
  }
}

