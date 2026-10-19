import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';

// Swara — dark-blue Calm Cub variant (see DESIGN.md §12)
const _groundHome    = Color(0xFFE6F4F1);
const _groundBreathe = Color(0xFFDCEEFA);
const _groundGarden  = Color(0xFFE4F3DC);
const _groundAdult   = Color(0xFFF2F6F5);

const _primary       = Color(0xFF1D4A87);
const _primaryTint   = Color(0xFFD9E6F7);

const _sun           = Color(0xFFFFC94A);
const _sunTint       = Color(0xFFFFF3CF);
const _lilacTint     = Color(0xFFDCD3F8);

const _ink           = Color(0xFF1E3A44);
const _inkMuted      = Color(0xFF3F5F6A);

const _fredoka       = 'Fredoka';
const _nunito        = 'Nunito';

/// Flat, gradient-free scene: soft circles, a small sun, three rolling hills.
/// Matches DESIGN.md §6 — the shared background for tab screens.
class _CalmScenePainter extends CustomPainter {
  final Color base;
  const _CalmScenePainter({required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Paint p(Color c) => Paint()..color = c;

    canvas.drawRect(Offset.zero & size, p(base));

    canvas.drawCircle(Offset(w * 0.92, h * 0.07), w * 0.55, p(_groundBreathe));
    canvas.drawCircle(Offset(w * 0.92, h * 0.07), w * 0.36,
        p(_primaryTint.withOpacity(0.85)));
    canvas.drawCircle(Offset(w * 0.92, h * 0.07), w * 0.18,
        p(Colors.white.withOpacity(0.55)));
    canvas.drawCircle(Offset(w * 0.04, h * 0.26), w * 0.22, p(_sunTint));
    canvas.drawCircle(Offset(w * 0.98, h * 0.50), w * 0.15,
        p(_lilacTint.withOpacity(0.7)));

    canvas.drawCircle(Offset(w * 0.15, h * 0.12), w * 0.045, p(_sun));
    canvas.drawCircle(Offset(w * 0.26, h * 0.17), w * 0.012, p(Colors.white));
    canvas.drawCircle(Offset(w * 0.74, h * 0.20), w * 0.016, p(Colors.white));
    canvas.drawCircle(Offset(w * 0.06, h * 0.60), w * 0.02, p(_primaryTint));

    final far = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.22, h * 0.70, w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.80, h * 0.86, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, p(_lilacTint.withOpacity(0.55)));

    final mid = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.28, h * 0.76, w * 0.58, h * 0.84)
      ..quadraticBezierTo(w * 0.82, h * 0.90, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mid, p(_primaryTint));

    final front = Path()
      ..moveTo(0, h * 0.93)
      ..quadraticBezierTo(w * 0.30, h * 0.87, w * 0.62, h * 0.93)
      ..quadraticBezierTo(w * 0.85, h * 0.97, w, h * 0.92)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, p(_groundGarden));
  }

  @override
  bool shouldRepaint(covariant _CalmScenePainter old) => old.base != base;
}

/// Slow fade + rise. Matches DESIGN.md §7.
class _Reveal extends StatelessWidget {
  final int order;
  final bool reduceMotion;
  final Widget child;
  const _Reveal(
      {required this.order, required this.reduceMotion, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 500 + order * 140),
      curve: Curves.easeInOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

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

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // --- Responsive signals (DESIGN.md §9) -----------------------------------
    final media = MediaQuery.of(context);
    final size = media.size;
    final isLandscape = size.width > size.height;
    final isNarrow = size.width < 360;
    final isShort = size.height < 640;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.3);

    final double widthScale = (size.width / 390).clamp(0.85, 1.15);
    final double scale = (widthScale * textScale).clamp(0.85, 1.25);

    // Padding / spacing (DESIGN.md §4 + §9)
    final double hPad = isNarrow ? 16 : 24;
    final double cardPad = isNarrow ? 20 : 24;
    final double sectionGap = isShort ? 16 : 20;

    // Content max-width — grows in landscape so 3-col grids have room.
    final double maxContentWidth = isLandscape ? 720 : 560;
    final double contentWidth =
        (size.width - hPad * 2).clamp(0.0, maxContentWidth);

