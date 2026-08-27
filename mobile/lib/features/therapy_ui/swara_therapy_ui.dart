// ============================================================================
// SWARA THERAPY UI - Standalone Forest Adventure Speech Therapy Module
// ============================================================================
// This file is entirely self-contained. It only imports flutter/material.dart.
// It does NOT modify or depend on any other part of the Swara-RP app.
//
// Entry point  : SwaraTherapyUI  (the only public symbol)
// Route to add : /c3/forest-therapy  ->  const SwaraTherapyUI()
//
// All internal classes have a leading underscore so they cannot clash with
// existing Swara classes (AppTheme, AppColors, etc.).
// ============================================================================

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// PUBLIC ENTRY POINT
// ---------------------------------------------------------------------------
/// Drop this widget into any route to launch the Adventure Therapy UI.
class SwaraTherapyUI extends StatelessWidget {
  const SwaraTherapyUI({super.key});

  @override
  Widget build(BuildContext context) => const _MainGalleryShell();
}

// ============================================================================
// THEME ENUM & CONSTANTS (6 Rich Worlds)
// ============================================================================
enum _AppTheme { forest, beach, space, underwater, safari, candyland }

extension _AppThemeX on _AppTheme {
  String get name {
    switch (this) {
      case _AppTheme.forest:      return 'Forest';
      case _AppTheme.beach:       return 'Beach';
      case _AppTheme.space:       return 'Space';
      case _AppTheme.underwater:  return 'Underwater';
      case _AppTheme.safari:      return 'Safari';
      case _AppTheme.candyland:   return 'Candy Land';
    }
  }

  String get emoji {
    switch (this) {
      case _AppTheme.forest:      return '🌲';
      case _AppTheme.beach:       return '🌊';
      case _AppTheme.space:       return '🚀';
      case _AppTheme.underwater:  return '🐠';
      case _AppTheme.safari:      return '🦁';
      case _AppTheme.candyland:   return '🍭';
    }
  }

  String get category {
    switch (this) {
      case _AppTheme.forest:
      case _AppTheme.safari:      return 'Nature';
      case _AppTheme.beach:
      case _AppTheme.underwater:  return 'Ocean';
      case _AppTheme.space:
      case _AppTheme.candyland:   return 'Fantasy';
    }
  }

  String get tagline {
    switch (this) {
      case _AppTheme.forest:      return 'Explore magical Whispering Woods';
      case _AppTheme.beach:       return 'Explore sunny Sandy Shore';
      case _AppTheme.space:       return 'Explore starry Cosmic Galaxy';
      case _AppTheme.underwater:  return 'Explore deep Coral Kingdom';
      case _AppTheme.safari:      return 'Explore golden Savanna Plains';
      case _AppTheme.candyland:   return 'Explore sweet Meadow Treats';
    }
  }

  String get speechPerk {
    switch (this) {
      case _AppTheme.forest:      return 'Calm & Easy Onset 🍃';
      case _AppTheme.beach:       return 'Smooth Rhythm & Waves 🌊';
      case _AppTheme.space:       return 'Confident & Bold Speech 🚀';
      case _AppTheme.underwater:  return 'Gentle Pausing & Flow 🫧';
      case _AppTheme.safari:      return 'Clear & Brave Projection 🦁';
      case _AppTheme.candyland:   return 'Joyful & Expressive Voice 🍬';
    }
  }

  String get journeyName {
    switch (this) {
      case _AppTheme.forest:      return 'Whispering Woods Journey';
      case _AppTheme.beach:       return 'Sunny Shore Journey';
      case _AppTheme.space:       return 'Cosmic Star Journey';
      case _AppTheme.underwater:  return 'Coral Kingdom Journey';
      case _AppTheme.safari:      return 'Golden Savanna Journey';
      case _AppTheme.candyland:   return 'Sweet Meadow Journey';
    }
  }

  String get adventureWord {
    switch (this) {
      case _AppTheme.forest:      return 'forest adventure';
      case _AppTheme.beach:       return 'beach adventure';
      case _AppTheme.space:       return 'space adventure';
      case _AppTheme.underwater:  return 'ocean adventure';
      case _AppTheme.safari:      return 'safari adventure';
      case _AppTheme.candyland:   return 'candy adventure';
    }
  }

  String get welcomeQuote {
    switch (this) {
      case _AppTheme.forest:      return 'Ready for your\nforest adventure? 🌲';
      case _AppTheme.beach:       return 'Ready for your\nbeach adventure? 🌊';
      case _AppTheme.space:       return 'Blast off to\nstar adventure! 🚀';
      case _AppTheme.underwater:  return 'Dive into\nocean adventure! 🐠';
      case _AppTheme.safari:      return 'Roar into\nsafari adventure! 🦁';
      case _AppTheme.candyland:   return 'Welcome to\nsweet adventure! 🍭';
    }
  }

  String get headerQuote {
    switch (this) {
      case _AppTheme.forest:      return "Let's continue your forest journey! 🌲";
      case _AppTheme.beach:       return "Let's continue your beach journey! 🌊🐢";
      case _AppTheme.space:       return "Let's explore cosmic speech quests! 🚀✨";
      case _AppTheme.underwater:  return "Let's discover deep coral sounds! 🐠🫧";
      case _AppTheme.safari:      return "Let's explore the golden savanna! 🦁🌾";
      case _AppTheme.candyland:   return "Let's find sweet sound treats! 🍭🍬";
    }
  }

  String get mascotName {
    switch (this) {
      case _AppTheme.forest:      return 'Milo';
      case _AppTheme.beach:       return 'Sandy';
      case _AppTheme.space:       return 'Cosmo';
      case _AppTheme.underwater:  return 'Bubbles';
      case _AppTheme.safari:      return 'Leo';
      case _AppTheme.candyland:   return 'Pip';
    }
  }

  String get mascotDescription {
    switch (this) {
      case _AppTheme.forest:
        return 'Milo the Squirrel is your forest friend. He will guide you on your adventures and help you become a confident speaker!';
      case _AppTheme.beach:
        return 'Sandy the Turtle is your beach friend. She will guide you on your adventures and help you become a confident speaker!';
      case _AppTheme.space:
        return 'Cosmo the Astro-Bunny is your cosmic friend. He helps you launch words with star confidence across the galaxy!';
      case _AppTheme.underwater:
        return 'Bubbles the Dolphin is your ocean friend. She helps your words flow gently like shimmering waves!';
      case _AppTheme.safari:
        return 'Leo the Lion Cub is your savanna friend. He helps you speak with a bold, clear, and brave voice!';
      case _AppTheme.candyland:
        return 'Pip the Sugar Bear is your sweet treat friend. He makes speech practice fun, joyful, and delightful!';
    }
  }

