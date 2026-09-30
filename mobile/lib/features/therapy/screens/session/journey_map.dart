part of '../../therapy_ui.dart';

class _JourneyMap extends StatelessWidget {
  const _JourneyMap();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    final size = MediaQuery.of(context).size;

    return _BgScaffold(
        child: Column(children: [
      _BackHeader(title: theme.journeyName),
      Expanded(
          child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _PathPainter(theme))),
        Positioned.fill(
            child: CustomPaint(painter: _OffPathLinePainter(theme))),

        // Start Mascot
        Positioned(
            bottom: 20,
            left: 30,
            child: GestureDetector(
                onTap: () => nav?.go(6),
                child: Column(children: [
                  const _Mascot(size: 56),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: theme.accentColor,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('ආරම්භය',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.white))),
                ]))),

        // Sequential Activities
        Positioned(
            bottom: size.height * 0.15,
            right: 30,
            child: _MChip(
                title: 'හුස්ම ගැනීම',
                locked: false,
                theme: theme,
                icon: Icons.air_rounded)),
        Positioned(
            bottom: size.height * 0.28,
            left: 40,
            child: _MChip(
                title: 'අක්ෂර පුහුණුව',
                locked: true,
                theme: theme,
                icon: Icons.record_voice_over_rounded)),
        Positioned(
            bottom: size.height * 0.5,
            right: 40,
            child: _MChip(
                title: 'පින්තූර විස්තරය',
                locked: true,
                theme: theme,
                icon: Icons.image_rounded)),
        Positioned(
            bottom: size.height * 0.65,
            left: 20,
            child: _MChip(
                title: 'මඟ පෙන්වන කතාබහ',
                locked: true,
                theme: theme,
                icon: Icons.chat_rounded)),

        // Treasure Plaque at End
        Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Align(
                alignment: Alignment.center,
                child: _TreasurePlaque(
                    title: '${theme.name} Treasure', theme: theme))),
      ])),
    ]));
  }
}

class _TreasurePlaque extends StatelessWidget {
  final String title;
  final _AppTheme theme;
  const _TreasurePlaque({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.plaqueGradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.plaqueBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFF8E7),
                shadows: [
                  Shadow(
                      color: Colors.black87,
                      blurRadius: 2,
                      offset: Offset(1, 1))
                ])),
      ]),
    );
  }
}

class _MChip extends StatelessWidget {
  final String title;
  final bool locked;
  final _AppTheme theme;
  final IconData icon;
  const _MChip(
      {required this.title,
      required this.locked,
      required this.theme,
      required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
          border: Border.all(
              color: locked ? Colors.grey.shade300 : theme.accentColor,
              width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(locked ? Icons.lock : icon,
              size: 18, color: locked ? Colors.grey : _C.gold),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: locked ? Colors.grey : _C.darkText)),
        ]),
      );
}
