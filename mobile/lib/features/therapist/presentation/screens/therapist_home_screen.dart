import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/storage/storage_service.dart';

class TherapistHomeScreen extends ConsumerWidget {
  const TherapistHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final childrenAsync = ref.watch(childNotifierProvider);
    final isDemoMode = StorageService.isDemoMode();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3730A3), Color(0xFF5B5FEF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.record_voice_over, color: Colors.white54, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'Dr. ${user?.name?.split(' ').last ?? 'Therapist'}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text('Speech & Language Therapist', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (isDemoMode) const DemoModeBanner(),
                const DisclaimerBanner(),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: childrenAsync.when(
                loading: () => const SwaraLoadingWidget(message: 'Loading dashboard...'),
                error: (_, __) => const SwaraErrorWidget(message: 'Failed to load data.'),
                data: (children) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Total Children',
                            value: '${children.length}',
                            icon: Icons.child_care,
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            label: 'Active Sessions',
                            value: '${children.where((c) => c.severity != null).length}',
                            icon: Icons.play_circle_outline,
                            iconColor: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Pending Reviews',
                            value: '${children.where((c) => (c.communicationScore ?? 0) < 6).length}',
                            icon: Icons.pending_actions,
                            iconColor: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/therapist/knowledge-base'),
                            child: const StatCard(
                              label: 'Knowledge Base',
                              value: 'Manage',
                              icon: Icons.library_books,
                              iconColor: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Assigned Children', style: AppTextStyles.heading3),
                        TextButton(
                          onPressed: () => context.push('/therapist/knowledge-base'),
                          child: const Text('Knowledge Base →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...children.map((child) => _TherapistChildCard(
                          childId: child.childId,
                          name: child.firstName,
                          age: child.age,
                          severity: child.severityDisplay,
                          stutterType: child.stutterTypeDisplay,
                          supportScore: child.supportIndicator,
                          commScore: child.communicationScore,
                          onTap: () => context.push('/therapist/child/${child.childId}'),
                        )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapistChildCard extends StatelessWidget {
  final String childId;
  final String name;
  final int age;
  final String severity;
  final String stutterType;
  final double? supportScore;
  final double? commScore;
  final VoidCallback onTap;

  const _TherapistChildCard({
    required this.childId,
    required this.name,
    required this.age,
    required this.severity,
    required this.stutterType,
    required this.onTap,
    this.supportScore,
    this.commScore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: AppTextStyles.label),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              childId,
                              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Age: $age • $stutterType', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                SeverityChip(severity: severity),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _ScoreTag(
                  label: 'Support Indicator',
                  value: supportScore != null ? '${supportScore!.toInt()}/100' : 'N/A',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 10),
                _ScoreTag(
                  label: 'Communication',
                  value: commScore != null ? '${commScore!.toStringAsFixed(1)}/10' : 'N/A',
                  color: AppColors.primary,
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTag extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreTag({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
