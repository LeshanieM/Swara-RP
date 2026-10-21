import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Swara design tokens.
///
/// Shared Swara Calm Cub palette.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1D4A87);
  static const Color primaryDeep = Color(0xFF1D4A87);
  static const Color primaryLight = Color(0xFFD9E6F7);

  // Surfaces — warm linen, not clinic-white
  static const Color background = Color(0xFFF2F6F5);
  static const Color surface = Color(0xFFF2F6F5);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color primaryWash = Color(0xFFD9E6F7);
  static const Color groundHome = Color(0xFFE6F4F1);
  static const Color groundBreathe = Color(0xFFDCEEFA);
  static const Color groundRead = Color(0xFFFFF6E0);
  static const Color groundFeel = Color(0xFFEEE9FB);
  static const Color groundGarden = Color(0xFFE4F3DC);
  static const Color groundAdult = Color(0xFFF2F6F5);
  static const Color groundSky = Color(0xFFDCEEFA);
  static const Color sun = Color(0xFFFFC94A);
  static const Color sunTint = Color(0xFFFFF3CF);
  static const Color lilacTint = Color(0xFFDCD3F8);
  static const Color coral = Color(0xFFFF8A6B);
  static const Color coralDeep = Color(0xFFE4553A);
  static const Color coralTint = Color(0xFFFFD3C6);

  // Ink — cool charcoal for contrast on warm paper
  static const Color text = Color(0xFF1E3A44);
  static const Color textLight = Color(0xFF3F5F6A);
  static const Color mutedText = Color(0xFF3F5F6A);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFD9E6F7);
  static const Color borderNavy = Color(0xFFD9E6F7);

  // Semantic — one earth accent family, not extra brand hues
  static const Color success = Color(0xFF5FB77A);
  static const Color warning = Color(0xFFF2B93B);
  static const Color error = Color(0xFF1E3A44);
  static const Color coralRed = error;

  static const Color white = Color(0xFFFFFFFF);
  static const Color cardCream = surfaceRaised;
  static const Color cardBg = surfaceRaised;
  static const Color deepNavy = Color(0xFF1E3A44);

  // Backward-compatible aliases (map old names onto the new system)
  static const Color primaryBlue = primary;
  static const Color oceanBlue = primary;
  static const Color indigoBlue = primary;
  static const Color ceruleanBlue = primaryLight;
  static const Color navyBlue = primaryDeep;
  static const Color iceBlue = primaryWash;
  static const Color softBlueBg = background;
  static const Color ctaOrange = sun;
  static const Color secondary = primaryDeep;
  static const Color secondaryLight = primaryWash;
  static const Color softYellow = sunTint;
  static const Color accentYellow = sun;
  static const Color mintGreen = success;
  static const Color skyBlue = primaryLight;
  static const Color jewelNavy = background;
  static const Color jewelEmerald = background;
  static const Color jewelTeal = background;
  static const Color jewelPurple = background;

  static const Color c1Blue = primary;
  static const Color c1BlueLight = primaryLight;
  static const Color c1BlueSubtle = primaryWash;
  static const Color c2Blue = primaryDeep;
  static const Color c2BlueLight = primary;
  static const Color c2BlueSubtle = primaryWash;
  static const Color c3Blue = primary;
  static const Color c3BlueLight = primaryLight;
  static const Color c3BlueSubtle = primaryWash;
  static const Color c4Blue = primaryDeep;
  static const Color c4BlueLight = primaryLight;
  static const Color c4BlueSubtle = primaryWash;

  static const Color component1Green = c1Blue;
  static const Color component2Lavender = c2Blue;
  static const Color component3Yellow = c3Blue;
  static const Color component4Orange = c4Blue;
  static const Color gradient1 = primaryDeep;
  static const Color gradient2 = primary;

  static const LinearGradient c1Gradient = LinearGradient(
    colors: [background, background],
  );
  static const LinearGradient c2Gradient = LinearGradient(
    colors: [background, background],
  );
  static const LinearGradient c3Gradient = LinearGradient(
    colors: [background, background],
  );
  static const LinearGradient c4Gradient = LinearGradient(
    colors: [background, background],
  );
  static const LinearGradient homeGradient = LinearGradient(
    colors: [background, background],
  );
}

class AppRadii {
  AppRadii._();

  /// Chips, tiny badges
  static const double xs = 6;

  /// Text fields, settings rows
  static const double sm = 22;

  /// Standard content cards
  static const double md = 24;

  /// Featured modules (home activities, recording well)
  static const double lg = 32;

  /// Primary CTAs, nav pill
  static const double pill = 32;

  static BorderRadius xsAll = BorderRadius.circular(xs);
  static BorderRadius smAll = BorderRadius.circular(sm);
  static BorderRadius mdAll = BorderRadius.circular(md);
  static BorderRadius lgAll = BorderRadius.circular(lg);
  static BorderRadius pillAll = BorderRadius.circular(pill);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = [];

  /// Settings / list rows — structure from a hairline, not a shadow
  static List<BoxShadow> get rest => none;

  static List<BoxShadow> get card => none;

  /// Primary actions only
  static List<BoxShadow> get cta => none;
}

class AppMotion {
  AppMotion._();

