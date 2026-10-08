part of '../../therapy_ui.dart';

class _Feedback extends StatelessWidget {
  const _Feedback();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Great Job!',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        const _Mascot(size: 160),
        const SizedBox(height: 16),
        const Text(
            'You did a wonderful job\ndescribing the scene with confidence!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _C.darkText, height: 1.4)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_half_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_outline_rounded, color: _C.gold, size: 32),
        ]),
        const SizedBox(height: 8),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
                color: _C.chipBg, borderRadius: BorderRadius.circular(12)),
            child: const Text('8 / 10 Fluency Score',
                style: TextStyle(fontWeight: FontWeight.bold, color: _C.blue))),
        const SizedBox(height: 24),
        _Btn(
            text: 'Continue',
            onTap: () => nav?.go(_TherapyRoute.adaptiveConversation)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 9. ADAPTIVE NEXT
