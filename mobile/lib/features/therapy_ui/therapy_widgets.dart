part of 'swara_therapy_ui.dart';

class _BgScaffold extends StatelessWidget {
  final Widget child;
  final bool paintScene;
  const _BgScaffold({required this.child, this.paintScene = true});

  @override
  Widget build(BuildContext context) {
    final theme = _InheritedTheme.themeOf(context);
    final overlayOpacity = theme == _AppTheme.space ? 0.78 : (paintScene ? 0.35 : 0.15);
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.bgTop, theme.bgMid, theme.bgBot],
      )),
      child: Stack(children: [
        if (paintScene)
          Positioned.fill(
            child: Image.asset(
              theme.bgImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  CustomPaint(painter: theme.createScenePainter()),
            ),
          ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: overlayOpacity),
          ),
        ),
        SafeArea(child: child),
      ]),
    );
  }
}

class _Mascot extends StatelessWidget {
  final double size;
  final String pose;
  const _Mascot({this.size = 140, this.pose = 'default'});

  @override
  Widget build(BuildContext context) {
    final theme = _InheritedTheme.themeOf(context);
    final imgPath = theme.mascotImage(pose);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          imgPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            painter: theme.createMascotPainter(pose),
            size: Size(size, size),
          ),
        ),
      ),
    );
  }
}

class _SceneWidget extends StatelessWidget {
  final double height;
  const _SceneWidget({this.height = 160});

  @override
  Widget build(BuildContext context) {
    final theme = _InheritedTheme.themeOf(context);
    return _ScenePreview(theme: theme, height: height);
  }
}

class _ScenePreview extends StatelessWidget {
  final _AppTheme theme;
  final double height;
  const _ScenePreview({required this.theme, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          theme.sceneImage,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            painter: theme.createScenePainter(),
            size: Size(double.infinity, height),
          ),
        ),
      ),
    );
  }
}

class _Plaque extends StatelessWidget {
  final String text;
  final double fontSize;
  const _Plaque({required this.text, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final t = _InheritedTheme.themeOf(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: t.plaqueGradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.plaqueBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFF8E7),
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 2))
            ],
          )),
    );
  }
}

class _Btn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Btn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.blue,
          foregroundColor: Colors.white,
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        onPressed: onTap,
        child: Text(text,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}

class _TherapyMicButton extends StatelessWidget {
  final int nextScreen;
  final String prompt;
  final String nextButtonText;
  final double radius;
  final VoidCallback? onComplete;
  final VoidCallback? onRecordingStopped;
  const _TherapyMicButton({
    required this.nextScreen,
    this.prompt = 'කතා කරන්න',
    this.nextButtonText = 'ඊළඟ ක්‍රියාකාරකමට යන්න',
    this.radius = 32,
    this.onComplete,
    this.onRecordingStopped,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _TherapyRecordingSheet(
              nextScreen: nextScreen,
              nextButtonText: nextButtonText,
              onComplete: onComplete,
              onRecordingStopped: onRecordingStopped),
        ),
        child: Column(children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: _C.blue,
            child: Icon(Icons.mic, color: Colors.white, size: radius),
          ),
          const SizedBox(height: 6),
          Text(prompt,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      );
}

class _TherapyRecordingSheet extends StatefulWidget {
  final int nextScreen;
  final String nextButtonText;
  final VoidCallback? onComplete;
  final VoidCallback? onRecordingStopped;
  const _TherapyRecordingSheet(
      {required this.nextScreen,
      required this.nextButtonText,
      this.onComplete,
      this.onRecordingStopped});

  @override
  State<_TherapyRecordingSheet> createState() => _TherapyRecordingSheetState();
}

class _TherapyRecordingSheetState extends State<_TherapyRecordingSheet> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    setState(() => _isRecording = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() => _isRecording = false);
    if (widget.onRecordingStopped != null) {
      Navigator.of(context).pop();
      widget.onRecordingStopped!();
    }
  }

  void _continue() {
    Navigator.of(context).pop();
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      _InheritedNav.of(context)?.go(widget.nextScreen);
    }
  }

  String get _time =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 22),
            Icon(
                _isRecording
                    ? Icons.fiber_manual_record_rounded
                    : Icons.check_circle_rounded,
                color: _isRecording ? Colors.red : _C.green,
                size: 46),
            const SizedBox(height: 10),
            Text(_isRecording ? 'පටිගත කරමින්...' : 'ඔබේ හඬ පටිගත විය',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText)),
            const SizedBox(height: 8),
            Text(_isRecording ? _time : 'කාලය: $_time',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.red : _C.blue)),
            const SizedBox(height: 22),
            if (_isRecording)
              _Btn(text: 'පටිගත කිරීම නවත්වන්න', onTap: _stopRecording)
            else ...[
              const Text('පටිගත කිරීම සම්පූර්ණයි. ඉදිරියට යාමට සූදානම්!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 16),
              _Btn(text: widget.nextButtonText, onTap: _continue),
            ],
          ]),
        ),
      );
}

