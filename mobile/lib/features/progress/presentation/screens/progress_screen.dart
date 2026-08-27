import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  final String childId;
  const ProgressScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
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
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 28),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏆 මගේ ප්‍රගතිය', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('My Speech Adventure Progress', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softYellow,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.softYellow.withOpacity(0.5), blurRadius: 15)],
                  ),
                  child: const Text('🦊', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 12),
                const Text('මගේ ගමන 🌱 / My Journey', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardCream,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                  ),
                  child: const Row(
                    children: [
                      Text('🌟', style: TextStyle(fontSize: 40)),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'පසුගිය වතාවට වඩා අද වැඩි වෙලාවක් කතා කළා!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
                            ),
                            Text(
                              'Spoke longer today than last session!',
                              style: TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildAchievement(
                  'පළමු පියවර',
                  'First Steps',
                  'ඔයාගේ පළමු ක්‍රියාකාරකම කළා!',
                  '🌟',
                  AppColors.softYellow,
                ),
                _buildAchievement(
                  'දින 3ක්',
                  '3-Day Streak',
                  'දවස් 3ක් එක දිගට පුහුණු වුණා!',
                  '🔥',
                  AppColors.coralRed,
                ),
                _buildAchievement(
                  'කතා මිතුරා',
                  'Speech Buddy',
                  'කතා ක්‍රියාකාරකම් 5ක් කළා!',
                  '🏆',
                  AppColors.ctaOrange,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('තව ක්‍රියාකාරකම් කරමු', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text('/ Continue Quests', style: TextStyle(fontSize: 12, color: Colors.white70)),
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

  Widget _buildAchievement(String titleSi, String titleEn, String descSi, String emoji, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(titleSi, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text)),
                    const SizedBox(width: 6),
                    Text('($titleEn)', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(descSi, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
