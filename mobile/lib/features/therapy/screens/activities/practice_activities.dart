part of '../../therapy_ui.dart';

class _TherapyActivityDefinition {
  final String id;
  final String title;
  final String emoji;
  final String focus;
  final String instruction;
  final List<String> prompts;
  final List<String> sentenceWords;

  const _TherapyActivityDefinition({
    required this.id,
    required this.title,
    required this.emoji,
    required this.focus,
    required this.instruction,
    required this.prompts,
    this.sentenceWords = const [],
  });

  String get route {
    switch (id) {
      case 'breathing-body-awareness':
        return _TherapyRoute.breathing;
      case 'syllable-practice':
        return _TherapyRoute.syllablePractice;
      case 'picture-description':
        return _TherapyRoute.pictureIntro;
      case 'guided-conversation':
        return _TherapyRoute.guidedConversation;
      case 'word-phrase-practice':
      default:
        return '${_TherapyRoute.practiceActivity}/$id';
    }
  }
}

// Exactly 5 clinically-selected, functional therapy activities
const _therapyActivities = <_TherapyActivityDefinition>[
  _TherapyActivityDefinition(
    id: 'breathing-body-awareness',
    title: 'හුස්ම ගැනීමේ විවේකය (Breathing & Relaxation)',
    emoji: '🌬️',
    focus: 'Notice your breath and release body tension',
    instruction: 'Follow the breathing circle, then check in with your body.',
    prompts: ['Breathe in gently, then let your shoulders soften.'],
  ),
  _TherapyActivityDefinition(
    id: 'syllable-practice',
    title: 'අක්ෂර පුහුණුව (Syllable Practice)',
    emoji: '🔤',
    focus: 'Build words one calm syllable at a time',
    instruction: 'Join the word parts slowly, then say the whole word smoothly.',
    prompts: ['අම්-මා  (mother)', 'ම-ල  (flower)', 'ගෙ-දර  (home)', 'පා-ට  (colour)', 'පො-ත  (book)'],
  ),
  _TherapyActivityDefinition(
    id: 'word-phrase-practice',
    title: 'වචන සහ වාක්‍ය ඛණ්ඩ (Word & Phrase Practice)',
    emoji: '💬',
    focus: 'Move from a single word to a short phrase with gentle onset',
    instruction: 'Begin gently. Pause between the word and the phrase to maintain easy onset.',
    prompts: [
      'තනි වචනය සෙමින් කියන්න: මල (Say the word: flower)',
      'දැන් වචන දෙකක් එකතු කරන්න: ලස්සන මල (Now say: beautiful flower)',
      'සම්පූර්ණ වාක්‍යය කියන්න: වත්තේ ලස්සන මලක් තියෙනවා (Say the sentence smoothly)',
    ],
  ),
  _TherapyActivityDefinition(
    id: 'picture-description',
    title: 'පින්තූර විස්තරය (Picture Description)',
    emoji: '🖼️',
    focus: 'Describe what you notice using smooth short phrases',
    instruction: 'Look carefully at the scene, choose one detail, and describe it in your own words.',
    prompts: ['What do you see happening in the picture?'],
  ),
  _TherapyActivityDefinition(
    id: 'guided-conversation',
    title: 'මඟපෙන්වන සංවාදය (Guided Conversation)',
    emoji: '🎙️',
    focus: 'Share an idea and listen for a natural pause',
    instruction: 'Answer the question in your own words. There is no right answer.',
    prompts: ['What is something fun you did today or enjoy doing with friends?'],
  ),
];

class _PracticeActivity extends StatefulWidget {
  final _TherapyActivityDefinition activity;

  const _PracticeActivity({required this.activity});

  @override
  State<_PracticeActivity> createState() => _PracticeActivityState();
}

class _PracticeActivityState extends State<_PracticeActivity> {
  int _promptIndex = 0;
  bool _recorded = false;
  final Set<int> _recordedPrompts = {};
  late final DateTime _startTime;
  bool _isSaving = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _recordCurrentPrompt() async {
    setState(() {
      _recorded = true;
      _recordedPrompts.add(_promptIndex);
    });
  }

  Future<void> _advancePrompt() async {
    final nav = _InheritedNav.of(context);
    final prompts = widget.activity.prompts;

    if (_promptIndex < prompts.length - 1) {
      setState(() {
        _promptIndex++;
        _recorded = _recordedPrompts.contains(_promptIndex);
      });
      return;
    }

    // Finished all prompts
    await _finishAndSave();
  }

  Future<void> _finishAndSave() async {
    if (_isSaving || _isCompleted) return;
    setState(() => _isSaving = true);

    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;
    final totalPrompts = widget.activity.prompts.length;
    final successful = _recordedPrompts.length;
    final completion = totalPrompts > 0 ? successful / totalPrompts : 1.0;

    // 1. Record to backend session
    await TherapyApiService.recordActivityResult(
      activityId: widget.activity.id,
      targetOpportunities: totalPrompts,
      successfulOpportunities: successful,
      completionFraction: completion,
      durationSeconds: durationSeconds,
      completed: true,
      engagementMode: 'logs_only',
      engagementScore: 0.85,
    );

    // 2. Update local LinUCB pending reward if active
    try {
      final model = await _LinUcbModel.load();
      if (model.pendingActivityId == widget.activity.id) {
        await model.recordPendingReward(0.6 * completion + 0.4 * 0.85);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isCompleted = true;
    });

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
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'ක්‍රියාකාරකම සම්පූර්ණයි!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_recordedPrompts.length} of ${widget.activity.prompts.length} prompts practiced successfully',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _Btn(
              text: 'ඊළඟ ක්‍රියාකාරකමට යන්න',
              onTap: () {
                Navigator.of(ctx).pop();
                nav?.go(_TherapyRoute.adaptiveSyllable);
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('ක්‍රියාකාරකම් එකතුවට (Activity Library)'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                nav?.go(_TherapyRoute.sessionComplete);
              },
              child: const Text('සැසිය අවසන් කරන්න (Finish Session)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final nav = _InheritedNav.of(context);

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BackHeader(title: ''),
            Text(
              activity.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activity.focus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: _C.blue, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      activity.instruction,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: _C.darkText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prompt ${_promptIndex + 1} of ${activity.prompts.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  '${_recordedPrompts.length} Completed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _C.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _recordedPrompts.contains(_promptIndex)
                      ? _C.green
                      : _C.blue.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Text(
                activity.prompts[_promptIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: _C.darkText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _TherapyMicButton(
                nextScreen: _TherapyRoute.adaptiveSyllable,
                prompt: _recorded ? 'නැවත පටිගත කරන්න' : 'හඬ පටිගත කරන්න',
                onRecordingStopped: _recordCurrentPrompt,
                onComplete: _advancePrompt,
              ),
            ),
            if (_recorded) ...[
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: _C.green, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'හඬ පටිගත කිරීම සාර්ථකයි!',
                    style: TextStyle(
                      color: _C.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _Btn(
              text: _promptIndex == activity.prompts.length - 1
                  ? (_isSaving ? 'සුරකිමින්...' : 'ක්‍රියාකාරකම අවසන් කරන්න')
                  : 'ඊළඟ පියවරට යන්න',
              onTap: _isSaving ? () {} : _advancePrompt,
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => nav?.go(_TherapyRoute.activityLibrary),
              child: const Text('ක්‍රියාකාරකම් එකතුවට ආපසු යන්න'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
