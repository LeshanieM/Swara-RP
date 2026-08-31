import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';

class ChildProfileScreen extends ConsumerWidget {
  final String childId;

  const ChildProfileScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(childProvider(childId));

    return Scaffold(
      body: childAsync.when(
        loading: () => const SwaraLoadingWidget(message: 'Loading profile...'),
        error: (e, _) => SwaraErrorWidget(message: 'Failed to load child profile.'),
        data: (child) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.primaryDeep,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/common/user_pic.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Text(
                                child.firstName.isNotEmpty ? child.firstName.substring(0, 1) : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        child.firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        child.childId,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    const DisclaimerBanner(),
                    const SizedBox(height: 16),
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            label: 'Age',
                            value: '${child.age} yrs',
                            icon: Icons.cake_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            label: 'Severity',
                            value: child.severityDisplay,
                            icon: Icons.bar_chart,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            label: 'Stutter Type',
                            value: child.stutterTypeDisplay,
                            icon: Icons.mic_outlined,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            label: 'Support Score',
                            value: child.supportIndicator != null
                                ? '${child.supportIndicator!.toInt()}/100'
                                : 'N/A',
                            icon: Icons.psychology_outlined,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            label: 'Comm. Score',
                            value: child.communicationScore != null
                                ? '${child.communicationScore!.toStringAsFixed(1)}/10'
                                : 'N/A',
                            icon: Icons.chat_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Interests
                    if (child.interests.isNotEmpty) ...[
                      SwaraCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite_outlined, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('Interests', style: AppTextStyles.heading3),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: child.interests
                                  .map((i) => Chip(
                                        label: Text(i),
                                        avatar: const Icon(Icons.star, size: 14, color: AppColors.primary),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Actions
                    Text('Start an Assessment', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.mic,
                      label: 'Speech Assessment',
                      subtitle: 'Record and analyze speech sample',
                      color: AppColors.primary,
                      onTap: () => context.push('/speech/record/${child.childId}'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.psychology,
                      label: 'Behavioral Questionnaire',
                      subtitle: 'Complete the caregiver questionnaire',
                      color: AppColors.secondary,
                      onTap: () => context.push('/psychology/questionnaire/${child.childId}'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.face_retouching_natural,
                      label: 'Component 2 (Secondary Behaviors)',
                      subtitle: 'Analyze physical and vocal indicators',
                      color: AppColors.primary,
                      onTap: () => context.push('/concomitant/dashboard/${child.childId}'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Therapy Recommendations',
                      subtitle: 'View personalized therapy activities',
                      color: AppColors.success,
                      onTap: () => context.push('/therapy/recommendations/${child.childId}'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.record_voice_over,
                      label: 'Communication Task',
                      subtitle: 'Post-therapy communication assessment',
                      color: AppColors.warning,
                      onTap: () => context.push('/communication/task/${child.childId}'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.trending_up,
                      label: 'Progress Dashboard',
                      subtitle: 'View charts and progress history',
                      color: AppColors.primary,
                      onTap: () => context.push('/progress/${child.childId}'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.label),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
