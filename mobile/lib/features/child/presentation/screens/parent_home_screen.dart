import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import '../../data/models/child_model.dart';
import '../../../auth/data/providers/auth_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/storage/storage_service.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final childrenAsync = ref.watch(childNotifierProvider);
    final isDemoMode = StorageService.isDemoMode();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradient1, AppColors.gradient2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          radius: 22,
                          child: Text(
                            (user?.name ?? 'P').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user?.name?.split(' ').first ?? 'Parent'}! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Swara Parent Dashboard',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: const [],
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Children Profiles', style: AppTextStyles.heading3),
                  TextButton.icon(
                    onPressed: () => context.push('/parent/add-child'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Child'),
                  ),
                ],
              ),
            ),
          ),
          childrenAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: SwaraLoadingWidget(message: 'Loading children...'),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: SwaraErrorWidget(
                message: 'Failed to load children.',
                onRetry: () => ref.read(childNotifierProvider.notifier).loadChildren(),
              ),
            ),
            data: (children) {
              if (children.isEmpty) {
                return SliverToBoxAdapter(
                  child: SwaraEmptyState(
                    title: 'No Children Added',
                    subtitle: 'Add a child profile to get started.',
                    icon: Icons.child_care,
                    action: SwaraButton(
                      label: 'Add Child',
                      onPressed: () => context.push('/parent/add-child'),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ChildCard(child: children[i]),
                    childCount: children.length,
                  ),
                ),
              );
            },
          ),
          // Quick Actions
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.mic,
                          label: 'Speech\nAssessment',
                          color: AppColors.primary,
                          onTap: () {
                            final children = ref.read(childNotifierProvider).valueOrNull;
                            if (children != null && children.isNotEmpty) {
                              context.push('/speech/record/${children.first.childId}');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.psychology,
                          label: 'Support\nQuestionnaire',
                          color: AppColors.secondary,
                          onTap: () {
                            final children = ref.read(childNotifierProvider).valueOrNull;
                            if (children != null && children.isNotEmpty) {
                              context.push('/psychology/questionnaire/${children.first.childId}');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.trending_up,
                          label: 'View\nProgress',
                          color: AppColors.success,
                          onTap: () {
                            final children = ref.read(childNotifierProvider).valueOrNull;
                            if (children != null && children.isNotEmpty) {
                              context.push('/progress/${children.first.childId}');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildModel child;

  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/parent/child/${child.childId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradient1, AppColors.gradient2],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  child.firstName.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(child.firstName, style: AppTextStyles.heading3),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          child.childId,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Age: ${child.age}', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      SeverityChip(severity: child.severityDisplay),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    child.stutterTypeDisplay,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (child.communicationScore != null) ...[
                  Text(
                    '${child.communicationScore!.toStringAsFixed(1)}',
                    style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
                  ),
                  const Text('Comm.', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                ],
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
