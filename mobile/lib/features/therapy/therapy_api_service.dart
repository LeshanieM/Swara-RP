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

  static Future<bool> startSession() async {
    try {
      final userId = await _currentUserId();
      if (userId == null) return false;
      final response = await http.post(
        Uri.parse('$baseUrl/therapy-sessions'),
        headers: await _authHeaders(),
        body: jsonEncode({}),
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
      debugPrint('TherapyApiService API Error: $e');
    }
    return false;
  }

  static Future<void> recordActivityResult(
      String sessionId, String activityId, double score, int duration) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/therapy-sessions/$sessionId/activity-result'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'activityId': activityId,
          'score': score,
          'duration': duration,
        }),
      );
    } catch (e) {
      debugPrint('TherapyApiService API Error: $e');
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
      debugPrint('TherapyApiService API Error: $e');
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
      debugPrint('TherapyApiService API Error: $e');
    }
    return [];
  }

  static Future<bool> uploadAudio(String filePath) async {
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
