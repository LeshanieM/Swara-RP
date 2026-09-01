part of 'swara_therapy_ui.dart';

// ---------------------------------------------------------------------------
// PUBLIC ENTRY POINT
// ---------------------------------------------------------------------------
/// Therapy journey shown inside the main Swara application.
class SwaraTherapyUI extends StatelessWidget {
  const SwaraTherapyUI({super.key});

  @override
  Widget build(BuildContext context) => const _TherapyJourneyShell();
}

// ============================================================================
// THEME ENUM & CONSTANTS (6 Rich Worlds)
// ============================================================================
enum _AppTheme { forest, beach, space, underwater, safari, candyland }

extension _AppThemeX on _AppTheme {
  String get name {
    switch (this) {
      case _AppTheme.forest:
        return 'Forest';
      case _AppTheme.beach:
        return 'Beach';
      case _AppTheme.space:
        return 'Space';
      case _AppTheme.underwater:
        return 'Underwater';
      case _AppTheme.safari:
        return 'Safari';
      case _AppTheme.candyland:
        return 'Candy Land';
    }
  }

  String get emoji {
    switch (this) {
      case _AppTheme.forest:
        return '🌲';
      case _AppTheme.beach:
        return '🌊';
      case _AppTheme.space:
        return '🚀';
      case _AppTheme.underwater:
        return '🐠';
      case _AppTheme.safari:
        return '🦁';
      case _AppTheme.candyland:
        return '🍭';
    }
  }

  String get category {
    switch (this) {
      case _AppTheme.forest:
      case _AppTheme.safari:
        return 'Nature';
      case _AppTheme.beach:
      case _AppTheme.underwater:
        return 'Ocean';
      case _AppTheme.space:
      case _AppTheme.candyland:
        return 'Fantasy';
    }
  }

  String get tagline {
    switch (this) {
      case _AppTheme.forest:
        return 'Explore magical Whispering Woods';
      case _AppTheme.beach:
        return 'Explore sunny Sandy Shore';
      case _AppTheme.space:
        return 'Explore starry Cosmic Galaxy';
      case _AppTheme.underwater:
        return 'Explore deep Coral Kingdom';
      case _AppTheme.safari:
        return 'Explore golden Savanna Plains';
      case _AppTheme.candyland:
        return 'Explore sweet Meadow Treats';
    }
  }

  String get speechPerk {
    switch (this) {
      case _AppTheme.forest:
        return 'Calm & Easy Onset 🍃';
      case _AppTheme.beach:
        return 'Smooth Rhythm & Waves 🌊';
      case _AppTheme.space:
        return 'Confident & Bold Speech 🚀';
      case _AppTheme.underwater:
        return 'Gentle Pausing & Flow 🫧';
      case _AppTheme.safari:
        return 'Clear & Brave Projection 🦁';
      case _AppTheme.candyland:
        return 'Joyful & Expressive Voice 🍬';
    }
  }

  String get journeyName {
    switch (this) {
      case _AppTheme.forest:
        return 'Whispering Woods Journey';
      case _AppTheme.beach:
        return 'Sunny Shore Journey';
      case _AppTheme.space:
        return 'Cosmic Star Journey';
      case _AppTheme.underwater:
        return 'Coral Kingdom Journey';
      case _AppTheme.safari:
        return 'Golden Savanna Journey';
      case _AppTheme.candyland:
        return 'Sweet Meadow Journey';
    }
  }

  String get adventureWord {
    switch (this) {
      case _AppTheme.forest:
        return 'forest adventure';
      case _AppTheme.beach:
        return 'beach adventure';
      case _AppTheme.space:
        return 'space adventure';
      case _AppTheme.underwater:
        return 'ocean adventure';
      case _AppTheme.safari:
        return 'safari adventure';
      case _AppTheme.candyland:
        return 'candy adventure';
    }
  }

  String get welcomeQuote {
    switch (this) {
      case _AppTheme.forest:
        return 'Ready for your\nforest adventure? 🌲';
      case _AppTheme.beach:
        return 'Ready for your\nbeach adventure? 🌊';
      case _AppTheme.space:
        return 'Blast off to\nstar adventure! 🚀';
      case _AppTheme.underwater:
        return 'Dive into\nocean adventure! 🐠';
      case _AppTheme.safari:
        return 'Roar into\nsafari adventure! 🦁';
      case _AppTheme.candyland:
        return 'Welcome to\nsweet adventure! 🍭';
    }
  }

  String get mascotName {
    switch (this) {
      case _AppTheme.forest:
        return 'Milo';
      case _AppTheme.beach:
        return 'Sandy';
      case _AppTheme.space:
        return 'Cosmo';
      case _AppTheme.underwater:
        return 'Bubbles';
      case _AppTheme.safari:
        return 'Leo';
      case _AppTheme.candyland:
        return 'Pip';
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
      case _AppTheme.forest:
        return const Color(0xFF4CAF50);
      case _AppTheme.beach:
        return const Color(0xFF00ACC1);
      case _AppTheme.space:
        return const Color(0xFF7E57C2);
      case _AppTheme.underwater:
        return const Color(0xFF0288D1);
      case _AppTheme.safari:
        return const Color(0xFFE65100);
      case _AppTheme.candyland:
        return const Color(0xFFD81B60);
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
      case _AppTheme.beach:
        return const Color(0xFF9A6800);
      case _AppTheme.space:
        return const Color(0xFFEDE7F6);
      case _AppTheme.underwater:
        return const Color(0xFF006064);
      case _AppTheme.safari:
        return const Color(0xFFBF360C);
      case _AppTheme.candyland:
        return const Color(0xFF880E4F);
      case _AppTheme.forest:
        return const Color(0xFF3D200B);
    }
  }