  String get characterScreenTitle => 'Meet $mascotName!';

  Color get accentColor {
    switch (this) {
      case _AppTheme.forest:      return const Color(0xFF4CAF50);
      case _AppTheme.beach:       return const Color(0xFF00ACC1);
      case _AppTheme.space:       return const Color(0xFF7E57C2);
      case _AppTheme.underwater:  return const Color(0xFF0288D1);
      case _AppTheme.safari:      return const Color(0xFFE65100);
      case _AppTheme.candyland:   return const Color(0xFFD81B60);
    }
  }

  List<Color> get plaqueGradient {
    switch (this) {
      case _AppTheme.beach:
        return const [Color(0xFFF5C842), Color(0xFFE8A530), Color(0xFFCC8800)];
      case _AppTheme.space:
        return const [Color(0xFF5C6BC0), Color(0xFF3949AB), Color(0xFF283593)];
      case _AppTheme.underwater:
        return const [Color(0xFF26C6DA), Color(0xFF00ACC1), Color(0xFF00838F)];
      case _AppTheme.safari:
        return const [Color(0xFFFFB74D), Color(0xFFFB8C00), Color(0xFFE65100)];
      case _AppTheme.candyland:
        return const [Color(0xFFF48FB1), Color(0xFFEC407A), Color(0xFFC2185B)];
      case _AppTheme.forest:
        return const [Color(0xFF9E6334), Color(0xFF7A4720), Color(0xFF5C3314)];
    }
  }

  Color get plaqueBorder {
    switch (this) {
      case _AppTheme.beach:       return const Color(0xFF9A6800);
      case _AppTheme.space:       return const Color(0xFF1A237E);
      case _AppTheme.underwater:  return const Color(0xFF006064);
      case _AppTheme.safari:      return const Color(0xFFBF360C);
      case _AppTheme.candyland:   return const Color(0xFF880E4F);
      case _AppTheme.forest:      return const Color(0xFF3D200B);
    }
  }

  Color get bgTop {
    switch (this) {
      case _AppTheme.beach:       return const Color(0xFFE0F7FA);
      case _AppTheme.space:       return const Color(0xFF1A237E);
      case _AppTheme.underwater:  return const Color(0xFFE0F7FA);
      case _AppTheme.safari:      return const Color(0xFFFFF3E0);
      case _AppTheme.candyland:   return const Color(0xFFFCE4EC);
      case _AppTheme.forest:      return const Color(0xFFE1F5FE);
    }
  }

  Color get bgMid {
    switch (this) {
      case _AppTheme.beach:       return const Color(0xFFFFF8E1);
      case _AppTheme.space:       return const Color(0xFF283593);
      case _AppTheme.underwater:  return const Color(0xFFB2EBF2);
      case _AppTheme.safari:      return const Color(0xFFFFE0B2);
      case _AppTheme.candyland:   return const Color(0xFFF8BBD0);
      case _AppTheme.forest:      return const Color(0xFFF1F8E9);
    }
  }

  Color get bgBot {
    switch (this) {
      case _AppTheme.beach:       return const Color(0xFFFFECB3);
      case _AppTheme.space:       return const Color(0xFF311B92);
      case _AppTheme.underwater:  return const Color(0xFF80DEEA);
      case _AppTheme.safari:      return const Color(0xFFFFCC80);
      case _AppTheme.candyland:   return const Color(0xFFF48FB1);
      case _AppTheme.forest:      return const Color(0xFFE8F5E9);
    }
  }

  String get bgImage {
    switch (this) {
      case _AppTheme.forest:      return 'assets/images/component3/magical_forest_bg.jpg';
      case _AppTheme.beach:       return 'assets/images/component3/beach_bg.jpg';
      case _AppTheme.space:       return 'assets/images/component3/space_bg.jpg';
      case _AppTheme.underwater:  return 'assets/images/component3/underwater_bg.jpg';
      case _AppTheme.safari:      return 'assets/images/component3/safari_bg.jpg';
      case _AppTheme.candyland:   return 'assets/images/component3/candyland_bg.jpg';
    }
  }

  String get sceneImage {
    switch (this) {
      case _AppTheme.forest:      return 'assets/images/component3/waterfall_scene.jpg';
      case _AppTheme.beach:       return 'assets/images/component3/beach_bg.jpg';
      case _AppTheme.space:       return 'assets/images/component3/space_scene.jpg';
      case _AppTheme.underwater:  return 'assets/images/component3/underwater_scene.jpg';
      case _AppTheme.safari:      return 'assets/images/component3/safari_scene.jpg';
      case _AppTheme.candyland:   return 'assets/images/component3/candyland_scene.jpg';
    }
  }

  String mascotImage(String pose) {
    switch (this) {
      case _AppTheme.forest:
        if (pose == 'magnifier') return 'assets/images/component3/milo_magnifier.jpg';
        if (pose == 'trophy') return 'assets/images/component3/milo_trophy.jpg';
        return 'assets/images/component3/milo_mascot.jpg';
      case _AppTheme.beach:
        if (pose == 'magnifier') return 'assets/images/component3/turtle_magnifier.jpg';
        if (pose == 'trophy') return 'assets/images/component3/turtle_trophy.jpg';
        return 'assets/images/component3/turtle_mascot.jpg';
      case _AppTheme.space:
        return 'assets/images/component3/cosmo_mascot.jpg';
      case _AppTheme.underwater:
        return 'assets/images/component3/dolphin_mascot.jpg';
      case _AppTheme.safari:
        return 'assets/images/component3/lion_mascot.jpg';
      case _AppTheme.candyland:
        return 'assets/images/component3/sugarbear_mascot.jpg';
    }
  }

  CustomPainter createScenePainter() {
    switch (this) {
      case _AppTheme.beach:       return _BeachScenePainter();
      case _AppTheme.space:       return _SpaceScenePainter();
      case _AppTheme.underwater:  return _UnderwaterScenePainter();
      case _AppTheme.safari:      return _SafariScenePainter();
      case _AppTheme.candyland:   return _CandyScenePainter();
      case _AppTheme.forest:      return _WaterfallPainter();
    }
  }

  CustomPainter createMascotPainter(String pose) {
    switch (this) {
      case _AppTheme.beach:       return _TurtlePainter(pose: pose);
      case _AppTheme.space:       return _CosmoBunnyPainter(pose: pose);
      case _AppTheme.underwater:  return _DolphinPainter(pose: pose);
      case _AppTheme.safari:      return _LionCubPainter(pose: pose);
      case _AppTheme.candyland:   return _SugarBearPainter(pose: pose);
      case _AppTheme.forest:      return _SquirrelPainter(pose: pose);
    }
  }
}

