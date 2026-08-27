import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue & White Palette (Light Themes)
  static const Color primaryBlue    = Color(0xFF0066CC); // Royal Blue
  static const Color oceanBlue      = Color(0xFF0284C7); // Vibrant Sky Blue
  static const Color indigoBlue     = Color(0xFF2563EB); // Deep Cobalt
  static const Color ceruleanBlue   = Color(0xFF0EA5E9); // Bright Cerulean
  static const Color navyBlue       = Color(0xFF1E3A8A); // Deep Navy
  static const Color iceBlue        = Color(0xFFE0F2FE); // Soft Ice Light Blue
  static const Color softBlueBg     = Color(0xFFF0F7FF); // Primary App Light Background

  // Component Shades of Blue (for 4 components)
  // Component 1 (Speech / Assessment): Royal / Cobalt Blue
  static const Color c1Blue         = Color(0xFF0066CC);
  static const Color c1BlueLight    = Color(0xFF2563EB);
  static const Color c1BlueSubtle   = Color(0xFFEFF6FF);

  // Component 2 (Secondary Behaviour / Camera): Deep Ocean / Indigo Blue
  static const Color c2Blue         = Color(0xFF1D4ED8);
  static const Color c2BlueLight    = Color(0xFF3B82F6);
  static const Color c2BlueSubtle   = Color(0xFFEEF2FF);

  // Component 3 (Guided Therapy / Storybook): Sky / Cerulean Blue
  static const Color c3Blue         = Color(0xFF0284C7);
  static const Color c3BlueLight    = Color(0xFF0EA5E9);
  static const Color c3BlueSubtle   = Color(0xFFF0F9FF);

  // Component 4 (Spontaneous Free Talk): Marine / Electric Blue
  static const Color c4Blue         = Color(0xFF0369A1);
  static const Color c4BlueLight    = Color(0xFF38BDF8);
  static const Color c4BlueSubtle   = Color(0xFFF0FDFA);

  // Surface & Neutral Colors
  static const Color white          = Colors.white;
  static const Color cardCream      = Colors.white;
  static const Color text           = Color(0xFF0F172A); // Dark Slate for high contrast
  static const Color textLight      = Color(0xFF475569); // Slate Grey
  static const Color mutedText      = Color(0xFF64748B);
  static const Color divider        = Color(0xFFE2E8F0);
  static const Color borderNavy     = Color(0xFFCBD5E1);

  // Accents & CTAs
  static const Color ctaOrange      = Color(0xFF0066CC); // CTA button in primary blue
  static const Color primary        = Color(0xFF0066CC);
  static const Color primaryLight   = Color(0xFFE0F2FE);
  static const Color secondary      = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFFBAE6FD);
  static const Color softYellow     = Color(0xFF0284C7);
  static const Color accentYellow   = Color(0xFF0284C7);
  static const Color coralRed       = Color(0xFFEF4444);
  static const Color mintGreen      = Color(0xFF0066CC);
  static const Color skyBlue        = Color(0xFF0EA5E9);
  static const Color success        = Color(0xFF0066CC);
  static const Color warning        = Color(0xFF0284C7);
  static const Color error          = Color(0xFFEF4444);
  static const Color background     = softBlueBg;
  static const Color surface        = Colors.white;
  static const Color cardBg         = Colors.white;
  static const Color jewelNavy      = softBlueBg;
  static const Color jewelEmerald   = softBlueBg;
  static const Color jewelTeal      = softBlueBg;
  static const Color jewelPurple    = softBlueBg;
  static const Color deepNavy       = Color(0xFF0F172A);

  static const Color component1Green    = c1Blue;
  static const Color component2Lavender = c2Blue;
  static const Color component3Yellow   = c3Blue;
  static const Color component4Orange   = c4Blue;
  static const Color gradient1          = Color(0xFF0066CC);
  static const Color gradient2          = Color(0xFF0284C7);

  // Component Backdrops (Blue Gradients for light theme)
  static const LinearGradient c1Gradient = LinearGradient(
    colors: [Color(0xFFEBF4FD), Color(0xFFDCEBFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient c2Gradient = LinearGradient(
    colors: [Color(0xFFEFF3FD), Color(0xFFDFE7FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient c3Gradient = LinearGradient(
    colors: [Color(0xFFEBF8FE), Color(0xFFD6F0FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient c4Gradient = LinearGradient(
    colors: [Color(0xFFEBF5FB), Color(0xFFD5EBF8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient homeGradient = LinearGradient(
    colors: [Color(0xFFF0F7FF), Color(0xFFE8F2FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF0F7FF),
      fontFamily: 'Outfit',
      fontFamilyFallback: const ['Noto Sans Sinhala', 'Roboto', 'sans-serif'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0066CC),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066CC),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0xFF0066CC).withValues(alpha: 0.25),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
    height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
    height: 1.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0066CC),
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: Color(0xFF0F172A),
    height: 1.4,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: Color(0xFF475569),
    height: 1.3,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Color(0xFF64748B),
  );
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF0F172A),
  );
}
