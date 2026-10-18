part of '../../therapy_ui.dart';

class _SyllablePractice extends StatefulWidget {
  const _SyllablePractice();

  @override
  State<_SyllablePractice> createState() => _SyllablePracticeState();
}

class _SyllablePracticeState extends State<_SyllablePractice> {
  static const _practiceWords = [
    {
      'word': 'අම්-මා',
      'meaning': 'අම්මා / Mother',
      'syllables': ['අම්', 'මා'],
      'hint':
          'Begin with gentle onset on "අම්", then smooth transition to "මා"',
    },
    {
      'word': 'ම-ල',
      'meaning': 'මල / Flower',
      'syllables': ['ම', 'ල'],
      'hint': 'Soft continuous voicing across "ම" and "ල"',
    },
    {
      'word': 'ගෙ-දර',
      'meaning': 'ගෙදර / Home',
      'syllables': ['ගෙ', 'දර'],
      'hint': 'Light contact on "ගෙ", relaxed vowel flow to "දර"',
    },
    {
      'word': 'පා-ට',
      'meaning': 'පාට / Colour',
      'syllables': ['පා', 'ට'],
      'hint': 'Gentle breath release before "පා", soft tap on "ට"',
    },
    {
      'word': 'පො-ත',
      'meaning': 'පොත / Book',
      'syllables': ['පො', 'ත'],
      'hint': 'Calm prolongation on "පො", gentle stop on "ත"',
    },
  ];

  int _selectedWordIndex = 0;
  final Set<int> _completedWordIndices = {};
  int _highlightedSyllable = 0;
  bool _isSaving = false;
  late final DateTime _startTime;
  final CameraEngagementActivityTracker _engagementTracker =
      CameraEngagementActivityTracker();

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

  void _onWordRecorded() {
    setState(() {
      _completedWordIndices.add(_selectedWordIndex);
      if (_selectedWordIndex < _practiceWords.length - 1) {
        _selectedWordIndex++;
        _highlightedSyllable = 0;
      }
    });
  }

  Future<void> _completeActivity() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;
    final successes =
        _completedWordIndices.isEmpty ? 1 : _completedWordIndices.length;
    final total = _practiceWords.length;
    final completion = (successes / total).clamp(0.2, 1.0);
    final performance = _LinUcbModel.calculatePerformanceScore(
      successes: successes,
      targets: total,
      completionFraction: completion,
    );
    final logsEngagement = _LinUcbModel.estimateLogsOnlyEngagement(
      completionFraction: completion,
      targetOpportunities: total,
      attempts: successes,
      durationSeconds: durationSeconds,
    );
    final cameraSnapshot = await _engagementTracker.completeActivity(
      durationSeconds: durationSeconds,
      responseCount: successes,
      targetCount: total,
      completionFraction: completion,
    );
    final engagement = cameraSnapshot?.engagementScore ?? logsEngagement;
    final engagementMode =
        cameraSnapshot?.engagementScore == null ? 'logs_only' : 'camera_logs';

    await TherapyApiService.recordActivityResult(
      activityId: 'syllable-practice',
      targetOpportunities: total,
      successfulOpportunities: successes,
      completionFraction: completion,
      durationSeconds: durationSeconds,
      completed: true,
      engagementMode: engagementMode,
      engagementScore: engagement,
    );

    try {
      final model = await _LinUcbModel.load();
      if (model.pendingActivityId == 'syllable-practice') {
        await model.recordPendingReward(
          performance: performance,
          engagement: engagement,
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
            const Text('🌟', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'අක්ෂර පුහුණුව සාර්ථකයි!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_completedWordIndices.length} of ${_practiceWords.length} words mastered',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _Btn(
              text: 'ඊළඟ ක්‍රියාකාරකමට යන්න',
              onTap: () {
                Navigator.of(ctx).pop();
                nav?.go(_TherapyRoute.adaptivePicture);
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
    final activeWord = _practiceWords[_selectedWordIndex];
    final syllables = activeWord['syllables'] as List<String>;

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const Text(
              'අක්ෂර පුහුණුව (Syllable Practice)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'වචන කැබලි එකතු කර සෙමින් කියමු',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            CameraEngagementActivityPanel(tracker: _engagementTracker),

            // Active Word Highlight Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: syllables.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final syl = entry.value;
                      final isSelected = _highlightedSyllable == idx;
                      return GestureDetector(
                        onTap: () => setState(() => _highlightedSyllable = idx),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _C.blue
                                : _C.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _C.blue, width: 2),
                          ),
                          child: Text(
                            syl,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : _C.darkText,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activeWord['meaning'] as String,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeWord['hint'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Practice Words Grid
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'පුහුණු වචන තෝරන්න (Select Word):',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _practiceWords.asMap().entries.map((e) {
                final isSelected = e.key == _selectedWordIndex;
                final isDone = _completedWordIndices.contains(e.key);
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedWordIndex = e.key;
                    _highlightedSyllable = 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _C.blue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _C.blue
                            : (isDone ? _C.green : Colors.grey.shade300),
                        width: isSelected || isDone ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDone) ...[
                          Icon(Icons.check_circle_rounded,
                              color: isSelected ? Colors.white : _C.green,
                              size: 16),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          e.value['word'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : _C.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Mic Button
            _TherapyMicButton(
              nextScreen: _TherapyRoute.adaptivePicture,
              prompt: 'මෙම වචනය සෙමින් කියන්න (Speak Word)',
              onRecordingStopped: _onWordRecorded,
              radius: 34,
            ),
            const SizedBox(height: 12),
            Text(
              '${_completedWordIndices.length} of ${_practiceWords.length} words completed',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: _C.green),
            ),
            const SizedBox(height: 18),

            _Btn(
              text: _isSaving
                  ? 'සුරකිමින්...'
                  : (_completedWordIndices.length >= _practiceWords.length
                      ? 'අවසන් කරන්න (Complete Activity)'
                      : 'ක්‍රියාකාරකම අවසන් කරන්න'),
              onTap: _completeActivity,
            ),
            const SizedBox(height: 8),
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