// ============================================================================
// COLORS
// ============================================================================
class _C {
  static const Color blue      = Color(0xFF0066CC);
  static const Color darkText  = Color(0xFF153B60);
  static const Color woodMid   = Color(0xFF8D5B2C);
  static const Color green     = Color(0xFF4CAF50);
  static const Color gold      = Color(0xFFFFB300);
  static const Color chipBg    = Color(0xFFE1F5FE);
}

// ============================================================================
// INHERITED STATE: THEME
// ============================================================================
class _InheritedTheme extends InheritedWidget {
  final _AppTheme theme;
  final ValueChanged<_AppTheme> onChanged;
  const _InheritedTheme({required this.theme, required this.onChanged, required super.child});

  static _InheritedTheme? of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_InheritedTheme>();
  static _AppTheme themeOf(BuildContext ctx) =>
      of(ctx)?.theme ?? _AppTheme.forest;

  @override
  bool updateShouldNotify(_InheritedTheme old) => old.theme != theme;
}

// ============================================================================
// INHERITED STATE: NAVIGATION
// ============================================================================
class _InheritedNav extends InheritedWidget {
  final int index;
  final void Function(int) go;
  const _InheritedNav({required this.index, required this.go, required super.child});

  static _InheritedNav? of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_InheritedNav>();

  @override
  bool updateShouldNotify(_InheritedNav old) => old.index != index;
}

// ============================================================================
// GALLERY SHELL
// ============================================================================
class _MainGalleryShell extends StatefulWidget {
  const _MainGalleryShell();
  @override
  State<_MainGalleryShell> createState() => _MainGalleryShellState();
}

class _MainGalleryShellState extends State<_MainGalleryShell> {
  int _idx = 0;
  bool _drawer = false;
  _AppTheme _theme = _AppTheme.forest;

  static const List<Map<String, Object>> _screens = [
    {'title': '1. Welcome',                'w': _S1Welcome()},
    {'title': '2. Home',                   'w': _S2Home()},
    {'title': '3. Theme Selection',        'w': _S3ThemeSelection()},
    {'title': '4. Adventure Plan',         'w': _S4AdventurePlan()},
    {'title': '5. Journey Map',            'w': _S5JourneyMap()},
    {'title': '6. Milestone Intro',        'w': _S6MilestoneIntro()},
    {'title': '7. Story Introduction',     'w': _S7StoryIntro()},
    {'title': '8. Activity (Picture)',     'w': _S8Activity()},
    {'title': '9. Activity Feedback',      'w': _S9Feedback()},
    {'title': '10. Adaptive Next',         'w': _S10AdaptiveNext()},
    {'title': '11. Guided Conversation',   'w': _S11GuidedConv()},
    {'title': '12. Session Complete',      'w': _S12SessionComplete()},
    {'title': '13. Progress',              'w': _S13Progress()},
    {'title': '14. Character',             'w': _S14Character()},
    {'title': '15. Therapist Dashboard',   'w': _S15TherapistDash()},
    {'title': '16. Activity Library',      'w': _S16Library()},
    {'title': '17. Activity Detail',       'w': _S17Detail()},
    {'title': '18. Settings',              'w': _S18Settings()},
  ];

  void _go(int i) {
    if (i >= 0 && i < _screens.length) setState(() { _idx = i; _drawer = false; });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      theme: _theme,
      onChanged: (t) => setState(() => _theme = t),
      child: Scaffold(
        body: Stack(children: [
          _InheritedNav(
            index: _idx,
            go: _go,
            child: Column(children: [
              Expanded(child: _screens[_idx]['w'] as Widget),
              if (_idx != 0) _BottomNav(index: _idx, go: _go),
            ]),
          ),

          // Screen selector pill
          Positioned(
            top: 10, right: 12,
            child: SafeArea(child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: _C.blue,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _drawer = !_drawer),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('Screen ${_idx + 1}/18', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                  ]),
                ),
              ),
            )),
          ),

          // Drawer overlay
          if (_drawer)
            GestureDetector(
              onTap: () => setState(() => _drawer = false),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.topRight,
                child: SafeArea(child: Container(
                  margin: const EdgeInsets.only(top: 50, right: 12, left: 12),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 520, maxWidth: 360),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('All 18 Screens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
                      IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _drawer = false)),
                    ]),
                    const Divider(height: 1),
                    Expanded(child: ListView.builder(
                      itemCount: _screens.length,
                      itemBuilder: (ctx, i) {
                        final sel = i == _idx;
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          selected: sel,
                          selectedTileColor: _C.blue.withValues(alpha: 0.12),
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: sel ? _C.blue : Colors.grey.shade300,
                            child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(_screens[i]['title'] as String,
                            style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? _C.blue : Colors.black87)),
                          onTap: () => _go(i),
                        );
                      },
                    )),
                  ]),
                )),
              ),
            ),
        ]),
      ),
    );
  }
}

// ============================================================================
// SHARED COMPONENTS
// ============================================================================

class _BgScaffold extends StatelessWidget {
  final Widget child;
  final bool paintScene;
  const _BgScaffold({required this.child, this.paintScene = true});

  @override
  Widget build(BuildContext context) {
    final theme = _InheritedTheme.themeOf(context);
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [theme.bgTop, theme.bgMid, theme.bgBot],
      )),
      child: Stack(children: [
        if (paintScene)
          Positioned.fill(
            child: Image.asset(
              theme.bgImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CustomPaint(painter: theme.createScenePainter()),
            ),
          ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: paintScene ? 0.35 : 0.15),
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
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: t.plaqueGradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.plaqueBorder, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(
        fontSize: fontSize, fontWeight: FontWeight.w900, color: const Color(0xFFFFF8E7),
        shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 2))],
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
      width: double.infinity, height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.blue, foregroundColor: Colors.white, elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
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
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]),
            child: const Icon(Icons.arrow_back_rounded, color: _C.darkText, size: 20),
          ),
        ),
        Expanded(child: Text(title, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.darkText))),
        const SizedBox(width: 36),
      ]),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.blue.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [BoxShadow(color: _C.blue.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _C.blue, width: 2)),
          child: const CircleAvatar(radius: 22, backgroundColor: _C.chipBg,
            child: Icon(Icons.person_rounded, color: _C.blue, size: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Hi, Aseliya! 👋', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _C.darkText)),
          const SizedBox(height: 2),
          Builder(builder: (ctx) => Text(
            _InheritedTheme.themeOf(ctx).headerQuote,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.blue),
          )),
        ])),
        IconButton(onPressed: () => nav?.go(17), icon: const Icon(Icons.tune_rounded, color: _C.blue, size: 22)),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final void Function(int) go;
  const _BottomNav({required this.index, required this.go});

  int _tab() {
    if (index == 14 || index == 15 || index == 16) return 1;
    if (index == 12) return 2;
    if (index == 17) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tab = _tab();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: _C.blue.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(1, 'Home',     Icons.home_rounded,      tab == 0),
          _navItem(14,'Therapy',  Icons.psychology_rounded, tab == 1),
          _navItem(12,'Progress', Icons.insights_rounded,   tab == 2),
          _navItem(17,'Profile',  Icons.person_rounded,     tab == 3),
        ]),
      )),
    );
  }

  Widget _navItem(int target, String label, IconData icon, bool sel) {
    return GestureDetector(
      onTap: () => go(target),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _C.blue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? _C.blue : Colors.grey.shade500, size: 24),
          if (sel) ...[
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: _C.blue, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ]),
      ),
    );
  }
}

