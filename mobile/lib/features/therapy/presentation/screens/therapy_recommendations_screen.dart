import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/features/therapy/data/providers/therapy_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';

class TherapyRecommendationsScreen extends ConsumerWidget {
  final String childId;

  const TherapyRecommendationsScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(therapyRecommendationsProvider(childId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapy Recommendations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: recAsync.when(
        loading: () => const SwaraLoadingWidget(message: 'Preparing personalized therapy...'),
        error: (e, _) => SwaraErrorWidget(
          message: 'Failed to load recommendations.',
          onRetry: () => ref.invalidate(therapyRecommendationsProvider(childId)),
        ),
        data: (rec) {
          final theme = rec['theme'] as String? ?? 'Animal Adventure';
          final activities = List<Map<String, dynamic>>.from(rec['activities'] ?? []);
          final sessionId = rec['sessionId'] as String? ?? 'session_001';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DisclaimerBanner(
                  message: 'Therapy activity suggestions — from a therapist-defined knowledge base.',
                ),
                const SizedBox(height: 16),

                // Theme card
                SwaraGradientCard(
                  child: Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personalized Therapy Session',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              theme,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('Suggested Activities (${activities.length})', style: AppTextStyles.heading3),
                const SizedBox(height: 12),
                ...activities.asMap().entries.map(
                      (e) => _ActivityCard(
                        index: e.key + 1,
                        activity: e.value,
                      ),
                    ),
                const SizedBox(height: 20),

                SwaraCard(
                  color: AppColors.primaryWash,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These activities are selected from a therapist-validated knowledge base '
                          'based on the child\'s age, severity, and interests.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SwaraButton(
                  label: 'Start Storybook Therapy',
                  icon: Icons.auto_stories,
                  onPressed: () {
                    // Start session then navigate
                    ref.read(therapyNotifierProvider(childId).notifier).startSession(activities);
                    context.push('/therapy/storybook/$sessionId');
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.index, required this.activity});

  Color _difficultyColor(String? d) {
    switch (d) {
      case 'Beginner':
        return AppColors.success;
      case 'Intermediate':
        return AppColors.warning;
      case 'Advanced':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = activity['name'] as String? ?? '';
    final desc = activity['description'] as String? ?? '';
    final difficulty = activity['difficulty'] as String? ?? '';
    final duration = activity['duration'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _difficultyColor(difficulty).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: _difficultyColor(difficulty),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${duration}m', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
