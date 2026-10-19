part of '../../therapy_ui.dart';

class _ActivityState extends State<_Activity> {
  final Set<int> _recordedCueIndexes = {};
  int _selectedCueIndex = 0;
  int _parentHelpLevel = 0;
  bool _isSaving = false;
  late final DateTime _startTime;
  final CameraEngagementActivityTracker _engagementTracker =
      CameraEngagementActivityTracker();
  bool get _recordingCompleted =>
      _recordedCueIndexes.contains(_selectedCueIndex);

  static const _cues = [
    {
      'title': 'සතුන් හඳුනාගන්න (Animals)',
      'prompt':
          'පින්තූරයේ ඔබට පෙනෙන සතුන් හෝ චරිත කවුද? ඔවුන්ගේ නම් සෙමින් කියන්න.',
    },
    {
      'title': 'ක්‍රියාකාරකම විස්තර කරන්න (Actions)',
      'prompt':
          'ඔවුන් කුමක් කරනවාද? එක් අයෙකු කරන දෙයක් වාක්‍යයකින් විස්තර කරන්න.',
    },
    {
      'title': 'වර්ණ සහ පරිසරය (Scenery)',
      'prompt': 'පරිසරයේ ඇති වර්ණ සහ දර්ශන මොනවාද? ඔබට ලස්සනම දේ කුමක්ද?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _engagementTracker.dispose();
    super.dispose();
  }

  Future<void> _completePictureActivity() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;
    final totalCues = _cues.length;
    final successfulCues = _recordedCueIndexes.length;
    final completion = successfulCues / totalCues;
    final performance = _LinUcbModel.calculatePerformanceScore(
      successes: successfulCues,
      targets: totalCues,
      completionFraction: completion,
    );
    final logsEngagement = _LinUcbModel.estimateLogsOnlyEngagement(
      completionFraction: completion,
      targetOpportunities: totalCues,
      attempts: successfulCues,
      durationSeconds: durationSeconds,
    );
    final cameraSnapshot = await _engagementTracker.completeActivity(
      durationSeconds: durationSeconds,
      responseCount: successfulCues,
      targetCount: totalCues,
      completionFraction: completion,
      parentHelpLevel: _parentHelpLevel,
    );
    final engagement = cameraSnapshot?.engagementScore ?? logsEngagement;
    final engagementMode =
        cameraSnapshot?.engagementScore == null ? 'logs_only' : 'camera_logs';

    await TherapyApiService.recordActivityResult(
      activityId: 'picture-description',
      targetOpportunities: totalCues,
      successfulOpportunities: successfulCues,
      completionFraction: completion,
      durationSeconds: durationSeconds,
      parentHelpLevel: _parentHelpLevel,
      completed: true,
      engagementMode: engagementMode,
      engagementScore: engagement,
    );

    try {
      final model = await _LinUcbModel.load();
      if (model.pendingActivityId == 'picture-description') {
        await model.recordPendingReward(
          performance: performance,
          engagement: engagement,
          parentHelpRating: _parentHelpLevel,
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSaving = false);

    _showCompletionModal();
  }

  void _showCompletionModal() {
    final nav = _InheritedNav.of(context);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'පින්තූර විස්තරය සම්පූර්ණයි!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your expressive description was recorded successfully',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _Btn(
              text: 'ඊළඟ ක්‍රියාකාරකමට යන්න',
              onTap: () {
                Navigator.of(ctx).pop();
                nav?.go(_TherapyRoute.adaptiveConversation);
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                nav?.go(_TherapyRoute.activityLibrary);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('ක්‍රියාකාරකම් එකතුවට (Activity Library)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final cue = _cues[_selectedCueIndex];

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const Text(
              'පින්තූර විස්තරය (Picture Description)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ඔබට පෙනෙන්නේ මොනවාද? සෙමින් විස්තර කරමු',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            CameraEngagementActivityPanel(tracker: _engagementTracker),

            // Illustrated scene
            const _SceneWidget(height: 200),
            const SizedBox(height: 16),

            // Guiding Cue Selector
            Row(
              children: _cues.asMap().entries.map((entry) {
                final isSelected = entry.key == _selectedCueIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCueIndex = entry.key),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _C.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _C.blue.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        entry.value['title']!.split(' ')[0],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : _C.darkText,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Prompt Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cue['title']!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _C.darkText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cue['prompt']!,
                    style: const TextStyle(
                        fontSize: 13, height: 1.35, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mic & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TherapyMicButton(
                  nextScreen: _TherapyRoute.adaptiveConversation,
                  prompt: _recordingCompleted
                      ? 'නැවත පටිගත කරන්න'
                      : 'විස්තරය පටිගත කරන්න',
                  onRecordingStopped: () => setState(
                    () => _recordedCueIndexes.add(_selectedCueIndex),
                  ),
                  radius: 34,
                ),
                // Parent Help Level Chip
                GestureDetector(
                  onTap: () => setState(
                      () => _parentHelpLevel = (_parentHelpLevel + 1) % 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.support_agent_rounded,
                            color: Colors.amber, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          'Help: ${[
                            'None',
                            'Low',
                            'Med',
                            'High'
                          ][_parentHelpLevel]}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_recordingCompleted) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: _C.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'ඔබේ පිළිතුර පටිගත කිරීම සම්පූර්ණයි!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _C.green,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Btn(
                text: _isSaving ? 'සුරකිමින්...' : 'ක්‍රියාකාරකම අවසන් කරන්න',
                onTap: _completePictureActivity,
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => nav?.go(_TherapyRoute.activityLibrary),
              child: const Text('ක්‍රියාකාරකම් එකතුවට ආපසු යන්න'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
