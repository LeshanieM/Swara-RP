part of '../../therapy_ui.dart';

class _SyllablePractice extends StatefulWidget {
  const _SyllablePractice();
  @override
  State<_SyllablePractice> createState() => _SyllablePracticeState();
}

class _SyllablePracticeState extends State<_SyllablePractice> {
  static const _practiceWords = [
    {'word': 'අම්-මා', 'meaning': 'අම්මා / Mother'},
    {'word': 'ම-ල', 'meaning': 'මල / Flower'},
    {'word': 'ගෙ-දර', 'meaning': 'ගෙදර / Home'},
    {'word': 'පා-ට', 'meaning': 'පාට / Colour'},
  ];

  late final _C3Attempt? _attempt = _C3Session.attemptFor('syllable-practice');
  int _active = 0;

  /// The server's target words, split into syllables by the item's prompt ("අම්-මා, ම-ල") when it lines up.
  List<Map<String, String>> get _words {
    final attempt = _attempt;
    if (attempt == null) return _practiceWords;
    final split = attempt.promptSi.split(RegExp(r'\s*,\s*'));
    final english = attempt.promptEn.split(RegExp(r'\s*,\s*'));
    return [
      for (var i = 0; i < attempt.targetWords.length; i++)
        {
          'word': split.length == attempt.targetWords.length
              ? split[i]
              : attempt.targetWords[i],
          'meaning': english.length == attempt.targetWords.length
              ? '${attempt.targetWords[i]} / ${english[i]}'
              : attempt.targetWords[i],
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    final attempt = _attempt;
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('අක්ෂර පුහුණුව',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const Text('වචන කැබලි එකතු කර සෙමින් කියමු',
            style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 20),
        const _Mascot(size: 130),
        const SizedBox(height: 20),
        const Text('අද පුහුණු වචන',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 10),
        Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: words.asMap().entries.map((e) {
              final active = e.key == _active;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? _C.blue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active ? _C.blue : Colors.grey.shade300, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.value['word']!,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : _C.darkText)),
                  const SizedBox(height: 3),
                  Text(e.value['meaning']!,
                      style: TextStyle(
                          fontSize: 10,
                          color: active ? Colors.white70 : Colors.black54)),
                ]),
              );
            }).toList()),
        const SizedBox(height: 30),
        // Live: one recording per word, checked by the server, then the next word lights up.
        _TherapyMicButton(
            key: ValueKey(_active),
            nextScreen: _TherapyRoute.adaptivePicture,
            radius: 34,
            onRecordingStopped:
                attempt == null ? null : () => _C3Session.recorded(_active),
            onAudio: attempt == null
                ? null
                : (audio) => _C3Session.checkWord(audio, _active),
            onComplete: attempt == null
                ? null
                : () => setState(
                    () => _active = (_active + 1).clamp(0, words.length - 1))),
        const SizedBox(height: 20),
        _Btn(
            text: 'ඊළඟ අභියෝගයට යන්න',
            onTap: () => _C3Session.finishAndContinue(context,
                demoRoute: _TherapyRoute.adaptivePicture)),
        if (attempt != null) const _SkipActivityButton(),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// ----------------------------------------------------------------------------
// 21. BREATHING EXERCISE — second missing arm; simple animated cue
// ----------------------------------------------------------------------------
