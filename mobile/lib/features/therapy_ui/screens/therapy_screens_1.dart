part of '../swara_therapy_ui.dart';

class _PathPainter extends CustomPainter {
  final _AppTheme theme;
  _PathPainter(this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.accentColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(60, size.height - 40)
      ..cubicTo(size.width * .9, size.height * .7, size.width * .1,
          size.height * .4, size.width * .8, size.height * .25)
      ..cubicTo(size.width * .9, size.height * .15, size.width * .3,
          size.height * .1, 110, 45);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter o) => o.theme != theme;
}

// ============================================================================
// SCREENS 1-18
// ============================================================================

// 1. WELCOME
class _S1Welcome extends StatelessWidget {
  const _S1Welcome();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
        child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(children: [
        const SizedBox(height: 10),
        const _Plaque(text: 'ආයුබෝවන් Aseliya!'),
        const SizedBox(height: 24),
        const _Mascot(size: 180),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(theme.welcomeQuote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _C.darkText,
                    height: 1.3)),
            const SizedBox(height: 16),
            _Btn(text: 'ඉදිරියට යමු!', onTap: () => nav?.go(3)),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 2. HOME
class _S2Home extends StatelessWidget {
  const _S2Home();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(
      paintScene: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _C.darkText),
                onPressed: () => context.go('/'),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Speech Therapy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _C.darkText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12)
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's Plan",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Row(children: [
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text("Today's Therapy Plan",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                      SizedBox(height: 6),
                      Text('අද දින පුහුණුව ආරම්භ කිරීමට සූදානම්ද?',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                const SizedBox(width: 8),
                const _Mascot(size: 74),
              ]),
              const SizedBox(height: 16),
              _Btn(
                  text: 'අද දින ප්‍රතිකාර සැලැස්ම අරඹන්න',
                  onTap: () => nav?.go(1)),
            ]),
          ),
          const SizedBox(height: 20),
          _item(context, '🎨', 'ත්‍රාසජනක ලෝක තෝරන්න', () => nav?.go(1)),
          const SizedBox(height: 10),
          _item(context, '🏆', 'මගේ ජයග්‍රහණ', () => nav?.go(16)),
          const SizedBox(height: 10),
          _item(context, '📋', 'ප්‍රතිකාර ඉතිහාසය', () => nav?.go(17)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('🔥', style: TextStyle(fontSize: 24)),
                      SizedBox(height: 8),
                      Text('Current Streak',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('5 Days',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('⭐', style: TextStyle(fontSize: 24)),
                      SizedBox(height: 8),
                      Text('Total Stars',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                      Text('1,250',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _C.darkText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Daily Tip',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _C.darkText)),
                    SizedBox(height: 4),
                    Text(
                        'Remember to take deep breaths and speak slowly during your exercises.',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _item(BuildContext ctx, String em, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ]),
      child: ListTile(
        leading: Text(em, style: const TextStyle(fontSize: 22)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: _C.darkText)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 16, color: _C.blue),
        onTap: onTap,
      ),
    );
  }
}

// 3. THEME SELECTION
class _S3ThemeSelection extends StatefulWidget {
  const _S3ThemeSelection();
  @override
  State<_S3ThemeSelection> createState() => _S3State();
}

class _S3State extends State<_S3ThemeSelection> {
  String _cat = 'All';
  final _cats = ['All', 'Nature', 'Ocean', 'Fantasy'];

  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final ts = _InheritedTheme.of(context);
    final cur = ts?.theme ?? _AppTheme.forest;
    final list = _AppTheme.values
        .where((t) => _cat == 'All' || t.category == _cat)
        .toList();

    return _BgScaffold(
        paintScene: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _BackHeader(title: ''),
            const _Plaque(text: 'ඔබේ ලෝකය තෝරන්න 🗺️', fontSize: 18),
            const SizedBox(height: 4),
            const Text('ඔබ කැමති කතා පුහුණු ලෝකය සහ යාළුවා තෝරන්න!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                  children: _cats.map((c) {
                final sel = _cat == c;
                return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c == 'All' ? 'All (6 Worlds)' : c,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : _C.darkText)),
                      selected: sel,
                      selectedColor: _C.blue,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: sel ? _C.blue : Colors.grey.shade300)),
                      onSelected: (v) {
                        if (v) setState(() => _cat = c);
                      },
                    ));
              }).toList()),
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _ThemeCard(
                  theme: list[i],
                  isSelected: cur == list[i],
                  onTap: () => ts?.onChanged(list[i])),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cur.accentColor, width: 2)),
              child: Column(children: [
                Row(children: [
                  const _Mascot(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${cur.emoji} ${cur.name} Selected!',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cur.accentColor)),
                        Text('Guide: ${cur.mascotName} • ${cur.speechPerk}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      ])),
                ]),
                const SizedBox(height: 12),
                _Btn(
                    text: '${cur.name} ත්‍රාසජනක ගමනට යමු',
                    onTap: () => nav?.go(2)),
              ]),
            ),
            const SizedBox(height: 20),
          ]),
        ));
  }
}

class _ThemeCard extends StatelessWidget {
  final _AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeCard(
      {required this.theme, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: isSelected ? theme.accentColor : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1.2),
            boxShadow: [
              BoxShadow(
                  color: isSelected
                      ? theme.accentColor.withValues(alpha: 0.18)
                      : Colors.black12,
                  blurRadius: isSelected ? 12 : 5,
                  offset: const Offset(0, 3))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              _ScenePreview(theme: theme, height: 125),
              Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('${theme.emoji} ${theme.name}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  )),
              if (isSelected)
                Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: theme.accentColor, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    )),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                  child: Text(theme.journeyName,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? theme.accentColor : _C.darkText))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color:
                        isSelected ? theme.accentColor : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(isSelected ? 'ACTIVE' : 'SELECT',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(theme.tagline,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _Chip(icon: '🐾', text: 'Guide: ${theme.mascotName}'),
              _Chip(icon: '✨', text: theme.speechPerk),
            ]),
          ]),
        ));
  }
}

class _Chip extends StatelessWidget {
  final String icon, text;
  const _Chip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8)),
        child: Text('$icon $text',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155))),
      );
}

// 4. ADVENTURE PLAN
class _S4AdventurePlan extends StatelessWidget {
  const _S4AdventurePlan();
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
        _Btn(text: 'ගමන අරඹන්න', onTap: () => nav?.go(5)),
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

    // Draw dashed lines to off-path activities
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
class _S5JourneyMap extends StatelessWidget {
  const _S5JourneyMap();
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

// 6. MILESTONE INTRO
