part of '../../therapy_ui.dart';

class _TherapistDash extends StatelessWidget {
  const _TherapistDash();
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
            child: Text("Aseliya's Overview",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText))),
        Center(
            child: Text(theme.journeyName,
                style: const TextStyle(fontSize: 13, color: Colors.black54))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const _MCard(title: 'Severity', value: 'Moderate'),
          const _MCard(title: 'Stutter Type', value: 'Repetition'),
          // Replaced "Psych Score" (out-of-scope) with Engagement metric
          GestureDetector(
            onTap: () => nav?.go(_TherapyRoute.engagement),
            child: const _MCard(title: 'Engagement', value: '0.78'),
          ),
        ]),
        const SizedBox(height: 20),
        const Text('Recent Activities',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 10),
        const _ARow(icon: '🖼️', title: 'Picture Description', score: '8 / 10'),
        const SizedBox(height: 8),
        const _ARow(icon: '📖', title: 'Story Retelling', score: '7 / 10'),
        const SizedBox(height: 8),
        const _ARow(icon: '🎙️', title: 'Guided Conversation', score: '8 / 10'),
        const SizedBox(height: 24),
        _Btn(
            text: 'Engagement', onTap: () => nav?.go(_TherapyRoute.engagement)),
        const SizedBox(height: 10),
        _Btn(
            text: 'View Full Report',
            onTap: () => nav?.go(_TherapyRoute.progress)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _MCard extends StatelessWidget {
  final String title, value;
  const _MCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Column(children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _C.darkText)),
        ]),
      );
}

class _ARow extends StatelessWidget {
  final String icon, title, score;
  const _ARow({required this.icon, required this.title, required this.score});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _C.darkText))),
          Text(score,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: _C.blue)),
        ]),
      );
}
