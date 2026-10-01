part of '../../therapy_ui.dart';

class _SessionComplete extends StatelessWidget {
  const _SessionComplete();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const _Plaque(text: 'ගමන සම්පූර්ණයි!', fontSize: 18),
        const SizedBox(height: 16),
        const _Mascot(size: 160, pose: 'trophy'),
        const SizedBox(height: 12),
        const Text('අද ඔබ ඉතා හොඳින් කළා!',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _StCard(label: 'Activities', value: '4 / 4', emoji: '🧩'),
          _StCard(label: 'Score', value: '8 / 10', emoji: '⭐️'),
          _StCard(label: 'Time', value: '25 min', emoji: '⏱️'),
        ]),
        const SizedBox(height: 24),
        _Btn(
            text: 'සාරාංශය බලන්න',
            onTap: () async {
              final saved = await TherapyApiService.completeActiveSession(
                resultSummary: const {
                  'activitiesCompleted': 4,
                  'activitiesTotal': 4,
                  'score': 8,
                  'scoreOutOf': 10,
                  'durationMinutes': 25,
                },
              );
              if (!context.mounted) return;
              if (!saved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Could not save this therapy result. Try again.'),
                  ),
                );
                return;
              }
              nav?.go(_TherapyRoute.progress);
            }),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _StCard extends StatelessWidget {
  final String label, value, emoji;
  const _StCard(
      {required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) => Container(
        width: 95,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _C.darkText)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      );
}

// 13. PROGRESS