// ============================================================================
// SCENE PAINTERS
// ============================================================================

class _WaterfallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFE8F5E9));
    final trees = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.4), size.height * 0.35, trees);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.3), size.height * 0.4, trees);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.4), size.height * 0.35, trees);
    final water = Paint()..color = const Color(0xFF4FC3F7);
    final stream = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.60, size.height)
      ..lineTo(size.width * 0.55, 0)
      ..close();
    canvas.drawPath(stream, water);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _BeachScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF81D4FA)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6)));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.35), Paint()..color = const Color(0xFF26C6DA));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28), Paint()..color = const Color(0xFFFFD54F));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.06, size.height * 0.2, size.width * 0.05, size.height * 0.52), const Radius.circular(4)), Paint()..color = const Color(0xFF8D6E63));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.085, size.height * 0.18), width: size.width * 0.22, height: size.height * 0.14), Paint()..color = const Color(0xFF388E3C));
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SpaceScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    final star = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (final p in [Offset(size.width * .15, size.height * .2), Offset(size.width * .45, size.height * .15), Offset(size.width * .8, size.height * .25), Offset(size.width * .65, size.height * .8)]) {
      canvas.drawCircle(p, 2.5, star);
    }
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.45), size.height * 0.22, Paint()..color = const Color(0xFFFFB74D));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.75, size.height * 0.45), width: size.width * 0.45, height: size.height * 0.12),
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 4);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _UnderwaterScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF00838F), Color(0xFF006064)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18), Paint()..color = const Color(0xFFFFE082));
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.82), size.height * 0.14, Paint()..color = const Color(0xFFFF7043));
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.85), size.height * 0.10, Paint()..color = const Color(0xFFEC407A));
    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 8, bubble);
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.25), 12, bubble);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SafariScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFCC80), Color(0xFFFFF3E0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.75)));
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.35), size.height * 0.18, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.95), width: size.width * 1.4, height: size.height * 0.45), Paint()..color = const Color(0xFFF57C00));
    final trunk = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.04, size.height * 0.35), trunk);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.27, size.height * 0.45), width: size.width * 0.32, height: size.height * 0.09), trunk);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _CandyScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.2, size.height * 0.9), width: size.width * 0.8, height: size.height * 0.4), Paint()..color = const Color(0xFFF06292));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.8, size.height * 0.9), width: size.width * 0.9, height: size.height * 0.45), Paint()..color = const Color(0xFFBA68C8));
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.8), Offset(size.width * 0.5, size.height * 0.35), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.35), size.height * 0.16, Paint()..color = const Color(0xFF00E676));
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ============================================================================
// MASCOT PAINTERS
// ============================================================================

