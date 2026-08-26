import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';

class SupportResultScreen extends ConsumerWidget {
  final Map<String, dynamic> result;

  const SupportResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = (result['score'] as num?)?.toDouble() ?? 0.0;
    final level = result['level'] as String? ?? 'Medium';
    final supportAreas = List<Map<String, dynamic>>.from(result['supportAreas'] ?? []);
    final guidance = result['caregiverGuidance'] as String? ?? '';
    final childId = result['childId'] as String? ?? '';

    Color levelColor;
    String levelMessage;
    switch (level) {
      case 'Low':
        levelColor = AppColors.error;
        levelMessage = 'Needs more support';
        break;
      case 'Medium':
        levelColor = AppColors.warning;
        levelMessage = 'Some areas to focus on';
        break;
      case 'High':
        levelColor = AppColors.success;
        levelMessage = 'Good overall';
        break;
      default:
        levelColor = AppColors.textLight;
        levelMessage = '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const DisclaimerBanner(
              message: 'These are supportive suggestions and not psychological treatment or diagnosis.',
            ),
            const SizedBox(height: 16),

            // Main score card
            SwaraGradientCard(
              colors: [const Color(0xFF7C83FD), const Color(0xFF5B5FEF)],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Psychological & Behavioral\nSupport Indicator',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const Text(
                        ' / 100',
                        style: TextStyle(color: Colors.white60, fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$level Support Level',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Support Areas
            Text('Support Areas', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ...supportAreas.map((area) => _SupportAreaCard(area: area)),

            const SizedBox(height: 16),
            // Caregiver Guidance
            SwaraCard(
              color: AppColors.primaryLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Caregiver Guidance', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(guidance, style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SwaraButton(
              label: 'View Therapy Recommendations',
              onPressed: childId.isNotEmpty ? () => context.push('/therapy/recommendations/$childId') : null,
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 10),
            SwaraButton(
              label: 'Done',
              outlined: true,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SupportAreaCard extends StatelessWidget {
  final Map<String, dynamic> area;

  const _SupportAreaCard({required this.area});

  @override
  Widget build(BuildContext context) {
    final areaName = area['area'] as String? ?? '';
    final areaScore = (area['score'] as num?)?.toInt() ?? 0;
    final suggestions = List<String>.from(area['suggestions'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(areaName, style: AppTextStyles.label),
              Text(
                '$areaScore/100',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: areaScore / 100,
              backgroundColor: AppColors.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Text('Suggested Activities:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(s, style: AppTextStyles.bodySmall)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
