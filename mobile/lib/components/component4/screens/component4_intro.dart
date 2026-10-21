import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class Component4Intro extends ConsumerStatefulWidget {
  const Component4Intro({super.key});

  @override
  ConsumerState<Component4Intro> createState() => _Component4IntroState();
}

class _Component4IntroState extends ConsumerState<Component4Intro> {
  bool _checking = false;

  /// A child who already ranked 5 interests goes straight to today's topic.
  Future<void> _start({bool changeInterests = false}) async {
    if (!C4Flow.isLive || changeInterests) {
      context.push('/c4/interest');
      return;
    }
    setState(() => _checking = true);
    try {
      final onboarded = await C4Flow.hasProfile();
      if (!mounted) return;
      context.push(onboarded ? '/c4/personalization_processing' : '/c4/interest');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiException.from(e).message)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    C4Flow.child = ref.watch(activeChildProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 1, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/spontaneous_friends.png',
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'ඔයා කැමති දේවල් ගැන කතා කරමු!',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let's Talk About Things You Like!",
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ඔයා කැමති දේවල් කිහිපයක් තෝරන්න. ඔයාට රසවත් සහ හුරුපුරුදු මාතෘකාවක් අපි තෝරමු.',
                      style: AppTextStyles.body.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose things you enjoy, and we'll find a topic that is interesting and comfortable for you.",
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIcon(Icons.touch_app_rounded, 'Choose'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.divider, size: 16),
                        const SizedBox(width: 8),
                        _buildStepIcon(Icons.record_voice_over_rounded, 'Talk'),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.divider, size: 16),
                        const SizedBox(width: 8),
                        _buildStepIcon(Icons.lightbulb_rounded, 'Discover'),
                      ],
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _checking ? null : _start,
                      child: _checking
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Start'),
                    ),
                    if (C4Flow.isLive)
                      TextButton(
                        onPressed: _checking ? null : () => _start(changeInterests: true),
                        child: const Text('මගේ කැමති දේවල් වෙනස් කරන්න (Change interests)'),
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

  Widget _buildStepIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.primaryWash,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
