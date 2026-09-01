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
                        Text('🏆 My Progress', style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('My Speech Adventure Progress', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ],
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
                const Text('My Journey 🌱', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
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
                              'You spoke longer today than last time!',
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
                  'First Steps',
                  'First Steps',
                  'You completed your first activity!',
                  '🌟',
                  AppColors.softYellow,
                ),
                _buildAchievement(
                  '3-Day Streak',
                  '3-Day Streak',
                  'You practiced 3 days in a row!',
                  '🔥',
                  AppColors.coralRed,
                ),
                _buildAchievement(
                  'Speech Buddy',
                  'Speech Buddy',
                  'You completed 5 speech activities!',
                  '🏆',
                  AppColors.ctaOrange,
                ),

                const SizedBox(height: 32),
                const Text('Clinical Progress Summary', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text)),
                const SizedBox(height: 16),
                _buildComponentsSummary(),

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
                        Text('Let\'s Do More Activities', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildComponentsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primaryLight, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Column(
        children: [
          _buildComponentRow('Component 1', 'Fluency / Stuttering', 'Moderate'),
          const Divider(height: 24),
          _buildComponentRow('Component 2', 'Secondary Behaviors', 'Mild–Moderate'),
          const Divider(height: 24),
          _buildComponentRow('Component 3', 'Therapy Activity', 'Storytelling'),
          const Divider(height: 24),
          _buildComponentRow('Component 4', 'Language Characteristics', 'Increasing lexical diversity'),
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
          child: Text(comp, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }
}