class _BackHeader extends StatelessWidget {
  final String title;
  const _BackHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        GestureDetector(
          onTap: () {
            final nav = _InheritedNav.of(context);
            if (nav != null && nav.index > 0) {
              nav.go(nav.index - 1);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]),
            child: const Icon(Icons.arrow_back_rounded,
                color: _C.darkText, size: 20),
          ),
        ),
        Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText))),
        const SizedBox(width: 36),
      ]),
    );
  }
}

// ============================================================================
// SCENE PAINTERS
// ============================================================================

class _WaterfallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFE8F5E9));
    final trees = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.4), size.height * 0.35, trees);
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.3), size.height * 0.4, trees);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.4), size.height * 0.35, trees);
    final water = Paint()..color = const Color(0xFF4FC3F7);
    final stream = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.60, size.height)
      ..lineTo(size.width * 0.55, 0)
      ..close();
    canvas.drawPath(stream, water);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BeachScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.6),
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF29B6F6), Color(0xFF81D4FA)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              .createShader(
                  Rect.fromLTWH(0, 0, size.width, size.height * 0.6)));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.35),
        Paint()..color = const Color(0xFF26C6DA));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        Paint()..color = const Color(0xFFFFD54F));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(size.width * 0.06, size.height * 0.2,
                size.width * 0.05, size.height * 0.52),
            const Radius.circular(4)),
        Paint()..color = const Color(0xFF8D6E63));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.085, size.height * 0.18),
            width: size.width * 0.22,
            height: size.height * 0.14),
        Paint()..color = const Color(0xFF388E3C));
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SpaceScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF415A77)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    final star = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (final p in [
      Offset(size.width * .15, size.height * .2),
      Offset(size.width * .45, size.height * .15),
      Offset(size.width * .8, size.height * .25),
      Offset(size.width * .65, size.height * .8)
    ]) {
      canvas.drawCircle(p, 2.5, star);
    }
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.45),
        size.height * 0.22, Paint()..color = const Color(0xFFFFB74D));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.75, size.height * 0.45),
            width: size.width * 0.45,
            height: size.height * 0.12),
        Paint()
          ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _UnderwaterScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFF00ACC1),
            Color(0xFF00838F),
            Color(0xFF006064)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
        Paint()..color = const Color(0xFFFFE082));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.82),
        size.height * 0.14, Paint()..color = const Color(0xFFFF7043));
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.85),
        size.height * 0.10, Paint()..color = const Color(0xFFEC407A));
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 8, bubble);
    canvas.drawCircle(
        Offset(size.width * 0.56, size.height * 0.25), 12, bubble);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SafariScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFFF9800),
            Color(0xFFFFCC80),
            Color(0xFFFFF3E0)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(
                  Rect.fromLTWH(0, 0, size.width, size.height * 0.75)));
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35),
        size.height * 0.18, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.95),
            width: size.width * 1.4,
            height: size.height * 0.45),
        Paint()..color = const Color(0xFFF57C00));
    final trunk = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.04,
            size.height * 0.35),
        trunk);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.27, size.height * 0.45),
            width: size.width * 0.32,
            height: size.height * 0.09),
        trunk);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _CandyScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.2, size.height * 0.9),
            width: size.width * 0.8,
            height: size.height * 0.4),
        Paint()..color = const Color(0xFFF06292));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width * 0.8, size.height * 0.9),
            width: size.width * 0.9,
            height: size.height * 0.45),
        Paint()..color = const Color(0xFFBA68C8));
    canvas.drawLine(
        Offset(size.width * 0.5, size.height * 0.8),
        Offset(size.width * 0.5, size.height * 0.35),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35),
        size.height * 0.16, Paint()..color = const Color(0xFF00E676));
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ============================================================================
// MASCOT PAINTERS
// ============================================================================

