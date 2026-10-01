part of '../../therapy_ui.dart';

class _Progress extends StatelessWidget {
  const _Progress();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(
            child: Text('ඔබේ සාරාංශය',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText))),
        const SizedBox(height: 3),
        const Center(
            child: Text('ඔබ සම්පූර්ණ කළ ක්‍රියාකාරකම්',
                style: TextStyle(fontSize: 13, color: Colors.black54))),
        Center(
            child: Text(theme.journeyName,
                style: const TextStyle(fontSize: 13, color: Colors.black54))),
        const SizedBox(height: 16),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('සම්පූර්ණ කළ ක්‍රියාකාරකම්',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('4 / 4',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _C.blue)),
                  ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.blue.shade50,
                  color: theme.accentColor,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5)),
            ])),
        const SizedBox(height: 20),
        const Text('ඔබේ ජයග්‍රහණ',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ABadge(emoji: '🥇', label: 'පළමු පියවර'),
          _ABadge(emoji: '🗣️', label: 'දක්ෂ කථිකයා'),
          _ABadge(emoji: '🌟', label: 'ගවේෂකයා'),
        ]),
        const SizedBox(height: 24),
        _Btn(
            text: 'ගමන් සිතියම බලන්න',
            onTap: () => nav?.go(_TherapyRoute.journeyMap)),
        const SizedBox(height: 12),
        _Btn(
            text: 'මුල් පිටුවට යන්න', onTap: () => nav?.go(_TherapyRoute.home)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _ABadge extends StatelessWidget {
  final String emoji, label;
  const _ABadge({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: _C.chipBg,
            child: Text(emoji, style: const TextStyle(fontSize: 26))),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: _C.darkText)),
      ]);
}

// 14. CHARACTER
