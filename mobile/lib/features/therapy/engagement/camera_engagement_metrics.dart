import 'dart:convert';

import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/storage/storage_service.dart';

class CameraEngagementSnapshot {
  static const String modelVersion = 'camera-feature-baseline-v1';
  static const String _storageKeyPrefix = 'c3_camera_engagement_latest_';

  final DateTime recordedAt;
  final int durationSeconds;
  final bool cameraEnabled;
  final double? engagementScore;
  final double faceVisibility;
  final double? lookingAtScreen;
  final double? eyesOpen;
  final double? smileProbability;
  final int processedFrames;
  final int responseCount;
  final int targetCount;
  final double? averageResponseSeconds;
  final double completionFraction;
  final bool endedEarly;
  final int parentHelpLevel;

  const CameraEngagementSnapshot({
    required this.recordedAt,
    required this.durationSeconds,
    required this.cameraEnabled,
    required this.engagementScore,
    required this.faceVisibility,
    required this.lookingAtScreen,
    required this.eyesOpen,
    required this.smileProbability,
    required this.processedFrames,
    required this.responseCount,
    required this.targetCount,
    required this.averageResponseSeconds,
    required this.completionFraction,
    required this.endedEarly,
    required this.parentHelpLevel,
  });

  Map<String, dynamic> toJson() => {
        'modelVersion': modelVersion,
        'recordedAt': recordedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'cameraEnabled': cameraEnabled,
        'engagementScore': engagementScore,
        'faceVisibility': faceVisibility,
        'lookingAtScreen': lookingAtScreen,
        'eyesOpen': eyesOpen,
        'smileProbability': smileProbability,
        'processedFrames': processedFrames,
        'responseCount': responseCount,
        'targetCount': targetCount,
        'averageResponseSeconds': averageResponseSeconds,
        'completionFraction': completionFraction,
        'endedEarly': endedEarly,
        'parentHelpLevel': parentHelpLevel,
      };

  factory CameraEngagementSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['modelVersion'] != modelVersion) {
      throw const FormatException(
        'Stored camera engagement model version is unsupported.',
      );
    }
    final recordedAt = DateTime.tryParse(json['recordedAt'] as String? ?? '');
    if (recordedAt == null) {
      throw const FormatException('Camera engagement timestamp is invalid.');
    }

    return CameraEngagementSnapshot(
      recordedAt: recordedAt,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      cameraEnabled: json['cameraEnabled'] as bool? ?? false,
      engagementScore: (json['engagementScore'] as num?)?.toDouble(),
      faceVisibility: (json['faceVisibility'] as num?)?.toDouble() ?? 0,
      lookingAtScreen: (json['lookingAtScreen'] as num?)?.toDouble(),
      eyesOpen: (json['eyesOpen'] as num?)?.toDouble(),
      smileProbability: (json['smileProbability'] as num?)?.toDouble(),
      processedFrames: (json['processedFrames'] as num?)?.toInt() ?? 0,
      responseCount: (json['responseCount'] as num?)?.toInt() ?? 0,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 0,
      averageResponseSeconds:
          (json['averageResponseSeconds'] as num?)?.toDouble(),
      completionFraction: (json['completionFraction'] as num?)?.toDouble() ?? 0,
      endedEarly: json['endedEarly'] as bool? ?? false,
      parentHelpLevel: (json['parentHelpLevel'] as num?)?.toInt() ?? 0,
    );
  }

  static double? estimateEngagement({
    required int detectedFaceFrames,
    required double? lookingAtScreen,
    required double? eyesOpen,
    required double? smileProbability,
    required double? responseRate,
    required double? responseSpeed,
    required double completionFraction,
  }) {
    if (detectedFaceFrames == 0) return null;

    var focusTotal = 0.0;
    var focusWeight = 0.0;
    if (lookingAtScreen != null) {
      focusTotal += lookingAtScreen.clamp(0.0, 1.0) * 0.6;
      focusWeight += 0.6;
    }
    if (eyesOpen != null) {
      focusTotal += eyesOpen.clamp(0.0, 1.0) * 0.3;
      focusWeight += 0.3;
    }
    if (smileProbability != null) {
      focusTotal += smileProbability.clamp(0.0, 1.0) * 0.1;
      focusWeight += 0.1;
    }
    if (focusWeight == 0) return null;

    final visualFocus = focusTotal / focusWeight;
    var responseTotal = 0.0;
    var responseWeight = 0.0;
    if (responseRate != null) {
      responseTotal += responseRate.clamp(0.0, 1.0) * 0.7;
      responseWeight += 0.7;
    }
    if (responseSpeed != null) {
      responseTotal += responseSpeed.clamp(0.0, 1.0) * 0.3;
      responseWeight += 0.3;
    }
    final response = responseWeight == 0 ? 0.5 : responseTotal / responseWeight;
    final completion = completionFraction.clamp(0.0, 1.0);
    return (0.55 * visualFocus + 0.25 * response + 0.20 * completion)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static Future<void> saveLatest(CameraEngagementSnapshot snapshot) async {
    final key = await _storageKey();
    await StorageService.saveString(key, jsonEncode(snapshot.toJson()));
  }

  static Future<CameraEngagementSnapshot?> loadLatest() async {
    final key = await _storageKey();
    final stored = await StorageService.getString(key);
    if (stored == null) return null;
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Stored camera engagement is not an object.');
    }
    return CameraEngagementSnapshot.fromJson(decoded);
  }

  static Future<String> _storageKey() async {
    final userJson = await StorageService.getString(AppConstants.userKey);
    if (userJson == null) {
      throw StateError(
          'A signed-in user is required to store engagement data.');
    }
    final user = jsonDecode(userJson);
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Stored user profile is not an object.');
    }
    final userId = user['id']?.toString() ?? user['_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw StateError('The signed-in user has no valid id.');
    }
    return '$_storageKeyPrefix${Uri.encodeComponent(userId)}';
  }
}
