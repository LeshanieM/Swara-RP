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
    if (location.startsWith('/activities') || location.startsWith('/c3')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    } else if (location.startsWith('/c1') || location.startsWith('/c2') || location.startsWith('/c4')) {
      currentIndex = 1;
    } else {
      currentIndex = 0;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066CC).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, index: 0, icon: Icons.home_rounded, label: 'Home', isActive: currentIndex == 0, route: '/'),
              _buildNavItem(context, index: 1, icon: Icons.mic_rounded, label: 'Speech', isActive: currentIndex == 1, route: '/c1/record'),
              _buildNavItem(context, index: 2, icon: Icons.psychology_rounded, label: 'Therapy', isActive: currentIndex == 2, route: '/activities'),
              _buildNavItem(context, index: 3, icon: Icons.person_rounded, label: 'Profile', isActive: currentIndex == 3, route: '/profile'),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required String route,
  }) {
    const blueColor = Color(0xFF0066CC);
    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? blueColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? blueColor : Colors.grey.shade500,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: blueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
