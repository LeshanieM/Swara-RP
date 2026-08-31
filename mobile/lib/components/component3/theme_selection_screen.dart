import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ඔබේ චාරිකාව තෝරන්න 🌈',
          style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose Your Adventure 🌈',
                style: TextStyle(fontSize: 20, color: AppColors.textLight, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _ThemeCard(
                      titleSi: 'වනාන්තර චාරිකාව',
                      titleEn: 'Jungle Adventure 🌴',
                      color: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      icon: Icons.park,
                      onTap: () => _selectTheme(context, 'jungle'),
                    ),
                    _ThemeCard(
                      titleSi: 'මුහුදු ලෝකය',
                      titleEn: 'Ocean Adventure 🌊',
                      color: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      icon: Icons.water,
                      onTap: () => _selectTheme(context, 'ocean'),
                    ),
                    _ThemeCard(
                      titleSi: 'අභ්‍යවකාශ චාරිකාව',
                      titleEn: 'Space Adventure 🚀',
                      color: const Color(0xFFEDE7F6),
                      iconColor: const Color(0xFF4527A0),
                      icon: Icons.rocket_launch,
                      onTap: () => _selectTheme(context, 'space'),
                    ),
                    _ThemeCard(
                      titleSi: 'මායා ලෝකය',
                      titleEn: 'Magical Kingdom 🏰',
                      color: const Color(0xFFFCE4EC),
                      iconColor: const Color(0xFFC2185B),
                      icon: Icons.castle,
                      onTap: () => _selectTheme(context, 'magic'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTheme(BuildContext context, String themeId) {
    context.push('/c3/plan', extra: themeId);
  }
}

class _ThemeCard extends StatelessWidget {
  final String titleSi;
  final String titleEn;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.titleSi,
    required this.titleEn,
    required this.color,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: iconColor.withValues(alpha: 0.3), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: iconColor.withValues(alpha: 0.1),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleSi,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titleEn,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
