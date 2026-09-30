part of '../../therapy_ui.dart';

class _TherapistKB extends StatelessWidget {
  const _TherapistKB();

  static const _rules = [
    {'rule': 'No DAF-lite two sessions in a row', 'status': 'Active — fired today'},
    {'rule': 'Prioritize breathing when concomitants trend up', 'status': 'Active'},
    {'rule': 'Cap syllable drills at 8 minutes for age < 7', 'status': 'Active'},
  ];

  @override
  Widget build(BuildContext context) {
    return _BgScaffold(paintScene: false, child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(child: Text('Therapist Knowledge Base', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _C.darkText))),
        const SizedBox(height: 4),
        const Center(child: Text('SLP-authored guardrails constrain the bandit', style: TextStyle(fontSize: 12, color: Colors.black54))),
        const SizedBox(height: 18),
        ..._rules.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
          child: Row(children: [
            const Icon(Icons.shield_outlined, color: _C.blue, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['rule']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText)),
              const SizedBox(height: 2),
              Text(r['status']!, style: TextStyle(fontSize: 11, color: r['status']!.contains('fired') ? _C.green : Colors.black54)),
            ])),
          ]),
        )),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(14)),
          child: const Text('Guardrails always override the bandit\'s raw preference — the policy proposes, the knowledge base disposes.',
            style: TextStyle(fontSize: 12, color: _C.darkText, height: 1.4))),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// ============================================================================
// STORYBOOK READER — activities delivered AS pages inside a single PageView
// ============================================================================

enum _ActivityType { narration, syllable, breathing, conversation, dafLite }

extension _ActivityTypeX on _ActivityType {
  String get label {
    switch (this) {
      case _ActivityType.narration:    return 'Story reading';
      case _ActivityType.syllable:     return 'Syllable practice';
      case _ActivityType.breathing:    return 'Breathing break';
      case _ActivityType.conversation: return 'Talk about it';
      case _ActivityType.dafLite:      return 'Slow & steady reading';
    }
  }
  IconData get icon {
    switch (this) {
      case _ActivityType.narration:    return Icons.auto_stories_rounded;
      case _ActivityType.syllable:     return Icons.graphic_eq_rounded;
      case _ActivityType.breathing:    return Icons.air_rounded;
      case _ActivityType.conversation: return Icons.chat_bubble_outline_rounded;
      case _ActivityType.dafLite:      return Icons.hourglass_bottom_rounded;
    }
  }
}

/// One page of the session's story, as decided by the bandit.
class _StoryPageModel {
  final _ActivityType type;
  final String narration;
  final List<String> targetWords;
  final List<String> syllables;
  final String prompt;
  final Map<String, dynamic> banditContext;
  final List<Map<String, dynamic>> armScores;

  const _StoryPageModel({
    required this.type,
    required this.narration,
    this.targetWords = const [],
    this.syllables = const [],
    this.prompt = '',
    this.banditContext = const {},
    this.armScores = const [],
  });
}

