import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.entrance,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: AppMotion.entranceCurve);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      _goHome(authState.role);
    } else {
      context.go('/login');
    }
  }

  void _goHome(String role) {
    switch (role) {
      case AppConstants.roleParent:
        context.go('/parent/home');
        break;
      case AppConstants.roleTherapist:
        context.go('/therapist/home');
        break;
      case AppConstants.roleChild:
        context.go('/child/home');
        break;
      default:
        context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text(
                    'ස',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 44,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Swara',
                style: AppTextStyles.heading1.copyWith(color: AppColors.onPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sinhala speech support',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Research prototype',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
