part of '../../therapy_ui.dart';

class _Breathing extends StatefulWidget {
  const _Breathing();
  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('හුස්ම ගැනීමේ විවේකය',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 30),
        AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final scale = 0.85 + _c.value * 0.3;
              return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accentColor.withValues(alpha: 0.25),
                        border: Border.all(color: theme.accentColor, width: 3)),
                    child: Center(
                        child: Text(
                            _c.value > 0.5 ? 'Breathe In' : 'Breathe Out',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.accentColor,
                                fontSize: 15))),
                  ));
            }),
        const SizedBox(height: 30),
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ]),
            child: const Text(
                'වටය අනුගමනය කරන්න. එය විශාල වන විට හුස්ම ගන්න; කුඩා වන විට හුස්ම පිට කරන්න.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _C.darkText))),
        const SizedBox(height: 24),
        _Btn(
            text: 'මම සූදානම්',
            onTap: () => nav?.go(_TherapyRoute.adaptiveSyllable)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}
