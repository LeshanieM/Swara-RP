import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../child/data/providers/child_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';

class TherapistChildDetailScreen extends ConsumerWidget {
  final String childId;

  const TherapistChildDetailScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(childProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('Child Detail')),
      body: childAsync.when(
        loading: () => const SwaraLoadingWidget(message: 'Loading...'),
        error: (_, __) => const SwaraErrorWidget(message: 'Failed to load.'),
        data: (child) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwaraGradientCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/common/user_pic.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Text(
                              child.firstName.substring(0, 1),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.firstName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('${child.childId} • Age ${child.age}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    SeverityChip(severity: child.severityDisplay),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section('Profile'),
              _row('Stutter Type', child.stutterTypeDisplay),
              _row('Interests', child.interests.join(', ')),
              _row('Severity', child.severityDisplay),
              const SizedBox(height: 12),
              _section('Scores'),
              _row('Support Indicator', child.supportIndicator != null ? '${child.supportIndicator!.toInt()}/100' : 'N/A'),
              _row('Communication Score', child.communicationScore != null ? '${child.communicationScore!.toStringAsFixed(1)}/10' : 'N/A'),
              const SizedBox(height: 20),
              Text('Actions', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.mic,
                label: 'View Speech Assessments',
                onTap: () => context.push('/speech/record/${child.childId}'),
              ),
              _ActionTile(
                icon: Icons.psychology,
                label: 'View Behavioral Assessment',
                onTap: () => context.push('/psychology/questionnaire/${child.childId}'),
              ),
              _ActionTile(
                icon: Icons.face_retouching_natural,
                label: 'Component 2 (Secondary Behaviors)',
                onTap: () => context.push('/concomitant/dashboard/${child.childId}'),
              ),
              _ActionTile(
                icon: Icons.auto_awesome,
                label: 'Therapy Recommendations',
                onTap: () => context.push('/therapy/recommendations/${child.childId}'),
              ),
              _ActionTile(
                icon: Icons.trending_up,
                label: 'Progress Dashboard',
                onTap: () => context.push('/progress/${child.childId}'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(title, style: AppTextStyles.heading3),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
          ],
        ),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTextStyles.label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
    );
  }
}
