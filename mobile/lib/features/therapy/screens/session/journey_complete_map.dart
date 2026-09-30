part of '../../therapy_ui.dart';

class _JourneyCompleteMap extends StatelessWidget {
  const _JourneyCompleteMap();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    final size = MediaQuery.of(context).size;
    
    return _BgScaffold(child: Column(children: [
      _BackHeader(title: '${theme.journeyName} Complete! 🏆'),
      // Celebration banner
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.6)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🎊', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('සියලු ක්‍රියාකාරකම් සම්පූර්ණයි!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(width: 10),
          Text('🎊', style: TextStyle(fontSize: 22)),
        ]),
      ),
      Expanded(child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _PathPainter(theme))),
        Positioned.fill(child: CustomPaint(painter: _OffPathLinePainter(theme))),
        Positioned(bottom: 20, left: 30, child: Column(children: [
          const _Mascot(size: 56),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(12)),
            child: const Text('අවසන්! ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
        ])),
        Positioned(bottom: size.height * 0.15, right: 30, child: _MChip(title: 'හුස්ම ගැනීම ✓', locked: false, theme: theme, icon: Icons.air_rounded)),
        Positioned(bottom: size.height * 0.28, left: 40, child: _MChip(title: 'අක්ෂර පුහුණුව ✓', locked: false, theme: theme, icon: Icons.record_voice_over_rounded)),
        Positioned(bottom: size.height * 0.5, right: 40, child: _MChip(title: 'පින්තූර විස්තරය ✓', locked: false, theme: theme, icon: Icons.image_rounded)),
        Positioned(bottom: size.height * 0.65, left: 20, child: _MChip(title: 'මඟ පෙන්වන කතාබහ ✓', locked: false, theme: theme, icon: Icons.chat_rounded)),
        Positioned(top: 20, left: 0, right: 0, child: Align(
          alignment: Alignment.center,
          child: _TreasurePlaque(title: '${theme.name} Treasure 🏆', theme: theme),
        )),
      ])),
      // Bottom CTA
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: _Btn(text: 'සැසි සාරාංශයට යන්න', onTap: () => nav?.go(15)),
      ),
    ]));
  }
}

