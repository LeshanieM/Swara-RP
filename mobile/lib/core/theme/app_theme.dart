import 'package:flutter/material.dart';

class AppColors {
  // Kids' Adventure Learning Palette
  static const Color ctaOrange = Color(0xFFFF9F1C); // Warm golden-orange CTA button
  static const Color jewelNavy = Color(0xFF1A1B4B); // Deep navy backdrop
  static const Color jewelEmerald = Color(0xFF064E3B); // Forest / Emerald backdrop
  static const Color jewelTeal = Color(0xFF0F4C5C); // Deep Teal backdrop
  static const Color jewelPurple = Color(0xFF311042); // Deep Purple backdrop

  static const Color cardCream = Color(0xFFFFFDF6); // Cream card surface
  static const Color softYellow = Color(0xFFFFD166); // Stars & Badges
  static const Color coralRed = Color(0xFFEF476F); // Mic / Record accent
  static const Color skyBlue = Color(0xFF118AB2); // Accent blue
  static const Color mintGreen = Color(0xFF06D6A0); // Mint green accent

  // Component Backdrops (Gradients)
  static const LinearGradient c1Gradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF047857)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient c2Gradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient c3Gradient = LinearGradient(
    colors: [Color(0xFF311042), Color(0xFF581C87)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient c4Gradient = LinearGradient(
    colors: [Color(0xFF0F4C5C), Color(0xFF134E5E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient homeGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Backward compatibility mappings
  static const Color primary = ctaOrange;
  static const Color deepNavy = jewelNavy;
  static const Color component1Green = mintGreen;
  static const Color component2Lavender = Color(0xFFAEB8F0);
  static const Color component3Yellow = softYellow;
  static const Color component4Orange = ctaOrange;
  static const Color accentYellow = softYellow;
  static const Color white = Colors.white;
  static const Color mutedText = Color(0xFF64748B);
  static const Color borderNavy = Color(0xFF1B1B3A);

  static const Color secondary = softYellow;
  static const Color background = jewelNavy;
  static const Color surface = cardCream;
  static const Color text = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color success = mintGreen;
  static const Color warning = ctaOrange;
  static const Color error = coralRed;
  static const Color cardBg = cardCream;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color primaryLight = Color(0xFFFFEDD5);
  static const Color secondaryLight = Color(0xFFFEF3C7);
  static const Color gradient1 = Color(0xFF1E1B4B);
  static const Color gradient2 = Color(0xFF3730A3);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.jewelNavy,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctaOrange,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.ctaOrange.withOpacity(0.5),
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill-shaped CTAs
          ),
          textStyle: const TextStyle(
            fontSize: 20,
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
    color: Colors.white,
    height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
    height: 1.4,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
    height: 1.3,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
}
