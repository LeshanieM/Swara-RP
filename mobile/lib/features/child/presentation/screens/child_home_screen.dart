import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final rawName = user?.name.trim();
    final childName = (rawName != null &&
            rawName.isNotEmpty &&
            rawName.toLowerCase() != 'child')
        ? rawName.split(' ').first
        : 'Aseliya';

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // =========================
            // HEADER
            // =========================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildFixedHeader(context, childName),
            ),

            // ============================================================
            // SCROLLABLE CONTENT BODY
            // ============================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================================
                    // 3. SECTION TITLE - Compact
                    // ============================================================
                    Text(
                      'අද ගවේෂණය',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a practice for today',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    // ============================================================
                    // 4. COMPONENT CARDS - ILLUSTRATED, COLOR-CODED SET
                    // ============================================================
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                      children: [
                        // Card 1: Royal / Electric Blue — hero action
                        _CompactAdventureCard(
                          icon: Icons.mic_rounded,
                          imageAsset: 'images/home/talk_card.png',
                          titleSi: 'කතා කරමු',
                          titleEn: "Let's Talk",
                          subtitle: 'Reading and picture practice',
                          accentColor: const Color(0xFF3B82F6),
                          onAccentColor: Colors.white,
                          onTap: () => context.push('/c1/record'),
                        ),
                        // Card 2: Teal / Aqua — visual feedback
                        _CompactAdventureCard(
                          icon: Icons.videocam_rounded,
                          imageAsset: 'images/home/camera_card.png',
                          titleSi: 'කතා කරන විදිහ',
                          titleEn: 'Camera Fun',
                          subtitle: 'Watch how speech looks',
                          accentColor: const Color(0xFF0FA3A3),
                          onAccentColor: Colors.white,
                          onTap: () => context.push('/c2/upload'),
                        ),
                        // Card 3: Warm Amber — guided storytelling
                        _CompactAdventureCard(
                          icon: Icons.auto_stories_rounded,
                          imageAsset: 'images/home/story_card.png',
                          titleSi: 'ක්‍රියාකාරකම්',
                          titleEn: 'Story Time',
                          subtitle: 'Guided, slower practice',
                          accentColor: const Color(0xFFE08A2E),
                          onAccentColor: Colors.white,
                          onTap: () => context.push('/c3/theme'),
                        ),
                        // Card 4: Violet — open expression
                        _CompactAdventureCard(
                          icon: Icons.forum_rounded,
                          imageAsset: 'images/home/free_talk_card.png',
                          titleSi: 'නිදහසේ කතා',
                          titleEn: 'Free Talk',
                          subtitle: 'Speak on a topic you like',
                          accentColor: const Color(0xFF7C5CE0),
                          onAccentColor: Colors.white,
                          onTap: () => context.push('/c4/task'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Forest Adventure Speech Therapy Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/c3/forest-therapy'),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0066CC), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066CC).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Text('🌲', style: TextStyle(fontSize: 26)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Forest Adventure Speech Therapy',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Open 18-Screen Adventure Journey (6 Themes)',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Progress Card - Now matches the adventure cards
                    Material(
                      color: AppColors.surfaceRaised,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        side: const BorderSide(color: AppColors.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/profile'),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        overlayColor: WidgetStateProperty.all(
                          AppColors.primaryDeep.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryWash,
                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_outlined,
                                  color: AppColors.primaryDeep,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'මගේ ගමන',
                                      style: AppTextStyles.heading3.copyWith(
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'My progress',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.primaryDeep,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Track your journey',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textLight,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Footer text
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                      child: Text(
                        'ඔබට ඕනෑම ක්‍රියාකාරකමක් තෝරා ගත හැකියි.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context, String childName) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: const Icon(
            Icons.record_voice_over_rounded,
            color: AppColors.onPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ස්වර',
                style: AppTextStyles.heading3
                    .copyWith(color: AppColors.primaryDeep)),
            Text('Speech support', style: AppTextStyles.caption),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: AppRadii.smAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(childName, style: AppTextStyles.label),
                  Text('Practice',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryWash,
                foregroundImage:
                    const AssetImage('assets/images/common/user_pic.jpg'),
                onForegroundImageError: (_, __) {},
                child: const Icon(Icons.face_rounded,
                    color: AppColors.primaryDeep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single "adventure" card used on the child home screen.
///
/// All cards share the exact same shape, spacing, and type scale so
/// they read as one cohesive family — the only things that vary are the
/// accent color, illustration, and copy.
class _CompactAdventureCard extends StatelessWidget {
  final IconData icon;
  final String imageAsset;
  final String titleSi;
  final String titleEn;
  final String subtitle;
  final Color accentColor;
  final Color onAccentColor;
  final VoidCallback onTap;
  final bool emphasized;

  const _CompactAdventureCard({
    required this.icon,
    required this.imageAsset,
    required this.titleSi,
    required this.titleEn,
    required this.subtitle,
    required this.accentColor,
    required this.onAccentColor,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised, // All cards now have the same background
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: AppColors.divider, // All cards now have the same border
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStateProperty.all(
          accentColor.withValues(alpha: 0.08), // All cards use the same ripple effect
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Illustration band ----
            // Every card reserves the same fixed-ratio image band at the
            // top; only the artwork and its tint differ.
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background tint - now consistent across all cards
                  Container(
                    color: accentColor.withValues(alpha: 0.12),
                  ),
                  Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        icon,
                        size: 34,
                        color: accentColor,
                      ),
                    ),
                  ),
                  // Icon badge - now consistent across all cards
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: onAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Text block ----
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleSi,
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.text, // All cards use the same text color
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titleEn,
                          style: AppTextStyles.label.copyWith(
                            color: accentColor, // Only the subtitle label shows accent color
                          ),
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textLight, // All cards use the same caption color
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}