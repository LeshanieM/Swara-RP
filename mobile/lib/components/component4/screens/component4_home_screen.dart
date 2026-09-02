import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class Component4HomeScreen extends StatefulWidget {
  const Component4HomeScreen({super.key});

  @override
  State<Component4HomeScreen> createState() => _Component4HomeScreenState();
}

class _Component4HomeScreenState extends State<Component4HomeScreen> {
  String _statusMessage = 'Swara is getting ready! 🌱';
  String _statusMessageSi = 'ස්වරා සූදානම් වෙනවා!';

  @override
  void initState() {
    super.initState();
    _startPreparationSequence();
  }

  Future<void> _startPreparationSequence() async {
    // 01 - Previous Results (Simulated backend retrieval)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _statusMessage = 'Finding today\'s activity... 🎁';
        _statusMessageSi = 'අද කතාව තෝරමින්...';
      });
    }

    // 02 - Personalized Task Preparation (Simulated backend processing)
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.pushReplacement('/c4/personalization');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Friendly Avatar
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withOpacity(0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/component4/c4_swara_bot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  color: AppColors.primaryDeep,
                  strokeWidth: 4,
                ),
                const SizedBox(height: 48),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    key: ValueKey<String>(_statusMessageSi),
                    children: [
                      Text(
                        _statusMessageSi,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primaryDeep,
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: AppTextStyles.heading3.copyWith(color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