class _SquirrelPainter extends CustomPainter {
  final String pose;
  _SquirrelPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final body = Paint()..color = const Color(0xFFE07A28);
    final belly = Paint()..color = const Color(0xFFFFF1D6);
    final vest = Paint()..color = const Color(0xFF1E88E5);
    final dark = Paint()..color = const Color(0xFF3E2723);
    final pink = Paint()..color = const Color(0xFFFF8A80);
    final gold = Paint()..color = const Color(0xFFFFC107);
    final tail = Path()
      ..moveTo(cx + size.width * .1, cy + size.height * .2)
      ..cubicTo(cx + size.width * .55, cy + size.height * .1, cx + size.width * .5, cy - size.height * .45, cx + size.width * .1, cy - size.height * .35)
      ..cubicTo(cx + size.width * .25, cy - size.height * .1, cx + size.width * .3, cy + size.height * .1, cx + size.width * .1, cy + size.height * .2);
    canvas.drawPath(tail, body);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * .22, cy - size.height * .32), width: size.width * .18, height: size.height * .26), body);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * .22, cy - size.height * .32), width: size.width * .09, height: size.height * .15), pink);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.width * .22, cy - size.height * .32), width: size.width * .18, height: size.height * .26), body);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.width * .22, cy - size.height * .32), width: size.width * .09, height: size.height * .15), pink);
    canvas.drawCircle(Offset(cx, cy - size.height * .12), size.width * .32, body);
    canvas.drawCircle(Offset(cx, cy - size.height * .05), size.width * .18, belly);
    canvas.drawCircle(Offset(cx - size.width * .12, cy - size.height * .18), size.width * .06, dark);
    canvas.drawCircle(Offset(cx + size.width * .12, cy - size.height * .18), size.width * .06, dark);
    canvas.drawCircle(Offset(cx - size.width * .14, cy - size.height * .20), size.width * .02, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + size.width * .10, cy - size.height * .20), size.width * .02, Paint()..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .22), width: size.width * .44, height: size.height * .42), body);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .22), width: size.width * .46, height: size.height * .38), vest);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .24), width: size.width * .24, height: size.height * .30), belly);
    if (pose == 'trophy') {
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + size.height * .08), width: size.width * .25, height: size.height * .22), gold);
      canvas.drawCircle(Offset(cx, cy + size.height * .02), size.width * .12, gold);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _TurtlePainter extends CustomPainter {
  final String pose;
  _TurtlePainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final shell = Paint()..color = const Color(0xFF2E7D32);
    final hi = Paint()..color = const Color(0xFF4CAF50);
    final skin = Paint()..color = const Color(0xFF80CBC4);
    final belly = Paint()..color = const Color(0xFFB2EBF2);
    final vest = Paint()..color = const Color(0xFF1E88E5);
    final dark = Paint()..color = const Color(0xFF1A237E);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - size.height * .04), width: size.width * .56, height: size.height * .52), shell);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * .04, cy - size.height * .08), width: size.width * .28, height: size.height * .22), hi);
    canvas.drawCircle(Offset(cx, cy - size.height * .30), size.width * .20, skin);
    canvas.drawCircle(Offset(cx - size.width * .09, cy - size.height * .32), size.width * .045, dark);
    canvas.drawCircle(Offset(cx + size.width * .09, cy - size.height * .32), size.width * .045, dark);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * .34, cy + size.height * .08), width: size.width * .22, height: size.height * .14), skin);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.width * .34, cy + size.height * .08), width: size.width * .22, height: size.height * .14), skin);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .18), width: size.width * .38, height: size.height * .22), belly);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .08), width: size.width * .30, height: size.height * .24), vest);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _CosmoBunnyPainter extends CustomPainter {
  final String pose;
  _CosmoBunnyPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final suit = Paint()..color = const Color(0xFFEDE7F6);
    final visor = Paint()..color = const Color(0xFF80DEEA).withValues(alpha: 0.7);
    final ear = Paint()..color = const Color(0xFFD1C4E9);
    final acc = Paint()..color = const Color(0xFF7E57C2);
    final dark = Paint()..color = const Color(0xFF311B92);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - size.width * .18, cy - size.height * .38), width: size.width * .14, height: size.height * .36), ear);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + size.width * .18, cy - size.height * .38), width: size.width * .14, height: size.height * .36), ear);
    canvas.drawCircle(Offset(cx - size.width * .18, cy - size.height * .48), size.width * .05, acc);
    canvas.drawCircle(Offset(cx + size.width * .18, cy - size.height * .48), size.width * .05, acc);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .24), width: size.width * .48, height: size.height * .42), suit);
    canvas.drawCircle(Offset(cx, cy - size.height * .10), size.width * .32, suit);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - size.height * .10), width: size.width * .48, height: size.height * .38), visor);
    canvas.drawCircle(Offset(cx - size.width * .09, cy - size.height * .12), size.width * .04, dark);
    canvas.drawCircle(Offset(cx + size.width * .09, cy - size.height * .12), size.width * .04, dark);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DolphinPainter extends CustomPainter {
  final String pose;
  _DolphinPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final dp = Paint()..color = const Color(0xFF29B6F6);
    final bp = Paint()..color = const Color(0xFFE1F5FE);
    final dk = Paint()..color = const Color(0xFF01579B);
    final path = Path()
      ..moveTo(cx - size.width * .36, cy + size.height * .05)
      ..quadraticBezierTo(cx - size.width * .25, cy - size.height * .35, cx + size.width * .15, cy - size.height * .25)
      ..quadraticBezierTo(cx + size.width * .45, cy - size.height * .15, cx + size.width * .35, cy + size.height * .15)
      ..quadraticBezierTo(cx + size.width * .05, cy + size.height * .35, cx - size.width * .36, cy + size.height * .05);
    canvas.drawPath(path, dp);
    canvas.drawCircle(Offset(cx + size.width * .18, cy - size.height * .02), size.width * .14, bp);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .15), size.width * .04, dk);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _LionCubPainter extends CustomPainter {
  final String pose;
  _LionCubPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final mane = Paint()..color = const Color(0xFFE65100);
    final fur  = Paint()..color = const Color(0xFFFFB74D);
    final muz  = Paint()..color = const Color(0xFFFFF3E0);
    final dark = Paint()..color = const Color(0xFF3E2723);
    canvas.drawCircle(Offset(cx + size.width * .28, cy - size.height * .05), size.width * .18, mane);
    canvas.drawCircle(Offset(cx - size.width * .28, cy - size.height * .05), size.width * .18, mane);
    canvas.drawCircle(Offset(cx, cy - size.height * .18), size.width * .18, mane);
    canvas.drawCircle(Offset(cx, cy - size.height * .10), size.width * .28, fur);
    canvas.drawCircle(Offset(cx - size.width * .22, cy - size.height * .30), size.width * .10, fur);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .30), size.width * .10, fur);
    canvas.drawCircle(Offset(cx, cy - size.height * .04), size.width * .14, muz);
    canvas.drawCircle(Offset(cx - size.width * .10, cy - size.height * .15), size.width * .045, dark);
    canvas.drawCircle(Offset(cx + size.width * .10, cy - size.height * .15), size.width * .045, dark);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .24), width: size.width * .44, height: size.height * .38), fur);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SugarBearPainter extends CustomPainter {
  final String pose;
  _SugarBearPainter({required this.pose});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final pink  = Paint()..color = const Color(0xFFF48FB1);
    final white = Paint()..color = const Color(0xFFFCE4EC);
    final dark  = Paint()..color = const Color(0xFF880E4F);
    final candy = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(Offset(cx - size.width * .22, cy - size.height * .30), size.width * .12, pink);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .30), size.width * .12, pink);
    canvas.drawCircle(Offset(cx - size.width * .22, cy - size.height * .30), size.width * .06, white);
    canvas.drawCircle(Offset(cx + size.width * .22, cy - size.height * .30), size.width * .06, white);
    canvas.drawCircle(Offset(cx, cy - size.height * .10), size.width * .30, pink);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + size.height * .24), width: size.width * .46, height: size.height * .40), pink);
    canvas.drawCircle(Offset(cx, cy + size.height * .22), size.width * .18, white);
    canvas.drawCircle(Offset(cx, cy - size.height * .04), size.width * .14, white);
    canvas.drawCircle(Offset(cx - size.width * .10, cy - size.height * .14), size.width * .04, dark);
    canvas.drawCircle(Offset(cx + size.width * .10, cy - size.height * .14), size.width * .04, dark);
    canvas.drawCircle(Offset(cx, cy + size.height * .22), size.width * .07, candy);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ============================================================================
