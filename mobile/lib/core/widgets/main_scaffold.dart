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
      backgroundColor: const Color(0xFF000080),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: AppColors.surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillAll,
          side: const BorderSide(color: AppColors.divider),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, icon: Icons.home_rounded, label: 'Home', isActive: currentIndex == 0, route: '/'),
                _buildNavItem(context, icon: Icons.mic_rounded, label: 'Speech', isActive: currentIndex == 1, route: '/c1/record'),
                _buildNavItem(context, icon: Icons.psychology_rounded, label: 'Therapy', isActive: currentIndex == 2, route: '/c3/forest-therapy'),
                _buildNavItem(context, icon: Icons.person_rounded, label: 'Profile', isActive: currentIndex == 3, route: '/profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: AppRadii.pillAll,
      overlayColor: WidgetStateProperty.all(AppColors.primaryWash),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryDeep : AppColors.textLight,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
