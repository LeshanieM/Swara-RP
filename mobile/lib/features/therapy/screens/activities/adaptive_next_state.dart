part of '../../therapy_ui.dart';

class _AdaptiveNextState extends State<_AdaptiveNext> {
  // Demo mode: a fixed activity order (no learning; the recommender runs on the server).
  _DemoPlan? _model;
  _DemoPick? _recommendation;
  _TherapyActivityDefinition? _completedActivity;
  // Live: the activity the server chose next, and whether the planned time is used up.
  _C3Attempt? _liveNext;
  bool _timeUp = false;
  // How much a parent helped in the finished activity (0 none … 3 did most of it); a context input, not a penalty.
  int? _parentHelp;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // The feedback chips pass the tap reward; the API takes the tap itself (same 0.2 / 1 / 0.55 rewards).
  static String _feedbackFor(double reward) =>
      reward <= 0.2 ? 'too_hard' : (reward >= 1 ? 'just_right' : 'too_easy');

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
    if (_C3Session.isLive) return _loadLive();
    try {
      final model = await _DemoPlan.load();
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

  /// A finished activity first gets its feedback card; otherwise show the open or the next activity.
  Future<void> _loadLive() async {
    try {
      if (_C3Session.sessionId == null) {
        throw const ApiException(
            'no_session', "Start today's plan from the therapy home first.");
      }
      final current = _C3Session.current;
      if (_C3Session.awaitingResult && current != null) {
        setState(() {
          _completedActivity = current.definition;
          _liveNext = null;
          _isLoading = false;
        });
        return;
      }
      final next = current ?? await _C3Session.next();
      if (!mounted) return;
      setState(() {
        _completedActivity = null;
        _liveNext = next;
        _timeUp = next == null || _C3Session.advice == 'end_session';
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(error).message;
        _isLoading = false;
      });
    }
  }

  /// Posts the finished activity with the feedback tap, follows the server's advice, then asks for the next one.
  Future<void> _recordLiveFeedback(double reward) async {
    setState(() => _isSaving = true);
    try {
      await _C3Session.postResult(
          feedback: _feedbackFor(reward), parentHelp: _parentHelp);
      _parentHelp = null;
      if (!mounted) return;
      if (_C3Session.advice == 'offer_break') await _offerBreak();
      if (!mounted) return;
      if (_C3Session.advice == 'end_session') {
        setState(() {
          _completedActivity = null;
          _liveNext = null;
          _timeUp = true;
          _isSaving = false;
        });
        return;
      }
      final next = await _C3Session.next();
      if (!mounted) return;
      setState(() {
        _completedActivity = null;
        _liveNext = next;
        _timeUp = next == null;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(error).message;
        _isSaving = false;
      });
    }
  }

  Future<void> _offerBreak() async {
    final takeBreak = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('පොඩි විවේකයක් ගමුද?'),
        content: const Text(
            'Time for a short break? Stretch, have some water, then come back.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Take a break')),
        ],
      ),
    );
    if (takeBreak == true) {
      try {
        await TherapyApiService.takeBreak(_C3Session.sessionId!);
      } catch (error) {
        debugPrint('Could not log the break: $error');
      }
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
    if (_C3Session.isLive) return _recordLiveFeedback(reward);
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
    final live = _liveNext;
    if (_C3Session.isLive) {
      if (live == null || _isSaving) return;
      await _C3Session.begin();
      if (!mounted) return;
      _InheritedNav.of(context)?.go(_C3Session.routeFor(live));
      return;
    }
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
    if (_C3Session.isLive) {
      setState(() => _isSaving = true);
      try {
        // A finished activity is still saved; an open one is marked abandoned by complete.
        if (_C3Session.awaitingResult && _C3Session.current != null)
          await _C3Session.postResult();
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _error = ApiException.from(error).message;
          _isSaving = false;
        });
        return;
      }
      if (!mounted) return;
      _InheritedNav.of(context)?.go(_TherapyRoute.sessionComplete);
      return;
    }
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
    final completedActivity = _completedActivity;
    final live = _liveNext;
    final liveDefinition = live?.definition;
    // What the recommendation card shows, from the server's choice or the on-device one.
    final (String, String, String)? recommendation = live != null
        ? (
            liveDefinition?.emoji ?? '🎯',
            live.titleEn.isEmpty
                ? live.titleSi
                : '${live.titleSi}\n${live.titleEn}',
            [
              liveDefinition?.focus,
              if (live.parentLed) '👪 A parent can help with this one.'
            ].whereType<String>().join('\n'),
          )
        : _recommendation == null
            ? null
            : (
                _recommendation!.activity.emoji,
                _recommendation!.activity.title,
                _recommendation!.activity.focus
              );
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
            Text(
              _C3Session.isLive
                  ? 'Activity ${(_C3Session.activitiesDone + (completedActivity == null && !_timeUp ? 1 : 0)).clamp(1, _C3Session.maxActivities)} of ${_C3Session.maxActivities} today'
                  : 'Personalized from your practice and chosen adventure world',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                  parentHelp: _parentHelp,
                  onParentHelp: _C3Session.isLive
                      ? (v) => setState(() => _parentHelp = v)
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              if (_C3Session.isLive && _timeUp && completedActivity == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _C.woodMid, width: 3),
                  ),
                  child: const Text(
                    'අද පුහුණුව ඇති! 🎉\nThat is enough practice for today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _C.darkText),
                  ),
                )
              else if (recommendation != null &&
                  (completedActivity == null || !_C3Session.isLive))
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
                        recommendation.$1,
                        style: const TextStyle(fontSize: 44),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _C.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation.$3,
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
              if (!_C3Session.isLive || (!_timeUp && completedActivity == null))
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

  final int? parentHelp;

  /// Live sessions only: the parent-help tap (0–3), sent with the result as recommender context.
  final ValueChanged<int>? onParentHelp;

  const _FeedbackCard({
    required this.activity,
    required this.enabled,
    required this.onSelected,
    this.parentHelp,
    this.onParentHelp,
  });

  static const _helpLevels = ['None', 'A little', 'A lot', 'Did most'];

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
            if (onParentHelp != null) ...[
              const SizedBox(height: 14),
              const Text('How much did a parent help?',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _C.darkText)),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: [
                  for (var i = 0; i < _helpLevels.length; i++)
                    ChoiceChip(
                      label: Text(_helpLevels[i],
                          style: const TextStyle(fontSize: 11)),
                      selected: parentHelp == i,
                      onSelected: enabled ? (_) => onParentHelp!(i) : null,
                    ),
                ],
              ),
            ],
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
