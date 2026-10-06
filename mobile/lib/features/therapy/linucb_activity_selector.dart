part of 'therapy_ui.dart';

class _LinUcbRecommendation {
  final _TherapyActivityDefinition activity;
  final List<double> context;
  final double score;

  const _LinUcbRecommendation({
    required this.activity,
    required this.context,
    required this.score,
  });
}

class _LinUcbArmState {
  final List<List<double>> a;
  final List<double> b;

  _LinUcbArmState()
      : a = List.generate(
          _LinUcbModel.contextSize,
          (row) => List.generate(
            _LinUcbModel.contextSize,
            (column) => row == column ? 1.0 : 0.0,
          ),
        ),
        b = List.filled(_LinUcbModel.contextSize, 0);

  Map<String, Object> toJson() => {'a': a, 'b': b};
}

class _LinUcbModel {
  static const int contextSize = 9;
  static const String _storageKeyPrefix = 'c3_therapy_linucb_v2_';
  static const double _exploration = 0.8;

  final String _storageKey;
  final Map<String, _LinUcbArmState> _arms = {};
  int _updates = 0;
  double _rewardTotal = 0;
  int sessionActivitiesCompleted = 0;
  double sessionRewardTotal = 0;
  int? sessionStartedAtMilliseconds;
  String? pendingActivityId;
  List<double>? _pendingContext;

  _LinUcbModel._(this._storageKey) {
    for (final activity in _therapyActivities) {
      _arms[activity.id] = _LinUcbArmState();
    }
  }

  static Future<_LinUcbModel> load() async {
    final userJson = await StorageService.getString(AppConstants.userKey);
    if (userJson == null) {
      throw StateError('A signed-in user is required for adaptive selection.');
    }
    final user = jsonDecode(userJson);
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Stored user profile is not an object.');
    }
    final userId = user['id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw StateError('The signed-in user has no valid id.');
    }

