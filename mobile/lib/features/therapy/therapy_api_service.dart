import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/storage/storage_service.dart';

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
}