  /// The one transition we use: screen / splash entrance.
  static const Duration entrance = Duration(milliseconds: 500);
  static const Curve entranceCurve = Curves.easeInOut;
}

class AppTheme {
  static const List<String> fontFallbacks = [
    'Noto Sans Sinhala',
    'NotoSansSinhala',
    'sans-serif',
  ];

  static String get _uiFont => GoogleFonts.nunito().fontFamily!;

  static TextStyle _display({
    required double size,
    required FontWeight weight,
    double height = 1.2,
    double letterSpacing = 0,
    Color color = AppColors.text,
  }) => GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      ).copyWith(fontFamilyFallback: fontFallbacks);

  static TextStyle _ui({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.4,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.text,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: fontFallbacks);
  }

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryWash,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.primaryDeep,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.primaryLight,
      onTertiary: AppColors.primaryDeep,
      error: AppColors.error,
      onError: Color(0xFFFFF8F6),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textLight,
      outline: AppColors.divider,
      outlineVariant: AppColors.divider,
    );

    final textTheme = TextTheme(
      displayLarge: _display(size: 32, weight: FontWeight.w600),
      headlineLarge: _display(size: 24, weight: FontWeight.w600),
      headlineMedium: _display(size: 22, weight: FontWeight.w600),
      titleLarge: _display(size: 20, weight: FontWeight.w600),
      titleMedium: _display(size: 18, weight: FontWeight.w600),
      bodyLarge: _ui(size: 17, weight: FontWeight.w700, height: 1.3),
      bodyMedium: _ui(size: 16, weight: FontWeight.w700, height: 1.35, color: AppColors.textLight),
      bodySmall: _ui(size: 16, weight: FontWeight.w700, height: 1.35, color: AppColors.textLight),
      labelLarge: _display(size: 22, weight: FontWeight.w600),
      labelMedium: _ui(size: 14, weight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.groundAdult,
      fontFamily: _uiFont,
      fontFamilyFallback: fontFallbacks,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SwaraFadeTransitionsBuilder(),
          TargetPlatform.iOS: _SwaraFadeTransitionsBuilder(),
          TargetPlatform.windows: _SwaraFadeTransitionsBuilder(),
          TargetPlatform.macOS: _SwaraFadeTransitionsBuilder(),
          TargetPlatform.linux: _SwaraFadeTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _display(size: 22, weight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primaryWash,
          disabledForegroundColor: AppColors.textLight,
          elevation: 0,
          shadowColor: AppColors.primaryDeep.withValues(alpha: 0.28),
          minimumSize: const Size(double.infinity, 64),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
          textStyle: _display(size: 22, weight: FontWeight.w600).copyWith(color: AppColors.onPrimary),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.22);
            }
            if (states.contains(WidgetState.focused)) {
              return AppColors.primaryLight.withValues(alpha: 0.18);
            }
            return null;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            if (states.contains(WidgetState.disabled)) return 0;
            return 0;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
          textStyle: _display(size: 19, weight: FontWeight.w600),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(AppColors.primaryWash),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          minimumSize: const Size(48, 52),
          textStyle: _ui(size: 16, weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.groundAdult,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(borderRadius: AppRadii.smAll, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.primaryWash, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.primary, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.text, width: 2),
        ),
        labelStyle: _ui(size: 16, weight: FontWeight.w700, color: AppColors.textLight),
        floatingLabelStyle: _ui(size: 16, weight: FontWeight.w700, color: AppColors.primary),
        hintStyle: _ui(size: 16, weight: FontWeight.w700, color: AppColors.textLight),
        errorMaxLines: 3,
        prefixIconColor: AppColors.primaryDeep,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryWash,
        checkmarkColor: AppColors.primaryDeep,
        labelStyle: _ui(size: 13, weight: FontWeight.w600),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xsAll),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onPrimary;
          return AppColors.surfaceRaised;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.divider;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryWash,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: _ui(size: 14, color: AppColors.onPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.smAll),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1, thickness: 1),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: const BorderSide(color: AppColors.primaryWash, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedItemColor: AppColors.primaryDeep,
        unselectedItemColor: AppColors.textLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryDeep, size: 22),
    );
  }
}

class _SwaraFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _SwaraFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.entranceCurve),
      child: child,
    );
  }
}

class AppTextStyles {
  static TextStyle get heading1 => AppTheme._display(
        size: 32,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.4,
      );
  static TextStyle get heading2 => AppTheme._display(
        size: 24,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.3,
      );
  static TextStyle get heading3 => AppTheme._display(
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
        color: AppColors.text,
      );
  static TextStyle get body => AppTheme._ui(size: 17, weight: FontWeight.w700, height: 1.3);
  static TextStyle get bodySmall => AppTheme._ui(
        size: 16,
        weight: FontWeight.w700,
        color: AppColors.textLight,
        height: 1.45,
      );
  static TextStyle get caption => AppTheme._ui(
        size: 14,
        weight: FontWeight.w700,
        color: AppColors.textLight,
      );
  static TextStyle get label => AppTheme._ui(size: 14, weight: FontWeight.w700);
  static TextStyle get titleLarge => AppTheme._display(size: 20, weight: FontWeight.w600, height: 1.3);
  static TextStyle get titleMedium => AppTheme._display(size: 18, weight: FontWeight.w600, height: 1.35);
}
