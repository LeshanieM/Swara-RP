import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TherapyApiService {
  static const String baseUrl = kIsWeb ? 'http://localhost:5000/api/c3' : 'http://10.0.2.2:5000/api/c3'; // Handles both Chrome and Android emulator

  static Future<String?> getNextActivity(String childId, String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations/next-activity'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'childId': childId,
          'sessionId': sessionId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['activity']?['name'];
      }
    } catch (e) {
      debugPrint('TherapyApiService API Error: $e');
    }
    return null;
  }

  static Future<void> recordActivityResult(String sessionId, String activityId, double score, int duration) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/therapy-sessions/$sessionId/activity-result'),
        headers: {'Content-Type': 'application/json'},
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

  static Future<void> completeSession(String sessionId) async {
    try {
      await http.post(Uri.parse('$baseUrl/therapy-sessions/$sessionId/complete'));
    } catch (e) {
      debugPrint('TherapyApiService API Error: $e');
    }
  }

  static Future<List<dynamic>> getTherapyHistory(String childId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/therapy-sessions/history/$childId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      debugPrint('TherapyApiService API Error: $e');
    }
    return [];
  }

  static Future<bool> uploadAudio(String filePath, String childId) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5000/api/speech/analyze-speech'));
      if (!kIsWeb) request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/speech/analyze-speech'));
      
      request.files.add(await http.MultipartFile.fromPath('audio', filePath));
      request.fields['childId'] = childId;
      
      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Upload Audio Error: $e');
      return false;
    }
  }
}
