part of '../../therapy_ui.dart';

class _AdaptiveNextState extends State<_AdaptiveNext> {
  _LinUcbModel? _model;
  _LinUcbRecommendation? _recommendation;
  _TherapyActivityDefinition? _completedActivity;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  double _currentParentHelp = 0.0;
  bool _hasCurrentParentHelp = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation([double? parentHelpLevel]) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (parentHelpLevel != null) {
        _currentParentHelp = parentHelpLevel;
        _hasCurrentParentHelp = true;
      }
    });

    try {
      final model = await _LinUcbModel.load();
      if (!mounted) return;

      int childAge = 7;
      String? c1Severity = 'mild';
      bool? c2Secondary = false;
      List<double>? contextVec;
      CameraEngagementSnapshot? cameraSnapshot;
      try {
        cameraSnapshot = await CameraEngagementSnapshot.loadLatest();
      } catch (error, stackTrace) {
        debugPrint(
          'Could not load camera engagement context: $error\n$stackTrace',
        );
      }
      final sessionStart = model.sessionStartedAtMilliseconds;
      final hasCurrentCameraSnapshot = cameraSnapshot != null &&
          sessionStart != null &&
          cameraSnapshot.recordedAt.millisecondsSinceEpoch >= sessionStart;
      final cameraOn = hasCurrentCameraSnapshot && cameraSnapshot.cameraEnabled;
      final recentEngagement = hasCurrentCameraSnapshot
          ? cameraSnapshot.engagementScore ?? 0.5
          : 0.82;
      final contextParentHelp = _hasCurrentParentHelp
          ? _currentParentHelp
          : (hasCurrentCameraSnapshot
              ? cameraSnapshot.parentHelpLevel / 3.0
              : _currentParentHelp);

      // 1. Fetch live clinical context from backend
      try {
        final serverCtx = await TherapyApiService.fetchClinicalContext(
          cameraOn: cameraOn,
          parentHelpLevel: contextParentHelp,
        );
        if (serverCtx != null && serverCtx['vector'] is List) {
          final list = (serverCtx['vector'] as List)
              .map((v) => (v as num).toDouble())
              .toList();
          if (list.length == _LinUcbModel.contextSize) {
            list[7] = cameraOn ? 1.0 : 0.0;
            list[8] = recentEngagement;
            list[11] = contextParentHelp.clamp(0.0, 1.0).toDouble();
            contextVec = list;
          }
          final meta = serverCtx['metadata'] as Map<String, dynamic>?;
          if (meta?['childAge'] is num) {
            childAge = (meta!['childAge'] as num).toInt();
          }
          if (meta?['c1Severity'] is String) {
            c1Severity = meta!['c1Severity'] as String;
          }
          if (meta?['c2SecondaryBehaviours'] is bool) {
            c2Secondary = meta!['c2SecondaryBehaviours'] as bool;
          }
        }
      } catch (e) {
        debugPrint('Clinical context network fetch fallback: $e');
      }

      // 2. Fallback to local clinical context calculation if offline
      contextVec ??= _LinUcbModel.buildContextVector(
        childAge: childAge,
        c1Severity: c1Severity,
        c2SecondaryBehaviours: c2Secondary,
        cameraOn: cameraOn,
        recentEngagementTrend: recentEngagement,
        recentPerformanceForType: 0.75,
        sessionCount: model.sessionActivitiesCompleted,
        parentHelpLevel: contextParentHelp,
      );

      final completedActivity = _activityForId(model.pendingActivityId);

      // 3. Select optimal activity via Hybrid LinUCB
      final recommendation = model.recommend(
        context: contextVec,
        childAge: childAge,
        excludeArmId: model.pendingArmId,
        excludeActivityId: completedActivity?.id,
      );

      if (!mounted) return;
      setState(() {
        _model = model;
        _completedActivity = completedActivity;
        _recommendation = recommendation;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Adaptive activity selection failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load activity recommendations: $error';
        _isLoading = false;
      });
    }
  }

  _TherapyActivityDefinition? _activityForId(String? id) {
    if (id == null) return null;
    for (final activity in _therapyActivities) {
      if (activity.id == id) return activity;
    }
    return null;
  }

  Future<void> _recordParentHelp(double helpLevel) async {
    final model = _model;
    if (model == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Record parent assistance level (0-3 scale to server)
      final normLevel = (helpLevel * 3.0).round();
      final pendingId = model.pendingActivityId ?? 'syllable-practice';
      await TherapyApiService.recordActivityResult(
        activityId: pendingId,
        parentHelpLevel: normLevel,
        completed: true,
      );

      // Re-run LinUCB recommendation with this parent assistance input
      await _loadRecommendation(helpLevel);

      if (!mounted) return;
      setState(() {
        _completedActivity = null;
        _isSaving = false;
      });
    } catch (error) {
      debugPrint('Parent help recording failed: $error');
      if (!mounted) return;
      setState(() {
        _completedActivity = null;
        _isSaving = false;
      });
    }
  }

  Future<void> _startRecommendedActivity() async {
    final model = _model;
    final recommendation = _recommendation;
    if (model == null || recommendation == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await model.setPendingRecommendation(recommendation);
      if (!mounted) return;
      _InheritedNav.of(context)?.go(recommendation.activity.route);
    } catch (error, stackTrace) {
      debugPrint(
          'Adaptive activity selection could not be saved: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Could not save this activity selection: $error';
        _isSaving = false;
      });
    }
  }

  Future<void> _finishSession() async {
    final model = _model;
    if (model != null) {
      setState(() => _isSaving = true);
      try {
        await model.clearPendingWithoutReward();
      } catch (error, stackTrace) {
        debugPrint(
            'Pending activity could not be cleared: $error\n$stackTrace');
        if (!mounted) return;
        setState(() {
          _error = 'Could not finish the activity plan: $error';
          _isSaving = false;
        });
        return;
      }
    }
    if (!mounted) return;
    _InheritedNav.of(context)?.go(_TherapyRoute.sessionComplete);
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF2E7D32);
      case 'moderate':
        return const Color(0xFFE65100);
      case 'difficult':
      default:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final completedActivity = _completedActivity;

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const Text(
              'ඔබේ ඊළඟ පුද්ගලාරෝපිත අභ්‍යාසය',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hybrid LinUCB Adaptive Therapy Recommender',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: () => _loadRecommendation())
            else ...[
              // Parent Assistance check for recently completed activity
              if (completedActivity != null) ...[
                _ParentHelpCard(
                  activityTitle: completedActivity.title,
                  enabled: !_isSaving,
                  onSelected: _recordParentHelp,
                ),
                const SizedBox(height: 16),
              ],

              // Within-session adaptation break notice (if applicable)
              if (recommendation != null && recommendation.isBreakRecommended)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF81C784), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text('🍃', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'සන්සුන් විවේකය (Breathing Break)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'අවධානය නැවත ලබා ගැනීමට සන්සුන් හුස්ම ගැනීමේ අභ්‍යාසයක් කරමු.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Recommended Activity Card
              if (recommendation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _C.woodMid, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header Row: Emoji & Difficulty Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recommendation.activity.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(
                                      recommendation.arm.difficulty)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getDifficultyColor(
                                    recommendation.arm.difficulty),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              recommendation.arm.difficultyLabelSinhala,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getDifficultyColor(
                                    recommendation.arm.difficulty),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        recommendation.arm.titleSinhala,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _C.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.arm.titleEnglish,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),

                      // Clinical Target Skill Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: _C.green),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                recommendation.arm.targetSkill,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _C.darkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Level 2 Prompt Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'අභ්‍යාස ඉඟිය (Prompt Preview):',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recommendation.level2Item.prompt,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _C.darkText,
                              ),
                            ),
                            if (recommendation.level2Item.hint.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                recommendation.level2Item.hint,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black45),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Algorithmic Confidence & Clinical Rationale
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 14, color: _C.woodMid),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Predicted Score: ${(recommendation.predictedReward * 10).toStringAsFixed(1)}/10 • UCB: ${recommendation.score.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Action Buttons
              _Btn(
                text:
                    _isSaving ? 'සූදානම් වෙමින්...' : 'අරඹමු! (Start Activity)',
                onTap: _isSaving ? () {} : _startRecommendedActivity,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _isSaving ? null : _finishSession,
                child: const Text(
                  'අද සැසිය අවසන් කරන්න (Finish Session)',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Parent Assistance Card (Input to context vector [11], not a penalty)
// ============================================================================
class _ParentHelpCard extends StatelessWidget {
  final String activityTitle;
  final bool enabled;
  final ValueChanged<double> onSelected;

  const _ParentHelpCard({
    required this.activityTitle,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            const Text(
              'දෙමාපිය සහයෝගය (Parental Assistance Level)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'පසුගිය අභ්‍යාසය සඳහා දරුවාට කොපමණ උදව් අවශ්‍ය වූවාද?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _ParentHelpChoice(
                  label: 'ස්වාධීනයි (None)',
                  emoji: '🌟',
                  helpLevel: 0.0,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
                _ParentHelpChoice(
                  label: 'සුළු උදව් (Minimal)',
                  emoji: '👍',
                  helpLevel: 0.33,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
                _ParentHelpChoice(
                  label: 'මධ්‍යස්ථ (Moderate)',
                  emoji: '🤝',
                  helpLevel: 0.67,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
                _ParentHelpChoice(
                  label: 'සම්පූර්ණ (Full)',
                  emoji: '❤️',
                  helpLevel: 1.0,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
              ],
            ),
          ],
        ),
      );
}

class _ParentHelpChoice extends StatelessWidget {
  final String label;
  final String emoji;
  final double helpLevel;
  final bool enabled;
  final ValueChanged<double> onSelected;

  const _ParentHelpChoice({
    required this.label,
    required this.emoji,
    required this.helpLevel,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Text(emoji),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: const Color(0xFFF5F5F5),
        onPressed: enabled ? () => onSelected(helpLevel) : null,
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Text(message, style: TextStyle(color: Colors.red.shade800)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
}
