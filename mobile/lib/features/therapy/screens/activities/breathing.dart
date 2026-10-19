part of '../../therapy_ui.dart';

class _Breathing extends StatefulWidget {
  const _Breathing();
  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  final Set<int> _relaxedAreas = {0, 1};
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);
  int _cyclesCompleted = 0;
  bool _isSaving = false;
  late final DateTime _startTime;
  final CameraEngagementActivityTracker _engagementTracker =
      CameraEngagementActivityTracker();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _cyclesCompleted++);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _engagementTracker.dispose();
    super.dispose();
  }

  Future<void> _completeBreathing() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;
    final successes = _relaxedAreas.isEmpty ? 1 : _relaxedAreas.length;
    final completion = (successes / 4.0).clamp(0.25, 1.0);
    final performance = _LinUcbModel.calculatePerformanceScore(
      successes: successes,
      targets: 4,
      completionFraction: completion,
    );
    final logsEngagement = _LinUcbModel.estimateLogsOnlyEngagement(
      completionFraction: completion,
      targetOpportunities: 4,
      attempts: successes,
      durationSeconds: durationSeconds,
    );
    final cameraSnapshot = await _engagementTracker.completeActivity(
      durationSeconds: durationSeconds,
      responseCount: successes,
      targetCount: 4,
      completionFraction: completion,
    );
    final engagement = cameraSnapshot?.engagementScore ?? logsEngagement;
    final engagementMode = cameraSnapshot?.engagementScore == null
        ? 'logs_only'
        : 'camera_logs';

    await TherapyApiService.recordActivityResult(
      activityId: 'breathing-body-awareness',
      targetOpportunities: 4,
      successfulOpportunities: successes,
      completionFraction: completion,
      durationSeconds: durationSeconds,
      completed: true,
      engagementMode: engagementMode,
      engagementScore: engagement,
    );

    try {
      final model = await _LinUcbModel.load();
      if (model.pendingActivityId == 'breathing-body-awareness') {
        await model.recordPendingReward(
          performance: performance,
          engagement: engagement,
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSaving = false);
    _InheritedNav.of(context)?.go(_TherapyRoute.adaptiveSyllable);
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('හුස්ම ගැනීමේ විවේකය',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const Text('Breathing and body awareness',
            style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 14),
        CameraEngagementActivityPanel(tracker: _engagementTracker),
        const SizedBox(height: 24),
        AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final scale = 0.85 + _c.value * 0.3;
              return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accentColor.withValues(alpha: 0.25),
                        border: Border.all(color: theme.accentColor, width: 3)),
                    child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                _c.value > 0.5 ? 'Breathe In' : 'Breathe Out',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.accentColor,
                                    fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              'Cycle: ${_cyclesCompleted + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.accentColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        )),
                  ));
            }),
        const SizedBox(height: 24),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ]),
            child: const Text(
                'වටය අනුගමනය කරන්න. එය විශාල වන විට හුස්ම ගන්න; කුඩා වන විට හුස්ම පිට කරන්න.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _C.darkText))),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Body check-in',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Notice each area, then tap to soften as you breathe out.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Shoulders', 'Jaw', 'Hands', 'Belly']
                    .asMap()
                    .entries
                    .map((entry) => FilterChip(
                          avatar: _relaxedAreas.contains(entry.key)
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                          label: Text(entry.value),
                          selected: _relaxedAreas.contains(entry.key),
                          selectedColor: _C.blue,
                          labelStyle: TextStyle(
                            color: _relaxedAreas.contains(entry.key) ? Colors.white : _C.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _relaxedAreas.add(entry.key);
                            } else {
                              _relaxedAreas.remove(entry.key);
                            }
                          }),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _Btn(
            text: _isSaving ? 'සුරකිමින්...' : 'මම සූදානම් (Finish Breathing)',
            onTap: _completeBreathing),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => nav?.go(_TherapyRoute.activityLibrary),
          child: const Text('ක්‍රියාකාරකම් එකතුවට ආපසු යන්න'),
        ),
        const SizedBox(height: 16),
      ]),
    ));
  }
}
