part of '../../therapy_ui.dart';

class _AdventurePlan extends StatelessWidget {
  const _AdventurePlan();
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
        const Text('ඔබේ ත්‍රාසජනක සැලැස්ම',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        Text(theme.journeyName,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 16),
        const _Plaque(text: "Today's Plan", fontSize: 16),
        const SizedBox(height: 8),
        _card(const Column(children: [
          _PRow(icon: '🏰', label: '4 Speech Activities'),
          SizedBox(height: 10),
          _PRow(icon: '⏱️', label: 'About 25-30 Minutes'),
          SizedBox(height: 10),
          _PRow(icon: '🎯', label: 'Focus: Easy Onset & Confidence'),
        ])),
        const SizedBox(height: 16),
        const _Plaque(text: "Today's Goals", fontSize: 16),
        const SizedBox(height: 8),
        _card(const Column(children: [
          _GRow(text: 'Speak Slowly & Breathe'),
          SizedBox(height: 8),
          _GRow(text: 'Gentle Voice Start'),
          SizedBox(height: 8),
          _GRow(text: 'Use Thoughtful Pauses'),
        ])),
        const SizedBox(height: 24),
        _Btn(
            text: 'ගමන අරඹන්න', onTap: () => nav?.go(_TherapyRoute.journeyMap)),
        const SizedBox(height: 20),
      ]),
    ));
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
        child: child,
      );
}

class _PRow extends StatelessWidget {
  final String icon, label;
  const _PRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _C.darkText))),
      ]);
}

class _GRow extends StatelessWidget {
  final String text;
  const _GRow({required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.check_circle_rounded, color: _C.green, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _C.darkText))),
      ]);
}

class _OffPathLinePainter extends CustomPainter {
  final _AppTheme theme;
  _OffPathLinePainter(this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    _drawDashedLine(canvas, Offset(size.width * 0.35, size.height * 0.65),
        Offset(size.width * 0.6, size.height * 0.72), paint);
    _drawDashedLine(canvas, Offset(size.width * 0.4, size.height * 0.3),
        Offset(size.width * 0.2, size.height * 0.4), paint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 8, dashSpace = 6;
    double startX = p1.dx, startY = p1.dy;
    final distance = (p2 - p1).distance;
    final dx = (p2.dx - p1.dx) / distance;
    final dy = (p2.dy - p1.dy) / distance;
    double currentDistance = 0;
    while (currentDistance < distance) {
      canvas.drawLine(Offset(startX, startY),
          Offset(startX + dx * dashWidth, startY + dy * dashWidth), paint);
      startX += dx * (dashWidth + dashSpace);
      startY += dy * (dashWidth + dashSpace);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _OffPathLinePainter o) => o.theme != theme;
}

// 5. JOURNEY MAP
