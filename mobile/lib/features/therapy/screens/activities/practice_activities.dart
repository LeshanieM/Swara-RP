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
      default:
        return '${_TherapyRoute.practiceActivity}/$id';
    }
  }
}

const _therapyActivities = <_TherapyActivityDefinition>[
  _TherapyActivityDefinition(
    id: 'breathing-body-awareness',
    title: 'Breathing and body awareness',
    emoji: '🌬️',
    focus: 'Notice your breath and release body tension',
    instruction: 'Follow the breathing circle, then check in with your body.',
    prompts: ['Breathe in gently, then let your shoulders soften.'],
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
    prompts: [
      'Say the word: sunny',
      'Now say: sunny day',
      'Make a phrase: The sunny day feels warm.',
    ],
  ),
  _TherapyActivityDefinition(
    id: 'reading-aloud',
    title: 'Reading aloud',
    emoji: '📖',
    focus: 'Read at a comfortable pace with natural pauses',
    instruction:
        'Read each line aloud. Pause at punctuation and take your time.',
    prompts: [
      'A little bird rested beside the garden gate.',
      'In the morning, the flowers opened to the sun.',
      'The bird sang softly before flying home.',
    ],
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
    id: 'sentence-building',
    title: 'Sentence building',
    emoji: '🧩',
    focus: 'Arrange words into a clear sentence, then say it aloud',
    instruction:
        'Tap the words in order to build a sentence. Then read it aloud.',
    prompts: ['Build a sentence about the garden.'],
    sentenceWords: ['The child', 'found', 'a bright shell'],
  ),
  _TherapyActivityDefinition(
    id: 'storytelling',
    title: 'Storytelling',
    emoji: '📚',
    focus: 'Connect ideas into a beginning, middle, and ending',
    instruction:
        'Use each story cue to add one part. Any answer can make a story.',
    prompts: [
      'Beginning: A small boat appears near the shore.',
      'Middle: Who is on the boat, and what do they find?',
      'Ending: How does the adventure finish?',
    ],
  ),
  _TherapyActivityDefinition(
    id: 'guided-conversation',
    title: 'Guided conversation',
    emoji: '🎙️',
    focus: 'Share an idea and listen for a natural pause',
    instruction:
        'Answer the question in your own words. There is no right answer.',
    prompts: ['What is something you enjoy doing with a friend?'],
  ),
  _TherapyActivityDefinition(
    id: 'role-play',
    title: 'Role-play',
    emoji: '🎭',
    focus: 'Practice everyday conversations through pretend roles',
    instruction:
        'Choose a role, respond to the situation, then try the other role.',
    prompts: [
      'You are choosing a snack at a shop. Ask what is available.',
      'Switch roles. Offer a snack and ask what your visitor would like.',
    ],
  ),
  _TherapyActivityDefinition(
    id: 'show-and-tell',
    title: 'Show and tell',
    emoji: '🧸',
    focus: 'Describe a familiar object and explain why it matters to you',
    instruction:
        'Choose an object nearby or imagine one. Share one thought at a time.',
    prompts: [
      'What object did you choose, and what does it look like?',
      'How do you use it, or where did you get it?',
      'Why is this object special to you?',
    ],
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
  String? _selectedRole;
  final List<String> _sentence = [];

  void _advancePrompt() {
    final nav = _InheritedNav.of(context);
    if (_promptIndex == widget.activity.prompts.length - 1) {
      nav?.go(_TherapyRoute.sessionComplete);
      return;
    }
    setState(() {
      _promptIndex++;
      _recorded = false;
      _selectedRole = null;
      _sentence.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final nav = _InheritedNav.of(context);
    final isRolePlay = activity.id == 'role-play';
    final isSentenceBuilding = activity.id == 'sentence-building';

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
                activity.instruction,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: _C.darkText,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Prompt ${_promptIndex + 1} of ${activity.prompts.length}',
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
              child: Text(
                activity.prompts[_promptIndex],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: _C.darkText,
                ),
              ),
            ),
            if (isSentenceBuilding) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: activity.sentenceWords.map((word) {
                  final selected = _sentence.contains(word);
                  return ChoiceChip(
                    label: Text(word),
                    selected: selected,
                    onSelected: selected
                        ? null
                        : (_) => setState(() => _sentence.add(word)),
                  );
                }).toList(),
              ),
              if (_sentence.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () => setState(_sentence.clear),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Start sentence again'),
                  ),
                ),
              if (_sentence.isNotEmpty)
                Text(
                  _sentence.join(' '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText,
                  ),
                ),
            ],
            if (isRolePlay) ...[
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: ['Customer', 'Shopkeeper']
                    .map((role) => ChoiceChip(
                          label: Text('I am the $role'),
                          selected: _selectedRole == role,
                          onSelected: (_) =>
                              setState(() => _selectedRole = role),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: _TherapyMicButton(
                nextScreen: _TherapyRoute.sessionComplete,
                prompt: 'Practice this prompt',
                onRecordingStopped: () => setState(() => _recorded = true),
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
              text: _promptIndex == activity.prompts.length - 1
                  ? 'Finish activity'
                  : 'Next prompt',
              onTap: _advancePrompt,
            ),
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
