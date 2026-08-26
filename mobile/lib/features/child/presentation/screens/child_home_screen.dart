import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.homeGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ============================================================
              // 1. MASCOT HEADER - Compact
              // ============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cardCream, Color(0xFFFFF5E6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.softYellow, AppColors.ctaOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ctaOrange.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text('🦊', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ආයුබෝවන්! 👋',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'අද අපි මොනවා කරමුද?',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'What shall we do today? 🌟',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.mintGreen.withOpacity(0.3),
                            width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: AppColors.ctaOrange, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '3 🔥',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ============================================================
              // 2. WELCOME BANNER - Compact
              // ============================================================
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.ctaOrange, Color(0xFFFF6B35)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctaOrange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('✨', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🌱 ස්වර ගමන ආරම්භ කරමු!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Let\'s begin the Swara journey 🚀',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        '4 Activities',
                        style: TextStyle(
                          color: AppColors.ctaOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // 3. SECTION TITLE - Compact
              // ============================================================
              Row(
                children: [
                  const Text(
                    '🎯 අද ගවේෂණය',
                    style: TextStyle(
                      color: Colors.white,
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
                        colors: [AppColors.softYellow, Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Today\'s Quest',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ============================================================
              // 4. COMPONENT CARDS - SMALLER
              // ============================================================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7, // SMALLER: reduced from 0.8 to 0.7
                children: [
                  _CompactAdventureCard(
                    emoji: '🎤',
                    titleSi: 'කතා කරමු',
                    titleEn: "Let's Talk",
                    subtitleSi: 'Reading & Picture',
                    subtitleEn: 'Speech practice',
                    colorAccent: AppColors.mintGreen,
                    gradientColors: const [
                      Color(0xFF6BCB77),
                      Color(0xFF4CAF50)
                    ],
                    badgeText: 'Comp 1',
                    onTap: () => context.push('/c1/record'),
                    icon: Icons.mic,
                  ),
                  _CompactAdventureCard(
                    emoji: '🎥',
                    titleSi: 'කතා කරන විදිහ',
                    titleEn: 'Camera Fun',
                    subtitleSi: 'Video Analysis',
                    subtitleEn: 'Watch & learn',
                    colorAccent: const Color(0xFFAEB8F0),
                    gradientColors: const [
                      Color(0xFF7C8CDB),
                      Color(0xFF5B6FC7)
                    ],
                    badgeText: 'Comp 2',
                    onTap: () => context.push('/c2/dashboard'),
                    icon: Icons.videocam,
                  ),
                  _CompactAdventureCard(
                    emoji: '📖',
                    titleSi: 'ක්‍රියාකාරකම්',
                    titleEn: 'Story Time',
                    subtitleSi: 'Guided Therapy',
                    subtitleEn: 'Relax & practice',
                    colorAccent: AppColors.softYellow,
                    gradientColors: const [
                      Color(0xFFFFD93D),
                      Color(0xFFFFC107)
                    ],
                    badgeText: 'Comp 3',
                    onTap: () => context.push('/activities'),
                    icon: Icons.auto_stories,
                  ),
                  _CompactAdventureCard(
                    emoji: '🌱',
                    titleSi: 'නිදහසේ කතා',
                    titleEn: 'Free Talk',
                    subtitleSi: 'Spontaneous Topics',
                    subtitleEn: 'Speak freely!',
                    colorAccent: AppColors.ctaOrange,
                    gradientColors: const [
                      Color(0xFFFF8A65),
                      Color(0xFFFF5722)
                    ],
                    badgeText: 'Comp 4',
                    onTap: () => context.push('/c4/task'),
                    icon: Icons.chat,
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
                    gradient: const LinearGradient(
                      colors: [AppColors.cardCream, Color(0xFFFFF5E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.softYellow.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
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
                            colors: [AppColors.softYellow, AppColors.ctaOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ctaOrange.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 22)),
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
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '• My Journey',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
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
                                color: AppColors.mintGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.mintGreen.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: AppColors.softYellow, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    'වැඩි වෙලාවක් කතා කළා! 🌟',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.text.withOpacity(0.7),
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
                          color: AppColors.ctaOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ctaOrange,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
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
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb,
                        color: AppColors.softYellow, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '✨ ඔබට ඕනෑම ක්‍රියාකාරකමක් තෝරා ගත හැකියි!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
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
    );
  }
}

// ============================================================
// COMPACT ADVENTURE CARD - Smaller design
// ============================================================
class _CompactAdventureCard extends StatelessWidget {
  final String emoji;
  final String titleSi;
  final String titleEn;
  final String subtitleSi;
  final String subtitleEn;
  final Color colorAccent;
  final List<Color> gradientColors;
  final String badgeText;
  final VoidCallback onTap;
  final IconData icon;

  const _CompactAdventureCard({
    required this.emoji,
    required this.titleSi,
    required this.titleEn,
    required this.subtitleSi,
    required this.subtitleEn,
    required this.colorAccent,
    required this.gradientColors,
    required this.badgeText,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // REDUCED: from 16 to 12
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, colorAccent.withOpacity(0.06)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22), // REDUCED: from 28 to 22
          border: Border.all(
            color: colorAccent.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorAccent.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji & Badge Row - Smaller
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8), // REDUCED: from 10 to 8
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(emoji,
                      style: const TextStyle(
                          fontSize: 22)), // REDUCED: from 28 to 22
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3), // REDUCED
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: Colors.white,
                          size: 10), // REDUCED: from 12 to 10
                      const SizedBox(width: 3),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8, // REDUCED: from 10 to 8
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Titles - Smaller
            Text(
              titleSi,
              style: const TextStyle(
                fontSize: 13, // REDUCED: from 16 to 13
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                height: 1.0,
              ),
            ),
            Text(
              titleEn,
              style: const TextStyle(
                fontSize: 11, // REDUCED: from 13 to 11
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitles - Smaller
            Text(
              subtitleSi,
              style: TextStyle(
                fontSize: 9, // REDUCED: from 11 to 9
                color: AppColors.textLight.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitleEn,
              style: TextStyle(
                fontSize: 8, // REDUCED: from 10 to 8
                color: AppColors.textLight.withOpacity(0.5),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // "Start" indicator - Smaller
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Start →',
                  style: TextStyle(
                    fontSize: 8, // REDUCED: from 10 to 8
                    fontWeight: FontWeight.w600,
                    color: colorAccent,
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