/// Dummy session: five pages, each a different bandit-picked activity type.
final List<_StoryPageModel> _demoSession = [
  _StoryPageModel(
    type: _ActivityType.narration,
    narration: 'මිලෝ වනාන්තරය තුළින් ඇවිද ගියා. ඉදිරියෙන් පැරණි ගසක් තිබුණා.',
    targetWords: const ['ගසක්'],
    banditContext: {'severity': 'Moderate', 'age': 8, 'concomitants': 'Low', 'engagement_prev': 0.74},
    armScores: const [
      {'name': 'Story reading', 'score': 0.71, 'picked': true},
      {'name': 'Syllable practice', 'score': 0.52, 'picked': false},
      {'name': 'Breathing exercise', 'score': 0.38, 'picked': false},
      {'name': 'Conversation prompt', 'score': 0.47, 'picked': false},
      {'name': 'Slow & steady reading', 'score': 0.21, 'picked': false},
    ],
  ),
  _StoryPageModel(
    type: _ActivityType.syllable,
    narration: 'ගසේ මුදුනේ රත්තරන් කූඩුවක් තිබුණා. එය කියන්න උදව් කරන්න...',
    syllables: const ['ර', 'ර-ත්', 'රත්-ත', 'රත්-තරන්'],
    banditContext: {'severity': 'Moderate', 'age': 8, 'concomitants': 'Low', 'engagement_prev': 0.7},
    armScores: const [
      {'name': 'Story reading', 'score': 0.44, 'picked': false},
      {'name': 'Syllable practice', 'score': 0.68, 'picked': true},
      {'name': 'Breathing exercise', 'score': 0.30, 'picked': false},
      {'name': 'Conversation prompt', 'score': 0.41, 'picked': false},
      {'name': 'Slow & steady reading', 'score': 0.25, 'picked': false},
    ],
  ),
  _StoryPageModel(
    type: _ActivityType.breathing,
    narration: 'කූඩුව අරින්න කලින්, මිලෝ එක්ක සෙමින් හුස්ම ගමු.',
    banditContext: {'severity': 'Moderate', 'age': 8, 'concomitants': 'Elevated', 'engagement_prev': 0.6},
    armScores: const [
      {'name': 'Story reading', 'score': 0.40, 'picked': false},
      {'name': 'Syllable practice', 'score': 0.35, 'picked': false},
      {'name': 'Breathing exercise', 'score': 0.66, 'picked': true},
      {'name': 'Conversation prompt', 'score': 0.30, 'picked': false},
      {'name': 'Slow & steady reading', 'score': 0.18, 'picked': false},
    ],
  ),
  _StoryPageModel(
    type: _ActivityType.conversation,
    narration: 'කූඩුව ඇරී ගියා! ඇතුළේ මොකක්ද තියෙන්නේ කියලා මිලෝ හිතනවා...',
    prompt: 'ඔයාට කුමන අන්දමේ බෝනස් සොයාගන්න ලැබෙයිද කියා හිතුනාද?',
    banditContext: {'severity': 'Moderate', 'age': 8, 'concomitants': 'Low', 'engagement_prev': 0.78},
    armScores: const [
      {'name': 'Story reading', 'score': 0.50, 'picked': false},
      {'name': 'Syllable practice', 'score': 0.42, 'picked': false},
      {'name': 'Breathing exercise', 'score': 0.33, 'picked': false},
      {'name': 'Conversation prompt', 'score': 0.69, 'picked': true},
      {'name': 'Slow & steady reading', 'score': 0.20, 'picked': false},
    ],
  ),
  _StoryPageModel(
    type: _ActivityType.dafLite,
    narration: 'මිලෝ සහ ඔයා දෙන්නා එකට කතාවේ අවසාන පිටුව කියවමු, සෙමින්.',
    targetWords: const ['කතාවේ', 'අවසාන'],
    banditContext: {'severity': 'Moderate', 'age': 8, 'concomitants': 'Low', 'engagement_prev': 0.72},
    armScores: const [
      {'name': 'Story reading', 'score': 0.48, 'picked': false},
      {'name': 'Syllable practice', 'score': 0.30, 'picked': false},
      {'name': 'Breathing exercise', 'score': 0.25, 'picked': false},
      {'name': 'Conversation prompt', 'score': 0.35, 'picked': false},
      {'name': 'Slow & steady reading', 'score': 0.61, 'picked': true},
    ],
  ),
];

// THE READER — one continuous book; page content varies by bandit pick.
class _StoryReaderScreen extends StatefulWidget {
  final List<_StoryPageModel> pages;
  const _StoryReaderScreen({required this.pages});
  @override State<_StoryReaderScreen> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<_StoryReaderScreen> {
  final _controller = PageController();
  int _page = 0;

  void _next() {
    if (_page < widget.pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    } else {
      final nav = _InheritedNav.of(context);
      nav?.go(12); // -> New Challenge: Guided Conversation
    }
  }

  void _showReasoning(_StoryPageModel p) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ReasoningSheet(page: p));
  }

  @override
  Widget build(BuildContext context) {
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          const _BackHeader(title: ''),
          const Spacer(),
          Row(children: List.generate(widget.pages.length, (i) => Container(
            width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: i == _page ? theme.accentColor : Colors.grey.shade300),
          ))),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20, color: _C.blue),
            onPressed: () => _showReasoning(widget.pages[_page]),
            tooltip: 'Why this page?',
          ),
        ]),
      ),
      Expanded(child: PageView.builder(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.pages.length,
        onPageChanged: (i) => setState(() => _page = i),
        itemBuilder: (_, i) => _StoryPageView(page: widget.pages[i], onDone: _next),
      )),
    ]));
  }
}

// PAGE FRAME — constant across all activity types.
class _StoryPageView extends StatelessWidget {
  final _StoryPageModel page;
  final VoidCallback onDone;
  const _StoryPageView({required this.page, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(children: [
        const _SceneWidget(height: 170),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(page.type.icon, size: 14, color: _C.blue),
            const SizedBox(width: 6),
            Text(page.type.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _C.blue)),
          ]),
        ),
        const SizedBox(height: 14),
        _PageBody(page: page, onDone: onDone),
      ]),
    );
  }
}

// PAGE BODY — the only part that changes per activity type.
class _PageBody extends StatelessWidget {
  final _StoryPageModel page;
  final VoidCallback onDone;
  const _PageBody({required this.page, required this.onDone});

