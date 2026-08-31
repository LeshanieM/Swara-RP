import 'activity_model.dart';

class ActivityResultModel {
  final ActivityModel activity;
  final int score;
  final int totalAttempts;
  final int completedAttempts;

  ActivityResultModel({
    required this.activity,
    required this.score,
    required this.totalAttempts,
    required this.completedAttempts,
  });
}
