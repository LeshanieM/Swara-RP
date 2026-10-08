part of '../../therapy_ui.dart';

class _AdaptiveNextState extends State<_AdaptiveNext> {
  _LinUcbModel? _model;
  _LinUcbRecommendation? _recommendation;
  _TherapyActivityDefinition? _completedActivity;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final model = await _LinUcbModel.load();
      if (!mounted) return;
      final completedActivity = _activityForId(model.pendingActivityId);
      final recommendation = model.recommend(
        activities: _therapyActivities,
        theme: _InheritedTheme.themeOf(context),
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

  Future<void> _recordFeedback(double reward) async {
    final model = _model;
    if (model == null || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await model.recordPendingReward(reward);
      if (!mounted) return;
      final recommendation = model.recommend(
        activities: _therapyActivities,
        theme: _InheritedTheme.themeOf(context),
        excludeActivityId: _completedActivity?.id,
      );
      if (!mounted) return;
      setState(() {
        _recommendation = recommendation;
        _completedActivity = null;
        _isSaving = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Adaptive activity feedback could not be saved: '
          '$error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Could not save your feedback: $error';
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
      debugPrint('Adaptive activity selection could not be saved: '
          '$error\n$stackTrace');
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
        await model.completePendingWithoutFeedback();
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

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
    final completedActivity = _completedActivity;
    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const Text(
              'ඔබේ ඊළඟ ක්‍රියාකාරකම',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Personalized from your practice and chosen adventure world',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadRecommendation)
            else ...[
              if (completedActivity != null) ...[
                _FeedbackCard(
                  activity: completedActivity,
                  enabled: !_isSaving,
                  onSelected: _recordFeedback,
                ),
                const SizedBox(height: 16),
              ],
              if (recommendation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _C.woodMid, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        recommendation.activity.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.activity.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _C.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.activity.focus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _Btn(
                text: _isSaving ? 'Saving...' : 'අරඹමු!',
                onTap: _isSaving ? () {} : _startRecommendedActivity,
              ),
              TextButton(
                onPressed: _isSaving ? null : _finishSession,
                child: const Text(
                  'Finish today\'s session',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final _TherapyActivityDefinition activity;
  final bool enabled;
  final ValueChanged<double> onSelected;

  const _FeedbackCard({
    required this.activity,
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(
              'How did ${activity.title.toLowerCase()} feel?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                _FeedbackChoice(
                  label: 'Too hard',
                  emoji: '😟',
                  reward: 0.2,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
                _FeedbackChoice(
                  label: 'Just right',
                  emoji: '🙂',
                  reward: 1,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
                _FeedbackChoice(
                  label: 'Too easy',
                  emoji: '😊',
                  reward: 0.55,
                  enabled: enabled,
                  onSelected: onSelected,
                ),
              ],
            ),
          ],
        ),
      );
}

class _FeedbackChoice extends StatelessWidget {
  final String label;
  final String emoji;
  final double reward;
  final bool enabled;
  final ValueChanged<double> onSelected;

  const _FeedbackChoice({
    required this.label,
    required this.emoji,
    required this.reward,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Text(emoji),
        label: Text(label),
        onPressed: enabled ? () => onSelected(reward) : null,
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
        ),
        child: Column(
          children: [
            Text(message, style: TextStyle(color: Colors.red.shade800)),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
}
