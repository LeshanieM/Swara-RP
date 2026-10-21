part of 'therapy_ui.dart';

/// The activity demo mode shows next.
class _DemoPick {
  final _TherapyActivityDefinition activity;
  const _DemoPick(this.activity);
}

/// Demo mode's activity order: a fixed walk through the activity list, with the session's tap scores
/// for the summary. It does not learn. The recommender is the server's Hybrid LinUCB (live sessions);
/// demo mode only shows the screens without a backend.
class _DemoPlan {
  static const String _storageKey = 'c3_demo_plan_v1';

  int _cursor = 0;
  int sessionActivitiesCompleted = 0;
  double sessionRewardTotal = 0;
  int? sessionStartedAtMilliseconds;
  String? pendingActivityId;

  _DemoPlan._();

  static Future<_DemoPlan> load() async {
    final plan = _DemoPlan._();
    final saved = await StorageService.getString(_storageKey);
    if (saved == null) return plan;
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      plan
        .._cursor = (json['cursor'] as num?)?.toInt() ?? 0
        ..sessionActivitiesCompleted = (json['completed'] as num?)?.toInt() ?? 0
        ..sessionRewardTotal = (json['rewardTotal'] as num?)?.toDouble() ?? 0
        ..sessionStartedAtMilliseconds = (json['startedAt'] as num?)?.toInt()
        ..pendingActivityId = json['pending'] as String?;
    } catch (_) {
      // A damaged demo record just starts over.
    }
    return plan;
  }

  /// The next activity in list order, skipping the one just done.
  _DemoPick recommend({
    required List<_TherapyActivityDefinition> activities,
    required _AppTheme theme,
    String? excludeActivityId,
  }) {
    if (activities.isEmpty) throw StateError('No therapy activities are available.');
    for (var i = 0; i < activities.length; i++) {
      final activity = activities[(_cursor + i) % activities.length];
      if (activities.length == 1 || activity.id != (excludeActivityId ?? pendingActivityId)) {
        return _DemoPick(activity);
      }
    }
    return _DemoPick(activities.first);
  }

  Future<void> setPendingRecommendation(_DemoPick pick) async {
    pendingActivityId = pick.activity.id;
    final index = _therapyActivities.indexWhere((a) => a.id == pick.activity.id);
    _cursor = index < 0 ? _cursor + 1 : index + 1;
    await _save();
  }

  /// The "How did it feel?" tap (0.2 / 1 / 0.55), kept only for the demo summary.
  Future<void> recordPendingReward(double reward) async {
    if (pendingActivityId == null) throw StateError('There is no completed activity awaiting feedback.');
    sessionActivitiesCompleted++;
    sessionRewardTotal += reward;
    pendingActivityId = null;
    await _save();
  }

  /// Finishing without a tap counts as the neutral 0.5, as before.
  Future<void> completePendingWithoutFeedback() async {
    if (pendingActivityId == null) return;
    await recordPendingReward(0.5);
  }

  Future<void> clearPendingWithoutReward() async {
    if (pendingActivityId == null) return;
    pendingActivityId = null;
    await _save();
  }

  static Future<void> clearPendingForCurrentUser() async {
    final plan = await load();
    plan
      ..pendingActivityId = null
      ..sessionActivitiesCompleted = 0
      ..sessionRewardTotal = 0
      ..sessionStartedAtMilliseconds = DateTime.now().millisecondsSinceEpoch;
    await plan._save();
  }

  double get sessionScoreOutOfTen =>
      sessionActivitiesCompleted == 0 ? 0 : sessionRewardTotal / sessionActivitiesCompleted * 10;

  int get sessionDurationMinutes {
    final startedAt = sessionStartedAtMilliseconds;
    if (startedAt == null) return 0;
    return math.max(0, DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startedAt)).inMinutes);
  }

  Future<void> _save() => StorageService.saveString(
        _storageKey,
        jsonEncode({
          'cursor': _cursor,
          'completed': sessionActivitiesCompleted,
          'rewardTotal': sessionRewardTotal,
          'startedAt': sessionStartedAtMilliseconds,
          'pending': pendingActivityId,
        }),
      );
}
