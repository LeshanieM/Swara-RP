import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // API
  static String get _host => (kIsWeb || !Platform.isAndroid) ? 'localhost' : '10.0.2.2';
  static String get baseUrl => 'http://$_host:5000';
  static String get aiServiceUrl => 'http://$_host:8000';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String demoModeKey = 'demo_mode';

  // App
  static const String appName = 'Swara';
  static const String appVersion = '1.0.0';
  static const String researchDisclaimer =
      'This is a research prototype. Results are intended to support research and therapist decision-making. '
      'This application does not replace a qualified Speech and Language Therapist or mental-health professional.';

  // Roles
  static const String roleParent = 'parent';
  static const String roleTherapist = 'therapist';
  static const String roleChild = 'child';

  // Severity Levels
  static const List<String> severityLevels = ['Mild', 'Moderate', 'Severe'];

  // Stutter Types
  static const List<String> stutterTypes = ['Repetition', 'Prolongation', 'Block', 'Mixed'];

  // Support Score Levels
  static const String supportLow = 'Low';
  static const String supportMedium = 'Medium';
  static const String supportHigh = 'High';

  // Audio
  static const int maxRecordingSeconds = 120;
  static const int maxFileSizeMb = 50;
}
