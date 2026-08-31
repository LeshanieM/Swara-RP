import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'models/activity_model.dart';

class FinalScoreScreen extends StatelessWidget {
  final Map<String, int> results;
  final List<ActivityModel> activities;
  final String themeId;

  const FinalScoreScreen({
    super.key,
    required this.results,
    required this.activities,
    required this.themeId,
  });

  @override
  Widget build(BuildContext context) {
    int totalScore = 0;
    if (results.isNotEmpty) {
      totalScore = (results.values.fold(0, (sum, score) => sum + score) / results.length).round();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                '🏆 🎉 ⭐',
                style: TextStyle(fontSize: 60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'චාරිකාව සම්පූර්ණයි! 🏆',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDeep),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Adventure Complete!',
                style: TextStyle(fontSize: 20, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.divider),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'සමස්ත ක්‍රියාකාරීත්ව ලකුණු',
                        style: TextStyle(fontSize: 18, color: AppColors.textLight),
                      ),
                      const Text(
                        'Overall Activity Performance',
                        style: TextStyle(fontSize: 16, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$totalScore / 100',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryDeep),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '4 / 4 Activities Completed',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: () {
                  context.pushReplacement('/c3/summary', extra: {
                    'results': results,
                    'activities': activities,
                    'themeId': themeId,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Finish', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