  @override
  Widget build(BuildContext context) {
    switch (page.type) {
      case _ActivityType.narration:
      case _ActivityType.dafLite:
        return _NarrationBody(page: page, onDone: onDone, slow: page.type == _ActivityType.dafLite);
      case _ActivityType.syllable:
        return _SyllableBody(page: page, onDone: onDone);
      case _ActivityType.breathing:
        return _BreathingBody(onDone: onDone);
      case _ActivityType.conversation:
        return _ConversationBody(page: page, onDone: onDone);
    }
  }
}

class _NarrationBody extends StatelessWidget {
  final _StoryPageModel page; final VoidCallback onDone; final bool slow;
  const _NarrationBody({required this.page, required this.onDone, this.slow = false});
  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var text = page.narration;
    for (final w in page.targetWords) {
      final i = text.indexOf(w);
      if (i < 0) continue;
      spans.add(TextSpan(text: text.substring(0, i)));
      spans.add(TextSpan(text: w, style: const TextStyle(color: _C.gold, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, decorationColor: _C.gold)));
      text = text.substring(i + w.length);
    }
    spans.add(TextSpan(text: text));
    return Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
        child: RichText(text: TextSpan(style: const TextStyle(fontSize: 18, height: 1.8, color: _C.darkText, fontWeight: FontWeight.w500), children: spans))),
      if (slow) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Take your time on the underlined words', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
      const SizedBox(height: 22),
      _TherapyMicButton(nextScreen: 0, prompt: 'තට්ටු කර කියවන්න', radius: 30, onComplete: onDone),
      const SizedBox(height: 18),
      _Btn(text: 'Turn the page', onTap: onDone),
      const SizedBox(height: 20),
    ]);
  }
}

class _SyllableBody extends StatelessWidget {
  final _StoryPageModel page; final VoidCallback onDone;
  const _SyllableBody({required this.page, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Text(page.narration, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: _C.darkText, height: 1.5))),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: page.syllables.asMap().entries.map((e) {
        final active = e.key == page.syllables.length - 1;
        return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: active ? _C.blue : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: active ? _C.blue : Colors.grey.shade300, width: 2)),
          child: Text(e.value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: active ? Colors.white : _C.darkText)));
      }).toList()),
      const SizedBox(height: 22),
      _TherapyMicButton(nextScreen: 0, onComplete: onDone, radius: 30),
      const SizedBox(height: 18),
      _Btn(text: 'Turn the page', onTap: onDone),
      const SizedBox(height: 20),
    ]);
  }
}

class _BreathingBody extends StatefulWidget {
  final VoidCallback onDone;
  const _BreathingBody({required this.onDone});
  @override State<_BreathingBody> createState() => _BreathingBodyState();
}
class _BreathingBodyState extends State<_BreathingBody> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final theme = _InheritedTheme.themeOf(context);
    return Column(children: [
      AnimatedBuilder(animation: _c, builder: (_, __) {
        final scale = 0.85 + _c.value * 0.3;
        return Transform.scale(scale: scale, child: Container(
          width: 150, height: 150,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.accentColor.withValues(alpha: 0.25), border: Border.all(color: theme.accentColor, width: 3)),
          child: Center(child: Text(_c.value > 0.5 ? 'Breathe In' : 'Breathe Out', style: TextStyle(fontWeight: FontWeight.bold, color: theme.accentColor, fontSize: 14)))));
      }),
      const SizedBox(height: 22),
      _Btn(text: 'Turn the page', onTap: widget.onDone),
      const SizedBox(height: 20),
    ]);
  }
}

class _ConversationBody extends StatelessWidget {
  final _StoryPageModel page; final VoidCallback onDone;
  const _ConversationBody({required this.page, required this.onDone});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Column(children: [
          Text(page.narration, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 10),
          Text(page.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.darkText)),
        ])),
      const SizedBox(height: 22),
      _TherapyMicButton(nextScreen: 0, onComplete: onDone, radius: 30),
      const SizedBox(height: 18),
      _Btn(text: 'Turn the page', onTap: onDone),
      const SizedBox(height: 20),
    ]);
  }
}

// "WHY THIS PAGE?" — inline bottom sheet, not a screen you navigate away to.
class _ReasoningSheet extends StatelessWidget {
  final _StoryPageModel page;
  const _ReasoningSheet({required this.page});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        const Text('Why this page?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: page.banditContext.entries.map((e) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)),
          child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        )).toList()),
        const SizedBox(height: 14),
        ...page.armScores.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(width: 130, child: Text(a['name'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (a['picked'] as bool) ? _C.blue : _C.darkText))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
              value: a['score'] as double, minHeight: 10, backgroundColor: const Color(0xFFF1F5F9),
              color: (a['picked'] as bool) ? _C.blue : Colors.grey.shade400))),
            const SizedBox(width: 8),
            Text((a['score'] as double).toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ]),
        )),
      ]),
    );
  }
}

// ============================================================================
// 27. JOURNEY COMPLETE MAP — all activities unlocked with treasure
// ============================================================================
