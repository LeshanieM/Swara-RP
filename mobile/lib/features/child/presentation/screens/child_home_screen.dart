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
    final childName = (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'child')
        ? rawName.split(' ').first
        : 'Aseliya';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.homeGradient,
      ),
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
                    Row(
                children: [
                  const Text(
                    '🎯 අද ගවේෂණය',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 2,
                    width: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066CC), Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Today\'s Quest',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ============================================================
              // 4. COMPONENT CARDS - MODERN DARK BLUE DESIGN
              // ============================================================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: [
                  // Comp 1: Royal / Electric Blue
                  _CompactAdventureCard(
                    icon: Icons.mic_rounded,
                    titleSi: 'කතා කරමු',
                    titleEn: "Let's Talk",
                    subtitleSi: 'Reading & Picture',
                    subtitleEn: 'Speech practice',
                    colorAccent: const Color(0xFF38BDF8),
                    gradientColors: const [
                      Color(0xFF0066CC),
                      Color(0xFF0284C7),
                    ],
                    badgeText: 'SPEECH',
                    onTap: () => context.push('/c1/record'),
                  ),
                  // Comp 2: Deep Indigo / Cobalt Blue
                  _CompactAdventureCard(
                    icon: Icons.videocam_rounded,
                    titleSi: 'කතා කරන විදිහ',
                    titleEn: 'Camera Fun',
                    subtitleSi: 'Video Analysis',
                    subtitleEn: 'Watch & learn',
                    colorAccent: const Color(0xFF818CF8),
                    gradientColors: const [
                      Color(0xFF1D4ED8),
                      Color(0xFF6366F1),
                    ],
                    badgeText: 'VIDEO',
                    onTap: () => context.push('/c2/dashboard'),
                  ),
                  // Comp 3: Cerulean / Sky Blue
                  _CompactAdventureCard(
                    icon: Icons.auto_stories_rounded,
                    titleSi: 'ක්‍රියාකාරකම්',
                    titleEn: 'Story Time',
                    subtitleSi: 'Guided Therapy',
                    subtitleEn: 'Relax & practice',
                    colorAccent: const Color(0xFF22D3EE),
                    gradientColors: const [
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9),
                    ],
                    badgeText: 'THERAPY',
                    onTap: () => context.push('/activities'),
                  ),
                  // Comp 4: Cyan / Marine Blue
                  _CompactAdventureCard(
                    icon: Icons.forum_rounded,
                    titleSi: 'නිදහසේ කතා',
                    titleEn: 'Free Talk',
                    subtitleSi: 'Spontaneous Topics',
                    subtitleEn: 'Speak freely!',
                    colorAccent: const Color(0xFF60A5FA),
                    gradientColors: const [
                      Color(0xFF0369A1),
                      Color(0xFF38BDF8),
                    ],
                    badgeText: 'FREE TALK',
                    onTap: () => context.push('/c4/task'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ============================================================
              // 5. PROGRESS PATH - Compact
              // ============================================================
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF0066CC).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0066CC).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066CC), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0066CC).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'මගේ ගමන',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '• My Journey',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0066CC).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF0066CC).withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      color: Color(0xFF0066CC), size: 14),
                                  SizedBox(width: 3),
                                  Text(
                                    'වැඩි වෙලාවක් කතා කළා!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF0066CC),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066CC),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF0066CC),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ============================================================
              // 6. QUICK TIPS - Compact
              // ============================================================
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0066CC).withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tips_and_updates_rounded,
                        color: Color(0xFF0066CC), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ඔබට ඕනෑම ක්‍රියාකාරකමක් තෝරා ගත හැකියි!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF0066CC).withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066CC).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Speech-support branded app logo (Soundwaves + Voice + Gradient Badge)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066CC), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066CC).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // App Name in both Sinhala & English
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ස්වර',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066CC),
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '• Swara',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                'Speech Support',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Child Profile (Aseliya + Profile Icon)
          GestureDetector(
            onTap: () => context.push('/profile'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explorer',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0066CC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Child avatar profile icon with active indicator
                Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0066CC).withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/common/user_pic.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(
                              Icons.face_rounded,
                              color: Color(0xFF0066CC),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPACT ADVENTURE CARD - Modern Dark Blue Card Design
// ============================================================
class _CompactAdventureCard extends StatelessWidget {
  final IconData icon;
  final String titleSi;
  final String titleEn;
  final String subtitleSi;
  final String subtitleEn;
  final Color colorAccent;
  final List<Color> gradientColors;
  final String badgeText;
  final VoidCallback onTap;

  const _CompactAdventureCard({
    required this.icon,
    required this.titleSi,
    required this.titleEn,
    required this.subtitleSi,
    required this.subtitleEn,
    required this.colorAccent,
    required this.gradientColors,
    required this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0F172A),
              Color.lerp(const Color(0xFF1E293B), colorAccent, 0.18) ?? const Color(0xFF1E293B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorAccent.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorAccent.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Modern Icon Badge & Tag Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: colorAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorAccent.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: colorAccent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Sinhala Title - High contrast crisp white
            Text(
              titleSi,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            // English Title - Highlighted Accent Blue
            Text(
              titleEn,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colorAccent,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitles - Crisp Slate Tones
            Text(
              subtitleSi,
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitleEn,
              style: const TextStyle(
                fontSize: 8.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Bottom Action Arrow Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: colorAccent,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 10,
                        color: colorAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