// JOURNEY PATH PAINTER
// ============================================================================
class _PathPainter extends CustomPainter {
  final _AppTheme theme;
  _PathPainter(this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.accentColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(60, size.height - 40)
      ..cubicTo(size.width * .9, size.height * .7, size.width * .1, size.height * .4, size.width * .8, size.height * .25)
      ..cubicTo(size.width * .9, size.height * .15, size.width * .3, size.height * .1, 110, 45);
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(covariant _PathPainter o) => o.theme != theme;
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
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(children: [
        const SizedBox(height: 10),
        const _Plaque(text: 'Welcome Aseliya!'),
        const SizedBox(height: 24),
        const _Mascot(size: 180),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(theme.welcomeQuote, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.darkText, height: 1.3)),
            const SizedBox(height: 16),
            _Btn(text: "Let's Go!", onTap: () => nav?.go(1)),
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
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _UserHeader(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current Adventure', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(theme.journeyName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _C.darkText)),
                const SizedBox(height: 6),
                const Text('3 / 5 Activities Completed', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              const SizedBox(width: 8),
              const _Mascot(size: 74),
            ]),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: 0.6, backgroundColor: Colors.blue.shade50, color: theme.accentColor, minHeight: 10, borderRadius: BorderRadius.circular(5)),
            const SizedBox(height: 16),
            _Btn(text: 'Continue Adventure', onTap: () => nav?.go(3)),
          ]),
        ),
        const SizedBox(height: 20),
        _item(context, '🗺️', 'My Journey Map', () => nav?.go(4)),
        const SizedBox(height: 10),
        _item(context, '🎨', 'Explore Adventure Themes (6 Worlds)', () => nav?.go(2)),
        const SizedBox(height: 10),
        _item(context, '🏆', 'Achievements & Badges', () => nav?.go(12)),
        const SizedBox(height: 10),
        _item(context, '🐾', 'Meet My Guide (${theme.mascotName})', () => nav?.go(13)),
        const SizedBox(height: 20),
      ]),
    ));
  }
  Widget _item(BuildContext ctx, String em, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
      child: ListTile(
        leading: Text(em, style: const TextStyle(fontSize: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _C.darkText)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: _C.blue),
        onTap: onTap,
      ),
    );
  }
}

// 3. THEME SELECTION
class _S3ThemeSelection extends StatefulWidget {
  const _S3ThemeSelection();
  @override State<_S3ThemeSelection> createState() => _S3State();
}
class _S3State extends State<_S3ThemeSelection> {
  String _cat = 'All';
  final _cats = ['All', 'Nature', 'Ocean', 'Fantasy'];

  @override
  Widget build(BuildContext context) {
    final nav  = _InheritedNav.of(context);
    final ts   = _InheritedTheme.of(context);
    final cur  = ts?.theme ?? _AppTheme.forest;
    final list = _AppTheme.values.where((t) => _cat == 'All' || t.category == _cat).toList();

    return _BgScaffold(paintScene: false, child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _BackHeader(title: ''),
        const _Plaque(text: 'Choose Your World 🗺️', fontSize: 18),
        const SizedBox(height: 4),
        const Text('Pick your favorite speech adventure world & friend!', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 14),
        SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
          child: Row(children: _cats.map((c) {
            final sel = _cat == c;
            return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
              label: Text(c == 'All' ? 'All (6 Worlds)' : c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? Colors.white : _C.darkText)),
              selected: sel, selectedColor: _C.blue, backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: sel ? _C.blue : Colors.grey.shade300)),
              onSelected: (v) { if (v) setState(() => _cat = c); },
            ));
          }).toList()),
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _ThemeCard(theme: list[i], isSelected: cur == list[i], onTap: () => ts?.onChanged(list[i])),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: cur.accentColor, width: 2)),
          child: Column(children: [
            Row(children: [
              const _Mascot(size: 48),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${cur.emoji} ${cur.name} Selected!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cur.accentColor)),
                Text('Guide: ${cur.mascotName} • ${cur.speechPerk}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ])),
            ]),
            const SizedBox(height: 12),
            _Btn(text: 'Continue with ${cur.name} Adventure', onTap: () => nav?.go(3)),
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
  const _ThemeCard({required this.theme, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? theme.accentColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isSelected ? theme.accentColor : Colors.grey.shade300, width: isSelected ? 2.5 : 1.2),
        boxShadow: [BoxShadow(color: isSelected ? theme.accentColor.withValues(alpha: 0.18) : Colors.black12, blurRadius: isSelected ? 12 : 5, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          _ScenePreview(theme: theme, height: 125),
          Positioned(top: 8, left: 8, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(12)),
            child: Text('${theme.emoji} ${theme.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          )),
          if (isSelected) Positioned(top: 8, right: 8, child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: theme.accentColor, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
          )),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(theme.journeyName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? theme.accentColor : _C.darkText))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: isSelected ? theme.accentColor : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            child: Text(isSelected ? 'ACTIVE' : 'SELECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(theme.tagline, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
    child: Text('$icon $text', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
  );
}

// 4. ADVENTURE PLAN
class _S4AdventurePlan extends StatelessWidget {
  const _S4AdventurePlan();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Your Adventure Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        Text(theme.journeyName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 16),
        const _Plaque(text: "Today's Plan", fontSize: 16),
        const SizedBox(height: 8),
        _card(const Column(children: [
          _PRow(icon: '🏰', label: '3 Speech Activities'),
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
        _Btn(text: 'Start Journey', onTap: () => nav?.go(4)),
        const SizedBox(height: 20),
      ]),
    ));
  }
  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
    child: child,
  );
}

class _PRow extends StatelessWidget {
  final String icon, label;
  const _PRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText))),
  ]);
}

class _GRow extends StatelessWidget {
  final String text;
  const _GRow({required this.text});
  @override
  Widget build(BuildContext context) => Row(children: [
    const Icon(Icons.check_circle_rounded, color: _C.green, size: 20), const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText))),
  ]);
}

// 5. JOURNEY MAP
class _S5JourneyMap extends StatelessWidget {
  const _S5JourneyMap();
  @override
  Widget build(BuildContext context) {
    final nav  = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: Column(children: [
      _BackHeader(title: theme.journeyName),
      Expanded(child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _PathPainter(theme))),
        Positioned(bottom: 30, left: 40, child: GestureDetector(onTap: () => nav?.go(5), child: Column(children: [
          const _Mascot(size: 56),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: theme.accentColor, borderRadius: BorderRadius.circular(12)),
            child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
        ]))),
        Positioned(bottom: 120, right: 30, child: _MChip(title: 'Picture Description', locked: false, theme: theme, icon: Icons.image_rounded)),
        Positioned(top: 200, left: 30, child: _MChip(title: 'Passage Reading', locked: true, theme: theme, icon: Icons.auto_stories_rounded)),
        Positioned(top: 110, right: 40, child: _MChip(title: 'Guided Chat', locked: true, theme: theme, icon: Icons.record_voice_over_rounded)),
        Positioned(top: 30, left: 80, child: _MChip(title: '${theme.name} Treasure 🏆', locked: true, theme: theme, icon: Icons.emoji_events_rounded)),
      ])),
    ]));
  }
}