class _SquirrelPainter extends CustomPainter {
  final String pose;
  _SquirrelPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final body = Paint()..color = const Color(0xFFE07A28);
    final belly = Paint()..color = const Color(0xFFFFF1D6);
    final vest = Paint()..color = const Color(0xFF1E88E5);
    final dark = Paint()..color = const Color(0xFF3E2723);
    final pink = Paint()..color = const Color(0xFFFF8A80);
    final gold = Paint()..color = const Color(0xFFFFC107);
    final tail = Path()
      ..moveTo(cx + size.width * .1, cy + size.height * .2)
      ..cubicTo(
          cx + size.width * .55,
          cy + size.height * .1,
          cx + size.width * .5,
          cy - size.height * .45,
          cx + size.width * .1,
          cy - size.height * .35)
      ..cubicTo(
          cx + size.width * .25,
          cy - size.height * .1,
          cx + size.width * .3,
          cy + size.height * .1,
          cx + size.width * .1,
          cy + size.height * .2);
    canvas.drawPath(tail, body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - size.width * .22, cy - size.height * .32),
            width: size.width * .18,
            height: size.height * .26),
        body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - size.width * .22, cy - size.height * .32),
            width: size.width * .09,
            height: size.height * .15),
        pink);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + size.width * .22, cy - size.height * .32),
            width: size.width * .18,
            height: size.height * .26),
        body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + size.width * .22, cy - size.height * .32),
            width: size.width * .09,
            height: size.height * .15),
        pink);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .12), size.width * .32, body);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .05), size.width * .18, belly);
    canvas.drawCircle(Offset(cx - size.width * .12, cy - size.height * .18),
        size.width * .06, dark);
    canvas.drawCircle(Offset(cx + size.width * .12, cy - size.height * .18),
        size.width * .06, dark);
    canvas.drawCircle(Offset(cx - size.width * .14, cy - size.height * .20),
        size.width * .02, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + size.width * .10, cy - size.height * .20),
        size.width * .02, Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .22),
            width: size.width * .44,
            height: size.height * .42),
        body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .22),
            width: size.width * .46,
            height: size.height * .38),
        vest);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .24),
            width: size.width * .24,
            height: size.height * .30),
        belly);
    if (pose == 'trophy') {
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(cx, cy + size.height * .08),
              width: size.width * .25,
              height: size.height * .22),
          gold);
      canvas.drawCircle(
          Offset(cx, cy + size.height * .02), size.width * .12, gold);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _TurtlePainter extends CustomPainter {
  final String pose;
  _TurtlePainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final shell = Paint()..color = const Color(0xFF2E7D32);
    final hi = Paint()..color = const Color(0xFF4CAF50);
    final skin = Paint()..color = const Color(0xFF80CBC4);
    final belly = Paint()..color = const Color(0xFFB2EBF2);
    final vest = Paint()..color = const Color(0xFF1E88E5);
    final dark = Paint()..color = const Color(0xFF1A237E);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy - size.height * .04),
            width: size.width * .56,
            height: size.height * .52),
        shell);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - size.width * .04, cy - size.height * .08),
            width: size.width * .28,
            height: size.height * .22),
        hi);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .30), size.width * .20, skin);
    canvas.drawCircle(Offset(cx - size.width * .09, cy - size.height * .32),
        size.width * .045, dark);
    canvas.drawCircle(Offset(cx + size.width * .09, cy - size.height * .32),
        size.width * .045, dark);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - size.width * .34, cy + size.height * .08),
            width: size.width * .22,
            height: size.height * .14),
        skin);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + size.width * .34, cy + size.height * .08),
            width: size.width * .22,
            height: size.height * .14),
        skin);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .18),
            width: size.width * .38,
            height: size.height * .22),
        belly);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .08),
            width: size.width * .30,
            height: size.height * .24),
        vest);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _CosmoBunnyPainter extends CustomPainter {
  final String pose;
  _CosmoBunnyPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final suit = Paint()..color = const Color(0xFFEDE7F6);
    final visor = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.7);
    final ear = Paint()..color = const Color(0xFFD1C4E9);
    final acc = Paint()..color = const Color(0xFF7E57C2);
    final dark = Paint()..color = const Color(0xFF311B92);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - size.width * .18, cy - size.height * .38),
            width: size.width * .14,
            height: size.height * .36),
        ear);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + size.width * .18, cy - size.height * .38),
            width: size.width * .14,
            height: size.height * .36),
        ear);
    canvas.drawCircle(Offset(cx - size.width * .18, cy - size.height * .48),
        size.width * .05, acc);
    canvas.drawCircle(Offset(cx + size.width * .18, cy - size.height * .48),
        size.width * .05, acc);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .24),
            width: size.width * .48,
            height: size.height * .42),
        suit);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .10), size.width * .32, suit);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy - size.height * .10),
            width: size.width * .48,
            height: size.height * .38),
        visor);
    canvas.drawCircle(Offset(cx - size.width * .09, cy - size.height * .12),
        size.width * .04, dark);
    canvas.drawCircle(Offset(cx + size.width * .09, cy - size.height * .12),
        size.width * .04, dark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DolphinPainter extends CustomPainter {
  final String pose;
  _DolphinPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dp = Paint()..color = const Color(0xFF29B6F6);
    final bp = Paint()..color = const Color(0xFFE1F5FE);
    final dk = Paint()..color = const Color(0xFF01579B);
    final path = Path()
      ..moveTo(cx - size.width * .36, cy + size.height * .05)
      ..quadraticBezierTo(cx - size.width * .25, cy - size.height * .35,
          cx + size.width * .15, cy - size.height * .25)
      ..quadraticBezierTo(cx + size.width * .45, cy - size.height * .15,
          cx + size.width * .35, cy + size.height * .15)
      ..quadraticBezierTo(cx + size.width * .05, cy + size.height * .35,
          cx - size.width * .36, cy + size.height * .05);
    canvas.drawPath(path, dp);
    canvas.drawCircle(Offset(cx + size.width * .18, cy - size.height * .02),
        size.width * .14, bp);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .15),
        size.width * .04, dk);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _LionCubPainter extends CustomPainter {
  final String pose;
  _LionCubPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final mane = Paint()..color = const Color(0xFFE65100);
    final fur = Paint()..color = const Color(0xFFFFB74D);
    final muz = Paint()..color = const Color(0xFFFFF3E0);
    final dark = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx + size.width * .28, cy - size.height * .05),
        size.width * .18, mane);
    canvas.drawCircle(Offset(cx - size.width * .28, cy - size.height * .05),
        size.width * .18, mane);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .18), size.width * .18, mane);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .10), size.width * .28, fur);
    canvas.drawCircle(Offset(cx - size.width * .22, cy - size.height * .30),
        size.width * .10, fur);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .30),
        size.width * .10, fur);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .04), size.width * .14, muz);
    canvas.drawCircle(Offset(cx - size.width * .10, cy - size.height * .15),
        size.width * .045, dark);
    canvas.drawCircle(Offset(cx + size.width * .10, cy - size.height * .15),
        size.width * .045, dark);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .24),
            width: size.width * .44,
            height: size.height * .38),
        fur);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SugarBearPainter extends CustomPainter {
  final String pose;
  _SugarBearPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pink = Paint()..color = const Color(0xFFF48FB1);
    final white = Paint()..color = const Color(0xFFFCE4EC);
    final dark = Paint()..color = const Color(0xFF880E4F);
    final candy = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(Offset(cx - size.width * .22, cy - size.height * .30),
        size.width * .12, pink);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .30),
        size.width * .12, pink);
    canvas.drawCircle(Offset(cx - size.width * .22, cy - size.height * .30),
        size.width * .06, white);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .30),
        size.width * .06, white);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .10), size.width * .30, pink);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + size.height * .24),
            width: size.width * .46,
            height: size.height * .40),
        pink);
    canvas.drawCircle(
        Offset(cx, cy + size.height * .22), size.width * .18, white);
    canvas.drawCircle(
        Offset(cx, cy - size.height * .04), size.width * .14, white);
    canvas.drawCircle(Offset(cx - size.width * .10, cy - size.height * .14),
        size.width * .04, dark);
    canvas.drawCircle(Offset(cx + size.width * .10, cy - size.height * .14),
        size.width * .04, dark);
    canvas.drawCircle(
        Offset(cx, cy + size.height * .22), size.width * .07, candy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
