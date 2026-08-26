import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final String? currentLocation;

  const MainScaffold({super.key, required this.child, this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.jewelNavy,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟 ', style: TextStyle(fontSize: 24)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ස්වර / Swara', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                Text('Speech Adventure', style: TextStyle(fontSize: 12, color: AppColors.softYellow.withOpacity(0.9))),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.softYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.softYellow.withOpacity(0.4), blurRadius: 10)
                ],
              ),
              child: const Text('🦊', style: TextStyle(fontSize: 24)), // Mascot!
            ),
          )
        ],
      ),
      body: child,
      bottomNavigationBar: _buildKidsBottomNav(context),
    );
  }

  Widget _buildKidsBottomNav(BuildContext context) {
    String location = currentLocation ?? '/';
    if (currentLocation == null) {
      try {
        location = GoRouterState.of(context).uri.toString();
      } catch (_) {
        try {
          location = GoRouter.of(context).routeInformationProvider.value.uri.toString();
        } catch (_) {}
      }
    }
    
    int currentIndex = 0;
    if (location.startsWith('/activities')) currentIndex = 2;
    else if (location.startsWith('/profile')) currentIndex = 3;
    else if (location.startsWith('/c1') || location.startsWith('/c2')) currentIndex = 1;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, index: 0, icon: Icons.map, emoji: '🗺️', label: 'මුල් පිටුව\nHome', isActive: currentIndex == 0, route: '/'),
            _buildNavItem(context, index: 1, icon: Icons.mic, emoji: '🎤', label: 'කතා\nSpeech', isActive: currentIndex == 1, route: '/c1/record'),
            _buildNavItem(context, index: 2, icon: Icons.menu_book, emoji: '📖', label: 'ක්‍රියාකාරකම්\nActivities', isActive: currentIndex == 2, route: '/activities'),
            _buildNavItem(context, index: 3, icon: Icons.military_tech, emoji: '🏆', label: 'මගේ\nProfile', isActive: currentIndex == 3, route: '/profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required int index,
    required IconData icon,
    required String emoji,
    required String label,
    required bool isActive,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.ctaOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label.split('\n')[0],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