class _MChip extends StatelessWidget {
  final String title; final bool locked; final _AppTheme theme; final IconData icon;
  const _MChip({required this.title, required this.locked, required this.theme, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      border: Border.all(color: locked ? Colors.grey.shade300 : theme.accentColor, width: 2),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(locked ? Icons.lock : icon, size: 18, color: locked ? Colors.grey : _C.gold),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: locked ? Colors.grey : _C.darkText)),
    ]),
  );
}

// 6. MILESTONE INTRO
class _S6MilestoneIntro extends StatelessWidget {
  const _S6MilestoneIntro();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Picture Description', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        const _Mascot(size: 170, pose: 'magnifier'),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Text("Let's look at a picture in ${theme.name} and describe what you see!", textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.darkText))),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.timer_outlined, color: Colors.black54, size: 18), SizedBox(width: 6),
          Text('5 Minutes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'Start Activity', onTap: () => nav?.go(6)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 7. STORY INTRO
class _S7StoryIntro extends StatelessWidget {
  const _S7StoryIntro();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('✦ Chapter 1 ✦', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _C.blue)),
        _Plaque(text: '${theme.name} Exploration', fontSize: 16),
        const SizedBox(height: 12),
        const _SceneWidget(height: 170),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Text('${theme.mascotName} is exploring the ${theme.adventureWord}. Listen and get ready to tell the story!', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _C.darkText, height: 1.4))),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _C.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          onPressed: () {},
          icon: const Icon(Icons.volume_up_rounded), label: const Text('Listen to Audio Guide'),
        ),
        const SizedBox(height: 16),
        _Btn(text: 'Continue >', onTap: () => nav?.go(7)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 8. ACTIVITY (PICTURE)
class _S8Activity extends StatelessWidget {
  const _S8Activity();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('What do you see?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 14),
        const _SceneWidget(height: 220),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          GestureDetector(onTap: () => nav?.go(8), child: const Column(children: [
            CircleAvatar(radius: 32, backgroundColor: _C.blue, child: Icon(Icons.mic, color: Colors.white, size: 32)),
            SizedBox(height: 6),
            Text('Tap and speak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ])),
          GestureDetector(onTap: () {}, child: Column(children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.amber.shade100, child: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24)),
            const SizedBox(height: 6),
            const Text('Need help?', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
        ]),
        const SizedBox(height: 24),
      ]),
    ));
  }
}

// 9. FEEDBACK
class _S9Feedback extends StatelessWidget {
  const _S9Feedback();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Great Job!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        const _Mascot(size: 160),
        const SizedBox(height: 16),
        const Text('You did a wonderful job\ndescribing the scene with confidence!', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _C.darkText, height: 1.4)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_half_rounded, color: _C.gold, size: 32),
          Icon(Icons.star_outline_rounded, color: _C.gold, size: 32),
        ]),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: _C.chipBg, borderRadius: BorderRadius.circular(12)),
          child: const Text('8 / 10 Fluency Score', style: TextStyle(fontWeight: FontWeight.bold, color: _C.blue))),
        const SizedBox(height: 24),
        _Btn(text: 'Continue', onTap: () => nav?.go(9)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 10. ADAPTIVE NEXT
class _S10AdaptiveNext extends StatelessWidget {
  const _S10AdaptiveNext();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('New Challenge', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText)),
        const Text('Unlocked!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.blue)),
        const SizedBox(height: 20),
        Stack(alignment: Alignment.topCenter, children: [
          Container(
            margin: const EdgeInsets.only(top: 40), padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(24), border: Border.all(color: _C.woodMid, width: 3), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: const Column(children: [
              SizedBox(height: 60),
              Text('Your next adventure is', style: TextStyle(fontSize: 14, color: Colors.black54)),
              SizedBox(height: 6),
              Text('Guided Conversation!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.darkText)),
            ]),
          ),
          const _Mascot(size: 130),
        ]),
        const SizedBox(height: 24),
        _Btn(text: "Let's Go!", onTap: () => nav?.go(10)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 11. GUIDED CONVERSATION
class _S11GuidedConv extends StatelessWidget {
  const _S11GuidedConv();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text("Let's Talk!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        Text('Your ${theme.adventureWord} friend ${theme.mascotName} has a question for you.', style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
            child: Text('What do you like most about the ${theme.name.toLowerCase()}?', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _C.darkText)))),
          const SizedBox(width: 8),
          const _Mascot(size: 90),
        ]),
        const SizedBox(height: 30),
        const CircleAvatar(radius: 36, backgroundColor: _C.blue, child: Icon(Icons.mic, color: Colors.white, size: 36)),
        const SizedBox(height: 8),
        const Text('Tap and speak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextButton(onPressed: () => nav?.go(11), child: const Text('Skip Activity', style: TextStyle(color: Colors.grey, fontSize: 14))),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 12. SESSION COMPLETE
class _S12SessionComplete extends StatelessWidget {
  const _S12SessionComplete();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const _Plaque(text: 'Adventure Complete!', fontSize: 18),
        const SizedBox(height: 16),
        const _Mascot(size: 160, pose: 'trophy'),
        const SizedBox(height: 12),
        const Text('You did amazing today!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _StCard(label: 'Activities', value: '3 / 3', emoji: '🧩'),
          _StCard(label: 'Score', value: '8 / 10', emoji: '⭐️'),
          _StCard(label: 'Time', value: '25 min', emoji: '⏱️'),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'Finish & Celebrate', onTap: () => nav?.go(12)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _StCard extends StatelessWidget {
  final String label, value, emoji;
  const _StCard({required this.label, required this.value, required this.emoji});
  @override
  Widget build(BuildContext context) => Container(
    width: 95, padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]),
  );
}

// 13. PROGRESS
class _S13Progress extends StatelessWidget {
  const _S13Progress();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(child: Text('My Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText))),
        Center(child: Text(theme.journeyName, style: const TextStyle(fontSize: 13, color: Colors.black54))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Adventures Completed', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('3 / 5', style: TextStyle(fontWeight: FontWeight.bold, color: _C.blue)),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.6, backgroundColor: Colors.blue.shade50, color: theme.accentColor, minHeight: 10, borderRadius: BorderRadius.circular(5)),
          ])),
        const SizedBox(height: 20),
        const Text('Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ABadge(emoji: '🥇', label: 'First Steps'),
          _ABadge(emoji: '🗣️', label: 'Great Talker'),
          _ABadge(emoji: '🌟', label: 'Explorer'),
        ]),
        const SizedBox(height: 24),
        _Btn(text: 'View Journey Map', onTap: () => nav?.go(4)),
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
    CircleAvatar(radius: 28, backgroundColor: _C.chipBg, child: Text(emoji, style: const TextStyle(fontSize: 26))),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _C.darkText)),
  ]);
}