    // Grid columns & aspect ratio. Wider layouts get 3 columns; each card
    // gets slightly taller on narrow screens so 2-line subtitles fit.
    final int crossAxisCount = isLandscape || size.width >= 600 ? 3 : 2;
    final double gridAspect = isNarrow ? 0.72 : 0.78;

    return Scaffold(
      backgroundColor: _groundHome,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _CalmScenePainter(base: _groundHome),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(hPad, isShort ? 16 : 24, hPad,
                    isShort ? 16 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ============================================================
                      // GREETING CARD
                      // ============================================================
                      _Reveal(
                        order: 0,
                        reduceMotion: reduceMotion,
                        child: _buildGreetingCard(
                          context,
                          childName,
                          scale,
                          cardPad: cardPad,
                          isNarrow: isNarrow,
                        ),
                      ),
                      SizedBox(height: sectionGap),

                      // ============================================================
                      // SECTION HEADER
                      // ============================================================
                      _Reveal(
                        order: 1,
                        reduceMotion: reduceMotion,
                        child: _buildSectionHeader(scale),
                      ),
                      SizedBox(height: isShort ? 12 : 16),

                      // ============================================================
                      // ADVENTURE GRID
                      // ============================================================
                      _Reveal(
                        order: 2,
                        reduceMotion: reduceMotion,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: isNarrow ? 10 : 14,
                          mainAxisSpacing: isNarrow ? 10 : 14,
                          childAspectRatio: gridAspect,
                          children: [
                            _CompactAdventureCard(
                              icon: Icons.mic_rounded,
                              imageAsset: 'images/home/talk_card.png',
                              titleSi: 'කතා කරමු',
                              titleEn: "Let's Talk",
                              subtitle: 'Reading and picture practice',
                              accentColor: const Color(0xFF3B82F6),
                              onAccentColor: Colors.white,
                              scale: scale,
                              onTap: () => context.push('/c1/record'),
                            ),
                            _CompactAdventureCard(
                              icon: Icons.videocam_rounded,
                              imageAsset: 'images/home/camera_card.png',
                              titleSi: 'ද්විතීයික හැසිරීම්',
                              titleEn: 'Behavior Analysis',
                              subtitle: 'Explore movement features in a video',
                              accentColor: const Color(0xFF0FA3A3),
                              onAccentColor: Colors.white,
                              scale: scale,
                              onTap: () => context.push('/c2/video/upload'),
                            ),
                            _CompactAdventureCard(
                              icon: Icons.auto_stories_rounded,
                              imageAsset: 'images/home/story_card.png',
                              titleSi: 'කතා පුහුණුව',
                              titleEn: 'Therapy Journey',
                              subtitle: 'Guided speech practice',
                              accentColor: const Color(0xFFE08A2E),
                              onAccentColor: Colors.white,
                              scale: scale,
                              onTap: () => context.push('/c3/forest-therapy'),
                            ),
                            _CompactAdventureCard(
                              icon: Icons.forum_rounded,
                              imageAsset: 'images/home/free_talk_card.png',
                              titleSi: 'නොපුහුණු කථනය',
                              titleEn: 'Spontaneous Talk',
                              subtitle: 'Speak on a topic you like',
                              accentColor: const Color(0xFF7C5CE0),
                              onAccentColor: Colors.white,
                              scale: scale,
                              onTap: () => context.push('/c4'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: sectionGap + 2),

                      // ============================================================
                      // PROGRESS CARD
                      // ============================================================
                      _Reveal(
                        order: 3,
                        reduceMotion: reduceMotion,
                        child: _buildProgressCard(
                          context,
                          scale,
                          cardPad: cardPad,
                          isNarrow: isNarrow,
                        ),
                      ),
                      SizedBox(height: isShort ? 12 : 16),

                      // ============================================================
                      // FOOTER TIP
                      // ============================================================
                      _Reveal(
                        order: 4,
                        reduceMotion: reduceMotion,
                        child: _buildFooterTip(scale),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // GREETING CARD
  // ---------------------------------------------------------------------
  Widget _buildGreetingCard(
    BuildContext context,
    String childName,
    double scale, {
    required double cardPad,
    required bool isNarrow,
  }) {
    // Logo + avatar shrink a touch on very narrow screens.
    final double logoSize = (56 * scale).clamp(48.0, 60.0);
    final double avatarRadius = isNarrow ? 20 : 24;

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _primaryTint, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            decoration: const BoxDecoration(
              color: _primaryTint,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/common/swara_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: isNarrow ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hi, $childName!',
                  style: TextStyle(
                    fontFamily: _fredoka,
                    fontSize: 22 * scale,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ස්වර · Ready to practice?',
                  style: TextStyle(
                    fontFamily: _nunito,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    color: _inkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(avatarRadius + 4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: _primaryTint,
                    child: CircleAvatar(
                      radius: avatarRadius - 2,
                      backgroundColor: _primaryTint,
                      foregroundImage: const AssetImage(
                          'assets/images/common/user_pic.jpg'),
                      onForegroundImageError: (_, __) {},
                      child: Icon(Icons.face_rounded,
                          color: _primary, size: avatarRadius),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------------
  Widget _buildSectionHeader(double scale) {
    return Column(
      children: [
        Text(
          'අද ගවේෂණය',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: _fredoka,
            fontSize: 26 * scale,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: _sun,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pick a practice for today',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: _nunito,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w700,
            color: _inkMuted,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // PROGRESS CARD
  // ---------------------------------------------------------------------
  Widget _buildProgressCard(
    BuildContext context,
    double scale, {
    required double cardPad,
    required bool isNarrow,
  }) {
    final double iconCircle = isNarrow ? 44 : 52;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/profile'),
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: cardPad, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _primaryTint, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: iconCircle,
                height: iconCircle,
                decoration: const BoxDecoration(
                  color: _sunTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: _sun,
                  size: isNarrow ? 24 : 28,
                ),
              ),
              SizedBox(width: isNarrow ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'මගේ ගමන',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fredoka,
                        fontSize: 18 * scale,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See how far you\'ve come!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _nunito,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        color: _inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _primary,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FOOTER TIP
  // ---------------------------------------------------------------------
  Widget _buildFooterTip(double scale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _primaryTint.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _primaryTint, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ඔබට ඕනෑම ක්‍රියාකාරකමක් තෝරා ගත හැකියි.',
              style: TextStyle(
                fontFamily: _nunito,
                fontSize: 14 * scale,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: _inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single "adventure" card used on the child home screen.
///
/// Shares the auth card DNA (DESIGN.md §5): white surface, `_primaryTint`
/// 2px border, 24px radius, and a soft accent-colored glow. Text scales
/// with the parent `scale` factor so cards stay readable on small phones
/// and large-text accessibility settings.
class _CompactAdventureCard extends StatefulWidget {
  final IconData icon;
  final String imageAsset;
  final String titleSi;
  final String titleEn;
  final String subtitle;
  final Color accentColor;
  final Color onAccentColor;
  final double scale;
  final VoidCallback onTap;

  const _CompactAdventureCard({
    required this.icon,
    required this.imageAsset,
    required this.titleSi,
    required this.titleEn,
    required this.subtitle,
    required this.accentColor,
    required this.onAccentColor,
    required this.scale,
    required this.onTap,
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
  late final Animation<double> _scaleAnim =
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Card text scales with the parent, but clamped so it never overflows.
    final double titleSize = (16 * widget.scale).clamp(13.0, 18.0);
    final double subtitleEnSize = (13 * widget.scale).clamp(11.0, 15.0);
    final double captionSize = (12 * widget.scale).clamp(10.0, 14.0);
    final double iconBadgeSize = (34 * widget.scale).clamp(28.0, 38.0);
    final double iconSize = (18 * widget.scale).clamp(14.0, 20.0);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => reduceMotion
            ? child!
            : Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: _primaryTint, width: 2),
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
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          width: iconBadgeSize,
                          height: iconBadgeSize,
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
                            size: iconSize,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _fredoka,
                                fontSize: titleSize,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.titleEn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _nunito,
                                fontSize: subtitleEnSize,
                                fontWeight: FontWeight.w800,
                                color: widget.accentColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _nunito,
                            fontSize: captionSize,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: _inkMuted,
                          ),
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
