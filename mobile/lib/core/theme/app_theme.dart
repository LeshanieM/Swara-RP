import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Swara design tokens.
///
/// Brand blues are fixed:
/// - primary `#2563EB`
/// - primaryDeep `#1E40AF`
/// - primaryLight `#60A5FA`
class AppColors {
  AppColors._();

  // Brand (do not change these values)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDeep = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Surfaces — warm linen, not clinic-white
  static const Color background = Color(0xFFF4F0E8);
  static const Color surface = Color(0xFFFAF7F1);
  static const Color surfaceRaised = Color(0xFFFFFCF7);
  static const Color primaryWash = Color(0xFFE8EEF9);

  // Ink — cool charcoal for contrast on warm paper
  static const Color text = Color(0xFF1B2433);
  static const Color textLight = Color(0xFF5A6472);
  static const Color mutedText = Color(0xFF5A6472);
  static const Color onPrimary = Color(0xFFF7F4EE);

  static const Color divider = Color(0xFFDDD6C8);
  static const Color borderNavy = Color(0xFFC9D4E8);

  // Semantic — one earth accent family, not extra brand hues
  static const Color success = Color(0xFF2F7D5A);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFC45C4A);
  static const Color coralRed = error;

  static const Color white = Color(0xFFFAF7F1);
  static const Color cardCream = surfaceRaised;
  static const Color cardBg = surfaceRaised;
  static const Color deepNavy = Color(0xFF1B2433);

  // Backward-compatible aliases (map old names onto the new system)
  static const Color primaryBlue = primary;
  static const Color oceanBlue = primary;
  static const Color indigoBlue = primary;
  static const Color ceruleanBlue = primaryLight;
  static const Color navyBlue = primaryDeep;
  static const Color iceBlue = primaryWash;
  static const Color softBlueBg = background;
  static const Color ctaOrange = primary;
  static const Color secondary = primaryDeep;
  static const Color secondaryLight = primaryWash;
  static const Color softYellow = warning;
  static const Color accentYellow = warning;
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
  static const double sm = 10;

  /// Standard content cards
  static const double md = 14;

  /// Featured modules (home activities, recording well)
  static const double lg = 20;

  /// Primary CTAs, nav pill
  static const double pill = 28;

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

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.primaryDeep.withValues(alpha: 0.06),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Primary actions only
  static List<BoxShadow> get cta => [
        BoxShadow(
          color: AppColors.primaryDeep.withValues(alpha: 0.28),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppMotion {
  AppMotion._();

  /// The one transition we use: screen / splash entrance.
  static const Duration entrance = Duration(milliseconds: 420);
  static const Curve entranceCurve = Curves.easeOutCubic;
}

class AppTheme {
  static const List<String> fontFallbacks = [
    'Noto Sans Sinhala',
    'NotoSansSinhala',
    'sans-serif',
  ];

  static String get _uiFont => GoogleFonts.nunito().fontFamily!;

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
      displayLarge: _ui(size: 32, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.4),
      headlineLarge: _ui(size: 24, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.3),
      headlineMedium: _ui(size: 20, weight: FontWeight.w700, height: 1.25),
      titleLarge: _ui(size: 18, weight: FontWeight.w700, height: 1.3),
      titleMedium: _ui(size: 16, weight: FontWeight.w600, height: 1.35),
      bodyLarge: _ui(size: 16, weight: FontWeight.w400, height: 1.5),
      bodyMedium: _ui(size: 14, weight: FontWeight.w400, height: 1.45, color: AppColors.textLight),
      bodySmall: _ui(size: 12, weight: FontWeight.w500, height: 1.4, color: AppColors.textLight),
      labelLarge: _ui(size: 16, weight: FontWeight.w700, letterSpacing: 0.15),
      labelMedium: _ui(size: 13, weight: FontWeight.w600, letterSpacing: 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
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
        centerTitle: false,
        titleTextStyle: _ui(size: 20, weight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primaryWash,
          disabledForegroundColor: AppColors.textLight,
          elevation: 0,
          shadowColor: AppColors.primaryDeep.withValues(alpha: 0.28),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
          textStyle: _ui(size: 16, weight: FontWeight.w700, letterSpacing: 0.15, color: AppColors.onPrimary),
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
            return 3;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
          textStyle: _ui(size: 15, weight: FontWeight.w600),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(AppColors.primaryWash),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          textStyle: _ui(size: 14, weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: _ui(size: 14, color: AppColors.textLight),
        hintStyle: _ui(size: 14, color: AppColors.textLight),
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
          side: const BorderSide(color: AppColors.divider),
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
  static TextStyle get heading1 => AppTheme._ui(
        size: 32,
        weight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.4,
      );
  static TextStyle get heading2 => AppTheme._ui(
        size: 24,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      );
  static TextStyle get heading3 => AppTheme._ui(
        size: 18,
        weight: FontWeight.w700,
        height: 1.3,
        color: AppColors.text,
      );
  static TextStyle get body => AppTheme._ui(size: 16, height: 1.5);
  static TextStyle get bodySmall => AppTheme._ui(
        size: 14,
        color: AppColors.textLight,
        height: 1.45,
      );
  static TextStyle get caption => AppTheme._ui(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.textLight,
      );
  static TextStyle get label => AppTheme._ui(size: 13, weight: FontWeight.w600);
}
