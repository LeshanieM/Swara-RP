import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'models/activity_model.dart';

class SlpSummaryScreen extends StatelessWidget {
  final Map<String, int> results;
  final List<ActivityModel> activities;
  final String themeId;

  const SlpSummaryScreen({
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
      appBar: AppBar(
        title: const Text('සැසි සාරාංශය (Session Summary)'),
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
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.divider)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Assessment Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
                      SizedBox(height: 8),
                      Text('Age: 10'),
                      Text('Severity: Moderate'),
                      Text('Primary Type: Repetition'),
                      SizedBox(height: 8),
                      Text('Physical Behavior Score: 61'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.divider)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Activities Completed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${activities.length} / 4', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Activity Performance', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      ...activities.map((act) {
                        final score = results[act.id] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(act.nameEn)),
                              Text('$score', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Overall Activity Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('$totalScore / 100', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: Text('Selected Theme: $themeId', style: const TextStyle(color: AppColors.textLight)),
              ),
              
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Return to Home', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