  Color get bgTop {
    switch (this) {
      case _AppTheme.beach:
        return const Color(0xFFE0F7FA);
      case _AppTheme.space:
        return const Color.fromARGB(255, 155, 158, 246);
      case _AppTheme.underwater:
        return const Color(0xFFE0F7FA);
      case _AppTheme.safari:
        return const Color(0xFFFFF3E0);
      case _AppTheme.candyland:
        return const Color(0xFFFCE4EC);
      case _AppTheme.forest:
        return const Color(0xFFE1F5FE);
    }
  }

  Color get bgMid {
    switch (this) {
      case _AppTheme.beach:
        return const Color(0xFFFFF8E1);
      case _AppTheme.space:
        return const Color.fromARGB(255, 103, 107, 207);
      case _AppTheme.underwater:
        return const Color(0xFFB2EBF2);
      case _AppTheme.safari:
        return const Color(0xFFFFE0B2);
      case _AppTheme.candyland:
        return const Color(0xFFF8BBD0);
      case _AppTheme.forest:
        return const Color(0xFFF1F8E9);
    }
  }

  Color get bgBot {
    switch (this) {
      case _AppTheme.beach:
        return const Color(0xFFFFECB3);
      case _AppTheme.space:
        return const Color.fromARGB(255, 103, 107, 207);
      case _AppTheme.underwater:
        return const Color(0xFF80DEEA);
      case _AppTheme.safari:
        return const Color(0xFFFDC985);
      case _AppTheme.candyland:
        return const Color(0xFFFCA4C1);
      case _AppTheme.forest:
        return const Color(0xFFE8F5E9);
    }
  }

  String get bgImage {
    switch (this) {
      case _AppTheme.forest:
        return 'assets/images/component3/magical_forest_bg.jpg';
      case _AppTheme.beach:
        return 'assets/images/component3/beach_bg.jpg';
      case _AppTheme.space:
        return 'assets/images/component3/space_bg.jpg';
      case _AppTheme.underwater:
        return 'assets/images/component3/underwater_bg.jpg';
      case _AppTheme.safari:
        return 'assets/images/component3/safari_bg.jpg';
      case _AppTheme.candyland:
        return 'assets/images/component3/candyland_bg.jpg';
    }
  }

  String get sceneImage {
    switch (this) {
      case _AppTheme.forest:
        return 'assets/images/component3/waterfall_scene.jpg';
      case _AppTheme.beach:
        return 'assets/images/component3/beach_bg.jpg';
      case _AppTheme.space:
        return 'assets/images/component3/space_scene.jpg';
      case _AppTheme.underwater:
        return 'assets/images/component3/underwater_scene.jpg';
      case _AppTheme.safari:
        return 'assets/images/component3/safari_scene.jpg';
      case _AppTheme.candyland:
        return 'assets/images/component3/candyland_scene.jpg';
    }
  }

  String mascotImage(String pose) {
    switch (this) {
      case _AppTheme.forest:
        if (pose == 'magnifier')
          return 'assets/images/component3/milo_magnifier.jpg';
        if (pose == 'trophy') return 'assets/images/component3/milo_trophy.jpg';
        return 'assets/images/component3/milo_mascot.jpg';
      case _AppTheme.beach:
        if (pose == 'magnifier')
          return 'assets/images/component3/turtle_magnifier.jpg';
        if (pose == 'trophy')
          return 'assets/images/component3/turtle_trophy.jpg';
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
      case _AppTheme.beach:
        return _BeachScenePainter();
      case _AppTheme.space:
        return _SpaceScenePainter();
      case _AppTheme.underwater:
        return _UnderwaterScenePainter();
      case _AppTheme.safari:
        return _SafariScenePainter();
      case _AppTheme.candyland:
        return _CandyScenePainter();
      case _AppTheme.forest:
        return _WaterfallPainter();
    }
  }

  CustomPainter createMascotPainter(String pose) {
    switch (this) {
      case _AppTheme.beach:
        return _TurtlePainter(pose: pose);
      case _AppTheme.space:
        return _CosmoBunnyPainter(pose: pose);
      case _AppTheme.underwater:
        return _DolphinPainter(pose: pose);
      case _AppTheme.safari:
        return _LionCubPainter(pose: pose);
      case _AppTheme.candyland:
        return _SugarBearPainter(pose: pose);
      case _AppTheme.forest:
        return _SquirrelPainter(pose: pose);
    }
  }
}

// ============================================================================
// COLORS
// ============================================================================
class _C {
  static const Color blue = Color(0xFF0066CC);
  static const Color darkText = Color(0xFF153B60);
  static const Color woodMid = Color(0xFF8D5B2C);
  static const Color green = Color(0xFF4CAF50);
  static const Color gold = Color(0xFFFFB300);
  static const Color chipBg = Color(0xFFE1F5FE);
}

// ============================================================================
// INHERITED STATE: THEME
// ============================================================================
class _InheritedTheme extends InheritedWidget {
  final _AppTheme theme;
  final ValueChanged<_AppTheme> onChanged;
  const _InheritedTheme(
      {required this.theme, required this.onChanged, required super.child});

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
  const _InheritedNav(
      {required this.index, required this.go, required super.child});

  static _InheritedNav? of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_InheritedNav>();

  @override
  bool updateShouldNotify(_InheritedNav old) => old.index != index;
}
