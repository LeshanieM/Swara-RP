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
            // HEADER — greeting banner
            // =========================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _buildGreetingBanner(context, childName),
            ),

            // ============================================================
            // SCROLLABLE CONTENT BODY
            // ============================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================================
                    // SECTION TITLE — with a friendly icon pill
                    // ============================================================
                    _buildSectionHeader(),
                    const SizedBox(height: 16),

                    // ============================================================
                    // COMPONENT CARDS — illustrated, color-coded, "sticker" set
                    // ============================================================
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                      children: [
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
                        _CompactAdventureCard(
                          icon: Icons.auto_stories_rounded,
                          imageAsset: 'images/home/story_card.png',
                          titleSi: 'කතා පුහුණුව',
                          titleEn: 'Therapy Journey',
                          subtitle: 'Guided speech practice',
                          accentColor: const Color(0xFFE08A2E),
                          onAccentColor: Colors.white,
                          onTap: () => context.push('/c3/forest-therapy'),
                        ),
                        _CompactAdventureCard(
                          icon: Icons.forum_rounded,
                          imageAsset: 'images/home/free_talk_card.png',
                          titleSi: 'නිදහසේ කතා',
                          titleEn: 'Free Talk',
                          subtitle: 'Speak on a topic you like',
                          accentColor: const Color(0xFF7C5CE0),
                          onAccentColor: Colors.white,
                          onTap: () => context.push('/c4'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ============================================================
                    // PROGRESS CARD — celebratory banner instead of a plain row
                    // ============================================================
                    _buildProgressBanner(context),
                    const SizedBox(height: 16),

                    // ============================================================
                    // FOOTER TIP — speech-bubble style callout
                    // ============================================================
                    _buildFooterTip(),
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

  // ---------------------------------------------------------------------
  // GREETING BANNER — replaces the small corner name label with a warm,
  // front-and-center welcome. This is the first thing a child reads.
  // ---------------------------------------------------------------------
  Widget _buildGreetingBanner(BuildContext context, String childName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDeep.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hi, $childName! 👋',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('ස්වර · Ready to practice?', style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryWash,
                  foregroundImage:
                      const AssetImage('assets/images/common/user_pic.jpg'),
                  onForegroundImageError: (_, __) {},
                  child: const Icon(Icons.face_rounded,
                      color: AppColors.primaryDeep),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECTION HEADER — a small icon pill makes the title feel less like a
  // list heading and more like a signpost.
  // ---------------------------------------------------------------------
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.ctaOrange.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🧭', style: TextStyle(fontSize: 17)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('අද ගවේෂණය', style: AppTextStyles.heading3),
              Text('Pick a practice for today', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // PROGRESS BANNER — a celebratory gradient card instead of a flat row,
  // so checking progress feels rewarding rather than administrative.
  // ---------------------------------------------------------------------
  Widget _buildProgressBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/profile'),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.ctaOrange.withValues(alpha: 0.90),
                AppColors.ctaOrange.withValues(alpha: 0.70),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.ctaOrange.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.ctaOrange,
                  size: 30,
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
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'My progress',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'See how far you\'ve come!',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FOOTER TIP — a speech-bubble callout instead of plain gray text,
  // matching the app's conversational, friendly tone.
  // ---------------------------------------------------------------------
  Widget _buildFooterTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ඔබට ඕනෑම ක්‍රියාකාරකමක් තෝරා ගත හැකියි.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single "adventure" card used on the child home screen.
///
/// All cards share the exact same shape, spacing, and type scale so
/// they read as one cohesive family — the only things that vary are the
/// accent color, illustration, and copy. Cards now have a light "press"
/// animation and a colored glow so each one feels like a tappable sticker.
class _CompactAdventureCard extends StatefulWidget {
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
  State<_CompactAdventureCard> createState() => _CompactAdventureCardState();
}

class _CompactAdventureCardState extends State<_CompactAdventureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: AppColors.surfaceRaised,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Illustration band ----
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: widget.accentColor.withValues(alpha: 0.14),
                      ),
                      Image.asset(
                        widget.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            widget.icon,
                            size: 36,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                      // Circular icon badge — softer than the old square chip
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size: 18,
                            color: widget.onAccentColor,
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
                              widget.titleSi,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.text,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.titleEn,
                              style: AppTextStyles.label.copyWith(
                                color: widget.accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
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
        ),
      ),
    );
  }
}