    final model = _LinUcbModel._(
      '$_storageKeyPrefix${Uri.encodeComponent(userId)}',
    );
    final stored = await StorageService.getString(model._storageKey);
    if (stored == null) return model;

    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic> || decoded['version'] != 2) {
      throw const FormatException(
          'Stored adaptive model has an invalid format.');
    }
    final updates = decoded['updates'];
    final rewardTotal = decoded['rewardTotal'];
    final sessionActivities = decoded['sessionActivitiesCompleted'];
    final sessionRewards = decoded['sessionRewardTotal'];
    final sessionStartedAt = decoded['sessionStartedAtMilliseconds'];
    final savedArms = decoded['arms'];
    if (updates is! int ||
        rewardTotal is! num ||
        sessionActivities is! int ||
        sessionRewards is! num ||
        (sessionStartedAt != null && sessionStartedAt is! int) ||
        savedArms is! Map<String, dynamic>) {
      throw const FormatException('Stored adaptive model is incomplete.');
    }
    model
      .._updates = updates
      .._rewardTotal = rewardTotal.toDouble()
      ..sessionActivitiesCompleted = sessionActivities
      ..sessionRewardTotal = sessionRewards.toDouble()
      ..sessionStartedAtMilliseconds = sessionStartedAt as int?;

    for (final entry in savedArms.entries) {
      final arm = model._arms[entry.key];
      final saved = entry.value;
      if (arm == null || saved is! Map<String, dynamic>) continue;
      final matrix = saved['a'];
      final vector = saved['b'];
      if (matrix is! List || vector is! List) {
        throw const FormatException('Stored adaptive arm is malformed.');
      }
      final parsedMatrix = matrix.map((row) {
        if (row is! List || row.length != contextSize) {
          throw const FormatException('Stored adaptive matrix is malformed.');
        }
        return row.map(_asDouble).toList();
      }).toList();
      if (parsedMatrix.length != contextSize || vector.length != contextSize) {
        throw const FormatException(
            'Stored adaptive model has an invalid size.');
      }
      final parsedVector = vector.map(_asDouble).toList();
      model._arms[entry.key] = _LinUcbArmState()
        ..a.setAll(0, parsedMatrix)
        ..b.setAll(0, parsedVector);
    }

    final pending = decoded['pending'];
    if (pending != null) {
      if (pending is! Map<String, dynamic> ||
          pending['activityId'] is! String ||
          pending['context'] is! List) {
        throw const FormatException('Stored pending activity is malformed.');
      }
      final activityId = pending['activityId'] as String;
      final context = (pending['context'] as List).map(_asDouble).toList();
      if (!model._arms.containsKey(activityId) ||
          context.length != contextSize) {
        throw const FormatException('Stored pending activity is invalid.');
      }
      model
        ..pendingActivityId = activityId
        .._pendingContext = context;
    }
    return model;
  }

  static double _asDouble(Object? value) {
    if (value is! num) {
      throw const FormatException('Stored adaptive value is not numeric.');
    }
    return value.toDouble();
  }

  _LinUcbRecommendation recommend({
    required List<_TherapyActivityDefinition> activities,
    required _AppTheme theme,
    String? excludeActivityId,
  }) {
    if (activities.isEmpty) {
      throw StateError('No therapy activities are available for selection.');
    }
    final context = _contextFor(theme);
    final excludedId =
        excludeActivityId ?? pendingActivityId ?? 'breathing-body-awareness';
    final candidates = activities.length > 1
        ? activities.where((item) => item.id != excludedId).toList()
        : activities;
    _TherapyActivityDefinition? bestActivity;
    var bestScore = double.negativeInfinity;

    for (final activity in candidates) {
      final arm = _arms[activity.id];
      if (arm == null) {
        throw StateError('No LinUCB state exists for ${activity.id}.');
      }
      final inverse = _inverse(arm.a);
      final theta = _multiply(inverse, arm.b);
      final meanReward = _dot(theta, context);
      final uncertainty = math.sqrt(
        math.max(0, _dot(context, _multiply(inverse, context))),
      );
      final score = meanReward + _exploration * uncertainty;
      if (bestActivity == null || score > bestScore) {
        bestActivity = activity;
        bestScore = score;
      }
    }

    return _LinUcbRecommendation(
      activity: bestActivity!,
      context: context,
      score: bestScore,
    );
  }

  Future<void> setPendingRecommendation(
      _LinUcbRecommendation recommendation) async {
    if (pendingActivityId != null) _applyPendingReward(0.5);
    pendingActivityId = recommendation.activity.id;
    _pendingContext = List.of(recommendation.context);
    await _save();
  }

  Future<void> recordPendingReward(double reward) async {
    if (reward < 0 || reward > 1) {
      throw RangeError.range(reward, 0, 1, 'reward');
    }
    final activityId = pendingActivityId;
    final context = _pendingContext;
    if (activityId == null || context == null) {
      throw StateError('There is no completed activity awaiting feedback.');
    }
    _applyPendingReward(reward);
    await _save();
  }

  void _applyPendingReward(double reward) {
    final activityId = pendingActivityId;
    final context = _pendingContext;
    if (activityId == null || context == null) {
      throw StateError('There is no completed activity awaiting feedback.');
    }
    final arm = _arms[activityId];
    if (arm == null) {
      throw StateError('No LinUCB state exists for $activityId.');
    }

    for (var row = 0; row < contextSize; row++) {
      arm.b[row] += reward * context[row];
      for (var column = 0; column < contextSize; column++) {
        arm.a[row][column] += context[row] * context[column];
      }
    }
    _updates++;
    _rewardTotal += reward;
    sessionActivitiesCompleted++;
    sessionRewardTotal += reward;
    pendingActivityId = null;
    _pendingContext = null;
  }

  Future<void> completePendingWithoutFeedback() async {
    if (pendingActivityId == null) return;
    _applyPendingReward(0.5);
    await _save();
  }

  Future<void> clearPendingWithoutReward() async {
    if (pendingActivityId == null) return;
    pendingActivityId = null;
    _pendingContext = null;
    await _save();
  }

  static Future<void> clearPendingForCurrentUser() async {
    final model = await load();
    model
      ..pendingActivityId = null
      .._pendingContext = null
      ..sessionActivitiesCompleted = 0
      ..sessionRewardTotal = 0
      ..sessionStartedAtMilliseconds = DateTime.now().millisecondsSinceEpoch;
    await model._save();
  }

  double get sessionScoreOutOfTen => sessionActivitiesCompleted == 0
      ? 0
      : sessionRewardTotal / sessionActivitiesCompleted * 10;

  int get sessionDurationMinutes {
    final startedAt = sessionStartedAtMilliseconds;
    if (startedAt == null) return 0;
    return math.max(
      0,
      DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(startedAt))
          .inMinutes,
    );
  }

  List<double> _contextFor(_AppTheme theme) {
    final context = List<double>.filled(contextSize, 0);
    context[0] = 1;
    context[1 + theme.index] = 1;
    context[7] = math.min(_updates / 20, 1);
    context[8] = _updates == 0 ? 0.5 : _rewardTotal / _updates;
    return context;
  }

  Future<void> _save() => StorageService.saveString(
        _storageKey,
        jsonEncode({
          'version': 2,
          'updates': _updates,
          'rewardTotal': _rewardTotal,
          'sessionActivitiesCompleted': sessionActivitiesCompleted,
          'sessionRewardTotal': sessionRewardTotal,
          'sessionStartedAtMilliseconds': sessionStartedAtMilliseconds,
          'arms': _arms.map((id, arm) => MapEntry(id, arm.toJson())),
          'pending': pendingActivityId == null
              ? null
              : {
                  'activityId': pendingActivityId,
                  'context': _pendingContext,
                },
        }),
      );

  static List<double> _multiply(
      List<List<double>> matrix, List<double> vector) {
    return List.generate(
      vector.length,
      (row) => _dot(matrix[row], vector),
    );
  }

  static double _dot(List<double> left, List<double> right) {
    var result = 0.0;
    for (var i = 0; i < left.length; i++) {
      result += left[i] * right[i];
    }
    return result;
  }

  static List<List<double>> _inverse(List<List<double>> matrix) {
    final size = matrix.length;
    final augmented = List.generate(
      size,
      (row) => [
        ...matrix[row],
        ...List.generate(size, (column) => row == column ? 1.0 : 0.0),
      ],
    );

    for (var column = 0; column < size; column++) {
      var pivotRow = column;
      for (var row = column + 1; row < size; row++) {
        if (augmented[row][column].abs() > augmented[pivotRow][column].abs()) {
          pivotRow = row;
        }
      }
      if (augmented[pivotRow][column].abs() < 1e-12) {
        throw StateError('LinUCB matrix is singular.');
      }
      final pivot = augmented[pivotRow][column];
      final pivotValues = augmented[pivotRow];
      augmented[pivotRow] = augmented[column];
      augmented[column] = pivotValues;
      for (var i = 0; i < size * 2; i++) {
        augmented[column][i] /= pivot;
      }
      for (var row = 0; row < size; row++) {
        if (row == column) continue;
        final factor = augmented[row][column];
        for (var i = 0; i < size * 2; i++) {
          augmented[row][i] -= factor * augmented[column][i];
        }
      }
    }

    return List.generate(
      size,
      (row) => augmented[row].sublist(size),
    );
  }
}
