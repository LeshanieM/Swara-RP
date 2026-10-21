import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/services/c4_flow.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final v = C4Flow.view;
    final duration = fmtClock(v.durationSec);
    final mlu = v.mlu == null ? '—' : v.mlu!.toStringAsFixed(1);
    return Scaffold(
      backgroundColor: AppColors.groundHome,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 12, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'සන්නිවේදන හා භාෂා ප්‍රතිඵල',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'සන්නිවේදන හා භාෂා ප්‍රතිඵල',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    _buildResultCard(
                      value: mlu,
                      unit: 'වචන / ප්‍රකාශනය',
                      titleSi: 'සාමාන්‍ය ප්‍රකාශන දිග',
                      description: 'එක් ප්‍රකාශනයක සාමාන්‍ය වචන ගණන.',
                      icon: Icons.linear_scale,
                    ),
                    const SizedBox(height: 16),
                    _buildResultCard(
                      value: '${v.ndw}',
                      unit: 'වෙනස් වචන',
                      titleSi: 'වෙනස් වචන ගණන',
                      description: 'පිළිතුරේ භාවිත කළ වෙනස් වචන ගණන.',
                      icon: Icons.abc,
                    ),
                    const SizedBox(height: 16),
                    _buildResultCard(
                      value: v.percentSS == null ? '—' : v.percentSS!.toStringAsFixed(1),
                      unit: v.percentSS == null ? 'ඇගයීමට ලක් කර නැත' : 'අක්ෂරවලින් %',
                      titleSi: 'පැකිළුණු අක්ෂර ප්‍රතිශතය',
                      description: 'C1 විශ්ලේෂණයට අනුව අක්ෂර 100කට පැකිළුණු අක්ෂර ගණන.',
                      icon: Icons.graphic_eq,
                    ),
                    const SizedBox(height: 16),
                    _buildResultCard(
                      value: duration,
                      unit: '',
                      titleSi: 'පිළිතුරු කාලය',
                      description: 'ස්වභාවිකව කතා කළ පිළිතුරේ කාලය.',
                      icon: Icons.timer,
                    ),

                    const SizedBox(height: 32),
                    if (v.utterances < 5)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'මෙවර වාක්‍ය 5කට අඩුයි. ඊළඟ වතාවේ තව ටිකක් කතා කරමු.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (v.flags.contains('unreliable_sample') || v.flags.contains('short_sample'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'පිළිතුර වචන 50කට අඩු නිසා මෙම මිනුම්වල විශ්වාසනීයත්වය අඩු විය හැකියි.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Text('මෙම සැසිය', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: AppRadii.lgAll,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildStatItem('${v.utterances}${v.utterances < 5 ? ' / 5' : ''}', 'ප්‍රකාශන'),
                          _buildStatItem('${v.totalWords}', 'මුළු වචන'),
                          _buildStatItem('${v.ndw}', 'වෙනස් වචන'),
                          _buildStatItem(mlu, 'MLU'),
                          _buildStatItem(duration, 'කාලය'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/comparison'),
                      child: const Text('සැසි සසඳන්න'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String value,
    required String unit,
    required String titleSi,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.mdAll,
        boxShadow: AppElevation.card,
        border: Border.all(color: AppColors.primaryWash, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 48),
          ),
          if (unit.isNotEmpty)
            Text(unit, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          const SizedBox(height: 16),
          Text(titleSi, style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTextStyles.heading2.copyWith(color: AppColors.text)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
