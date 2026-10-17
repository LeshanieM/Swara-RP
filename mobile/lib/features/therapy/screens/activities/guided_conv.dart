part of '../../therapy_ui.dart';

class _GuidedConv extends StatefulWidget {
  const _GuidedConv();

  @override
  State<_GuidedConv> createState() => _GuidedConvState();
}

class _GuidedConvState extends State<_GuidedConv> {
  int _questionIndex = 0;
  bool _recorded = false;
  String _difficultyFeedback = 'just_right';
  bool _isSaving = false;
  late final DateTime _startTime;

  static const _questions = [
    'What do you like most about the adventure today? (අද ගමනේ ඔබ වඩාත්ම කැමති කුමකටද?)',
    'Tell your mascot friend about your favorite game to play. (ඔබ වඩාත්ම කැමති ක්‍රීඩාව ගැන කියන්න)',
    'What was the happiest moment of your day today? (අද දවසේ සතුටුම මොහොත කුමක්ද?)',
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _completeConversation() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;

    await TherapyApiService.recordActivityResult(
      activityId: 'guided-conversation',
      targetOpportunities: 1,
      successfulOpportunities: 1,
      completionFraction: 1.0,
      durationSeconds: durationSeconds,
      parentDifficultyFeedback: _difficultyFeedback,
      completed: true,
      engagementMode: 'logs_only',
      engagementScore: 0.95,
    );

    try {
      final model = await _LinUcbModel.load();
      if (model.pendingActivityId == 'guided-conversation') {
        final reward = _difficultyFeedback == 'just_right'
            ? 1.0
            : (_difficultyFeedback == 'too_easy' ? 0.6 : 0.4);
        await model.recordPendingReward(0.6 * 1.0 + 0.4 * reward);
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSaving = false);
    _InheritedNav.of(context)?.go(_TherapyRoute.sessionComplete);
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const _BackHeader(title: ''),
            const Text(
              'මඟපෙන්වන සංවාදය (Guided Conversation)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your ${theme.adventureWord} friend ${theme.mascotName} has a question for you.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Question bubble with mascot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Text(
                      _questions[_questionIndex],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: _C.darkText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const _Mascot(size: 85),
              ],
            ),
            const SizedBox(height: 10),

            // Question cycling chip
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _questionIndex = (_questionIndex + 1) % _questions.length;
                  _recorded = false;
                }),
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('වෙනත් ප්‍රශ්නයක් අසන්න (Another Question)'),
              ),
            ),
            const SizedBox(height: 16),

            // Mic Button
            _TherapyMicButton(
              nextScreen: _TherapyRoute.sessionComplete,
              prompt: _recorded ? 'නැවත පිළිතුරු දෙන්න' : 'පිළිතුර පටිගත කරන්න',
              onRecordingStopped: () => setState(() => _recorded = true),
              radius: 36,
            ),
            if (_recorded) ...[
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: _C.green, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'සංවාද පිළිතුර පටිගත කිරීම සාර්ථකයි!',
                    style: TextStyle(color: _C.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Parent Difficulty Feedback
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'දෙමාපියන්ගේ ඇගයීම (Parent Feedback):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.darkText),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      {'key': 'too_hard', 'label': 'ඉතා අපහසුයි'},
                      {'key': 'just_right', 'label': 'හරියටම හරි'},
                      {'key': 'too_easy', 'label': 'ඉතා පහසුයි'},
                    ].map((opt) {
                      final isSelected = _difficultyFeedback == opt['key'];
                      return ChoiceChip(
                        label: Text(opt['label']!),
                        selected: isSelected,
                        selectedColor: _C.blue,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : _C.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _difficultyFeedback = opt['key']!),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _Btn(
              text: _isSaving ? 'සුරකිමින්...' : 'සැසිය අවසන් කරන්න (Finish Session)',
              onTap: _completeConversation,
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