// 14. CHARACTER
class _S14Character extends StatelessWidget {
  const _S14Character();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        Text(theme.characterScreenTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        const _Mascot(size: 190),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Text(theme.mascotDescription, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: _C.darkText, height: 1.4))),
        const SizedBox(height: 24),
        _Btn(text: 'Back to Home', onTap: () => nav?.go(1)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 15. THERAPIST DASHBOARD
class _S15TherapistDash extends StatelessWidget {
  const _S15TherapistDash();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    final theme = _InheritedTheme.themeOf(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(child: Text("Aseliya's Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText))),
        Center(child: Text(theme.journeyName, style: const TextStyle(fontSize: 13, color: Colors.black54))),
        const SizedBox(height: 16),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _MCard(title: 'Severity', value: 'Moderate'),
          _MCard(title: 'Stutter Type', value: 'Repetition'),
          _MCard(title: 'Psych Score', value: '5 / 10'),
        ]),
        const SizedBox(height: 20),
        const Text('Recent Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 10),
        const _ARow(icon: '🖼️', title: 'Picture Description', score: '8 / 10'),
        const SizedBox(height: 8),
        const _ARow(icon: '📖', title: 'Story Retelling', score: '7 / 10'),
        const SizedBox(height: 8),
        const _ARow(icon: '🎙️', title: 'Guided Conversation', score: '8 / 10'),
        const SizedBox(height: 24),
        _Btn(text: 'View Full Report', onTap: () => nav?.go(15)),
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
    width: 100, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: Column(children: [
      Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _C.darkText)),
    ]),
  );
}

class _ARow extends StatelessWidget {
  final String icon, title, score;
  const _ARow({required this.icon, required this.title, required this.score});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 20)), const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.darkText))),
      Text(score, style: const TextStyle(fontWeight: FontWeight.bold, color: _C.blue)),
    ]),
  );
}

// 16. LIBRARY
class _S16Library extends StatelessWidget {
  const _S16Library();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _BackHeader(title: ''),
        const Center(child: Text('Activity Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.darkText))),
        const SizedBox(height: 16),
        const SingleChildScrollView(scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics(), child: Row(children: [
          _CTab(title: 'All', sel: true),
          _CTab(title: 'Speaking', sel: false),
          _CTab(title: 'Breathing', sel: false),
          _CTab(title: 'Reading', sel: false),
        ])),
        const SizedBox(height: 16),
        _LItem(icon: '🖼️', title: 'Picture Description', sub: 'Focus: Fluency & Expression', onTap: () => nav?.go(16)),
        const SizedBox(height: 10),
        _LItem(icon: '🎙️', title: 'Guided Conversation', sub: 'Focus: Pausing & Phrasing', onTap: () => nav?.go(16)),
        const SizedBox(height: 10),
        _LItem(icon: '🔤', title: 'Syllable Practice', sub: 'Focus: Easy Onset', onTap: () {}),
        const SizedBox(height: 10),
        _LItem(icon: '🫁', title: 'Breathing Exercise', sub: 'Focus: Relaxation', onTap: () {}),
        const SizedBox(height: 20),
        _Btn(text: '+ Add Activity', onTap: () {}),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _CTab extends StatelessWidget {
  final String title; final bool sel;
  const _CTab({required this.title, required this.sel});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: sel ? _C.blue : Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Text(title, style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
  );
}

class _LItem extends StatelessWidget {
  final String icon, title, sub; final VoidCallback onTap;
  const _LItem({required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _C.darkText)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _C.blue),
      onTap: onTap,
    ),
  );
}

// 17. DETAIL
class _S17Detail extends StatelessWidget {
  const _S17Detail();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Picture Description', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        Container(width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Technique', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Pausing & Phrasing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _C.darkText)),
            SizedBox(height: 16),
            Text('Suitable For', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• Moderate Severity\n• Repetition Type\n• Age 6 - 10', style: TextStyle(fontSize: 14, color: _C.darkText, height: 1.4)),
            SizedBox(height: 16),
            Text('Description', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('Child describes a picture in short phrases with encouragement of smooth easy pauses.', style: TextStyle(fontSize: 14, color: _C.darkText, height: 1.4)),
          ])),
        const SizedBox(height: 24),
        _Btn(text: 'Edit Activity', onTap: () => nav?.go(17)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

// 18. SETTINGS
class _S18Settings extends StatelessWidget {
  const _S18Settings();
  @override
  Widget build(BuildContext context) {
    final nav = _InheritedNav.of(context);
    return _BgScaffold(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        const _BackHeader(title: ''),
        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.darkText)),
        const SizedBox(height: 20),
        _STile(icon: Icons.person_outline_rounded, title: 'Profile', onTap: () {}),
        const SizedBox(height: 10),
        _SSwitchTile(icon: Icons.volume_up_outlined, title: 'Sound Effects', value: true, onChanged: (v) {}),
        const SizedBox(height: 10),
        _STile(icon: Icons.mic_none_rounded, title: 'Voice', trailing: 'Sinhala / English', onTap: () {}),
        const SizedBox(height: 10),
        _SSwitchTile(icon: Icons.access_time_rounded, title: 'Daily Reminders', value: true, onChanged: (v) {}),
        const SizedBox(height: 10),
        _STile(icon: Icons.palette_outlined, title: 'Change Theme', trailing: '6 Worlds', onTap: () => nav?.go(2)),
        const SizedBox(height: 10),
        _STile(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () {}),
        const SizedBox(height: 10),
        _STile(icon: Icons.arrow_back_rounded, title: 'Back to Main App', color: _C.blue, onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 20),
      ]),
    ));
  }
}

class _STile extends StatelessWidget {
  final IconData icon; final String title; final String? trailing; final Color? color; final VoidCallback onTap;
  const _STile({required this.icon, required this.title, this.trailing, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: ListTile(
      leading: Icon(icon, color: color ?? _C.blue),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? _C.darkText)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 4),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ]),
      onTap: onTap,
    ),
  );
}

class _SSwitchTile extends StatelessWidget {
  final IconData icon; final String title; final bool value; final ValueChanged<bool> onChanged;
  const _SSwitchTile({required this.icon, required this.title, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: ListTile(
      leading: Icon(icon, color: _C.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _C.darkText)),
      trailing: Switch(value: value, activeTrackColor: _C.blue, onChanged: onChanged),
    ),
  );
}