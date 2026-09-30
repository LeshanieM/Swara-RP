part of '../../therapy_ui.dart';

class _SyllablePractice extends StatelessWidget {
  const _SyllablePractice();
  static const _practiceWords = [
    {'word': 'අම්-මා', 'meaning': 'අම්මා / Mother'},
    {'word': 'ම-ල', 'meaning': 'මල / Flower'},
    {'word': 'ගෙ-දර', 'meaning': 'ගෙදර / Home'},
    {'word': 'පා-ට', 'meaning': 'පාට / Colour'},
  ];

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('අක්ෂර පුහුණුව', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const Text('වචන කැබලි එකතු කර සෙමින් කියමු', style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 20),
        const _Mascot(size: 130),
        const SizedBox(height: 20),
        const Text('අද පුහුණු වචන', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: _practiceWords.asMap().entries.map((e) {
          final active = e.key == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: active ? _C.blue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? _C.blue : Colors.grey.shade300, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(e.value['word']!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: active ? Colors.white : _C.darkText)),
              const SizedBox(height: 3),
              Text(e.value['meaning']!, style: TextStyle(fontSize: 10, color: active ? Colors.white70 : Colors.black54)),
            ]),
          );
        }).toList()),
        const SizedBox(height: 30),
        const _TherapyMicButton(nextScreen: 9, radius: 34),
        const SizedBox(height: 20),
        _Btn(text: 'ඊළඟ අභියෝගයට යන්න', onTap: () => nav?.go(9)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// ----------------------------------------------------------------------------
// 21. BREATHING EXERCISE — second missing arm; simple animated cue
// ----------------------------------------------------------------------------
