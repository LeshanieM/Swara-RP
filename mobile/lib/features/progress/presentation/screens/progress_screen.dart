import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';
import '../../data/providers/progress_provider.dart';

/// The active child's progress; the clinical summary reads each component's summary on the API.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(clinicalSummaryProvider).valueOrNull;
    final overall = ref.watch(overallProgressProvider).valueOrNull;
    final (verdictEmoji, verdictSi, verdictEn) = switch (overall?.status) {
      'improved' => ('🌟', 'ඔයා දියුණු වෙලා!', 'Improved: stuttering is going down'),
      'needs_attention' => ('💛', 'අපි තව ටිකක් පුහුණු වෙමු', 'Needs attention: stuttering went up lately'),
      'no_clear_change' => ('🌱', 'ඔයා දිගටම පුහුණු වෙනවා', 'No clear change yet'),
      'insufficient_data' => ('🌱', 'තව කතා කරමු!', 'Not enough sessions yet to tell'),
      _ => ('🌱', 'ප්‍රගතිය', 'Progress could not be loaded'),
    };
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.homeGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primary, size: 28),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏆 මගේ ප්‍රගතිය (My Progress)',
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('මගේ කතා ගමනේ ප්‍රගතිය (My Speech Adventure)',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.primary),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.softYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softYellow.withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/common/user_pic.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('මගේ ගමන 🌱 (My Journey)',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 12)
                    ],
                  ),
                  // The overall verdict from all four components (GET /api/children/:id/progress).
                  child: Row(
                    children: [
                      Text(verdictEmoji, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              verdictSi,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text),
                            ),
                            Text(
                              verdictEn,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textLight),
                            ),
                            for (final r in overall?.reasons ?? const <String>[])
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('• $r', style: const TextStyle(fontSize: 12, color: AppColors.text)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Earned achievements are bright; the others are greyed until the child earns them.
                _buildAchievement(
                  'පළමු පියවර',
                  'First Steps',
                  'ඔයා ඔයාගේ පළමු ක්‍රියාකාරකම අවසන් කළා!',
                  '🌟',
                  AppColors.softYellow,
                  earned: overall?.firstSteps ?? false,
                ),
                _buildAchievement(
                  'දින 3 ක අඛණ්ඩ ගමන',
                  '3-Day Streak',
                  'ඔයා දින 3 ක් දිගටම පුහුණු වුණා!',
                  '🔥',
                  AppColors.coralRed,
                  earned: overall?.threeDayStreak ?? false,
                ),
                _buildAchievement(
                  'කතා කරන යාළුවා',
                  'Speech Buddy',
                  'ඔයා කථන ක්‍රියාකාරකම් 5 ක් අවසන් කළා!',
                  '🏆',
                  AppColors.ctaOrange,
                  earned: overall?.speechBuddy ?? false,
                ),
                const SizedBox(height: 32),
                const Text('සායනික ප්‍රගති සාරාංශය (Clinical Summary)',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text)),
                const SizedBox(height: 16),
                _buildComponentsSummary(summary),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('තවත් ක්‍රියාකාරකම් කරමු',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('(More Activities)',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievement(String titleSi, String titleEn, String descSi,
      String emoji, Color color, {bool earned = true}) {
    return Opacity(opacity: earned ? 1 : 0.4, child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(titleSi,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text)),
                    const SizedBox(width: 6),
                    Text('($titleEn)',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(descSi,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textLight)),
              ],
            ),
          )
        ],
      ),
    ));
  }

  Widget _buildComponentsSummary(ClinicalSummary? s) {
    const loading = '...';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primaryLight, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          _buildComponentRow('Component 1', 'Fluency / Stuttering', s?.c1 ?? loading),
          const Divider(height: 24),
          _buildComponentRow(
              'Component 2', 'Secondary behaviours', s?.c2 ?? loading),
          const Divider(height: 24),
          _buildComponentRow('Component 3', 'Therapy Activity', s?.c3 ?? loading),
          const Divider(height: 24),
          _buildComponentRow('Component 4', 'Language Characteristics',
              s?.c4 ?? loading),
        ],
      ),
    );
  }

  Widget _buildComponentRow(String comp, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(comp,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14, color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }
}
