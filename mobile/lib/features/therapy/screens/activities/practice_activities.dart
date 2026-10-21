part of '../../therapy_ui.dart';

class _TherapyActivityDefinition {
  final String id;
  final String title;
  final String emoji;
  final String focus;
  final String instruction;
  final List<String> prompts;

  const _TherapyActivityDefinition({
    required this.id,
    required this.title,
    required this.emoji,
    required this.focus,
    required this.instruction,
    required this.prompts,
  });

  String get route {
    switch (id) {
      case 'breathing-body-awareness':
        return _TherapyRoute.breathing;
      case 'syllable-practice':
        return _TherapyRoute.syllablePractice;
      case 'picture-description':
        return _TherapyRoute.pictureActivity;
      default:
        return '${_TherapyRoute.practiceActivity}/$id';
    }
  }
}

/// The therapy activity library: the six activity types the team chose (same ids as the server's catalog
/// `appActivityId`). The prompts here are only for browsing the library; a live session uses the server's item.
const _therapyActivities = <_TherapyActivityDefinition>[
  _TherapyActivityDefinition(
    id: 'breathing-body-awareness',
    title: 'Breathing and relaxation',
    emoji: '🌬️',
    focus: 'Notice your breath and release body tension',
    instruction: 'Follow the breathing circle, then check in with your body.',
    prompts: ['Breathe in gently, then let your shoulders soften.'],
  ),
  _TherapyActivityDefinition(
    id: 'picture-description',
    title: 'Picture description',
    emoji: '🖼️',
    focus: 'Describe what you notice using smooth short phrases',
    instruction:
        'Look carefully, choose one detail, and describe it in your own words.',
    prompts: ['What do you see happening in the picture?'],
  ),
  _TherapyActivityDefinition(
    id: 'picture-naming',
    title: 'Picture naming',
    emoji: '🐘',
    focus: 'Name the picture with a gentle start',
    instruction: 'Look at the picture and say its name slowly and gently.',
    prompts: ['පූසා', 'බෝලය'],
  ),
  _TherapyActivityDefinition(
    id: 'syllable-practice',
    title: 'Syllable practice',
    emoji: '🔤',
    focus: 'Build words one calm syllable at a time',
    instruction:
        'Join the word parts slowly, then say the whole word smoothly.',
    prompts: ['අම්-මා  (mother)', 'ම-ල  (flower)', 'ගෙ-දර  (home)'],
  ),
  _TherapyActivityDefinition(
    id: 'word-phrase-practice',
    title: 'Word and phrase practice',
    emoji: '💬',
    focus: 'Move from a single word to a short phrase',
    instruction: 'Begin gently. Pause between the word and the phrase.',
    prompts: ['ඇපල්', 'ඇපල් කන්න', 'මම ඇපල් කනවා'],
  ),
  _TherapyActivityDefinition(
    id: 'reading-aloud',
    title: 'Paragraph reading',
    emoji: '📖',
    focus: 'Read at a comfortable pace with natural pauses',
    instruction:
        'Read the passage aloud. Pause at the full stops and take your time.',
    prompts: ['අපේ ගෙදර ලොකු ගහක් තියෙනවා. ගහේ කුරුල්ලෝ ඉන්නවා.'],
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

  // In a live session the server's item replaces the built-in prompts.
  late final _C3Attempt? _attempt = _C3Session.attemptFor(widget.activity.id);
  List<String> get _prompts => _attempt?.prompts ?? widget.activity.prompts;

  void _advancePrompt() {
    if (_promptIndex == _prompts.length - 1) {
      _C3Session.finishAndContinue(context);
      return;
    }
    setState(() {
      _promptIndex++;
      _recorded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final nav = _InheritedNav.of(context);
    final attempt = _attempt;
    final prompts = _prompts;
    // Picture naming shows the picture, not the word: the child names it.
    final naming = attempt?.isPictureNaming == true;

    return _BgScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BackHeader(title: ''),
            Text(
              attempt == null ? activity.title : attempt.titleSi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                attempt?.isWordActivity == true
                    ? 'Say each word slowly and gently. ${activity.instruction}'
                    : activity.instruction,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: _C.darkText,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${naming ? 'Picture' : attempt?.isWordActivity == true ? 'Word' : attempt?.isReading == true ? 'Passage' : 'Prompt'} ${_promptIndex + 1} of ${prompts.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 110),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.blue.withValues(alpha: 0.3)),
              ),
              child: naming
                  ? Column(children: [
                      _ItemPicture(asset: attempt!.image, height: 200),
                      const SizedBox(height: 10),
                      const Text('මේ මොකක්ද? / What is this?',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _C.darkText)),
                    ])
                  : Text(
                      prompts[_promptIndex],
                      textAlign: attempt?.isReading == true
                          ? TextAlign.start
                          : TextAlign.center,
                      style: TextStyle(
                        fontSize: attempt?.isReading == true ? 18 : 20,
                        height: attempt?.isReading == true ? 1.7 : 1.35,
                        fontWeight: FontWeight.w600,
                        color: _C.darkText,
                      ),
                    ),
            ),
            if (attempt?.isReading == true && attempt!.textEn.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(attempt.textEn,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ),
            const SizedBox(height: 20),
            Center(
              child: _TherapyMicButton(
                key: ValueKey(_promptIndex),
                nextScreen: _TherapyRoute.sessionComplete,
                prompt: 'Practice this prompt',
                onRecordingStopped: () {
                  if (attempt != null) _C3Session.recorded(_promptIndex);
                  setState(() => _recorded = true);
                },
                onAudio: attempt?.isWordActivity == true
                    ? (audio) => _C3Session.checkWord(audio, _promptIndex)
                    : attempt?.needsSpeechCheck == true
                        ? _C3Session.checkSpeech
                        : null,
                onComplete: _advancePrompt,
              ),
            ),
            if (_recorded) ...[
              const SizedBox(height: 10),
              const Text(
                'Recording complete',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _Btn(
              text: _promptIndex == prompts.length - 1
                  ? 'Finish activity'
                  : 'Next prompt',
              onTap: _advancePrompt,
            ),
            if (attempt != null)
              const _SkipActivityButton()
            else
              TextButton(
                onPressed: () => nav?.go(_TherapyRoute.activityLibrary),
                child: const Text('Back to activity library'),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
