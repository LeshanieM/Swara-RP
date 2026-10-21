import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/screens/interest_selection.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/core/network/api_exception.dart';

class PersonalizedTopicScreen extends StatefulWidget {
  const PersonalizedTopicScreen({super.key});

  @override
  State<PersonalizedTopicScreen> createState() => _PersonalizedTopicScreenState();
}

class _PersonalizedTopicScreenState extends State<PersonalizedTopicScreen> {
  bool _busy = false;

  /// "Another topic" skips the main prompt; the server picks a different topic (logged).
  Future<void> _anotherTopic() async {
    if (!C4Flow.isLive) {
      context.push('/c4/question');
      return;
    }
    setState(() => _busy = true);
    try {
      await C4Flow.anotherTopic();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiException.from(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = C4Flow.view;
    final image = C4Flow.isLive
        ? InterestCategory.images[C4Flow.session?['topic']?['categoryId']] ?? 'assets/images/spontaneous_friends.png'
        : 'assets/images/component3/lion_mascot.jpg';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 5, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                        image: DecorationImage(
                          image: AssetImage(image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep,
                        borderRadius: AppRadii.xsAll,
                      ),
                      child: Text(
                        'YOUR TOPIC',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ඔයාගේ මාතෘකාව',
                      style: AppTextStyles.label.copyWith(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      v.topicSi,
                      style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      v.topicEn,
                      style: AppTextStyles.heading3.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildChip(v.categoryEn),
                        _buildChip('Age ${v.ageBand}'),
                        _buildChip(v.level),
                        if (v.categoryRank != null) _buildChip('Favourite no. ${v.categoryRank}'),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'මේ ගැන කතා කරමුද?',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/question'),
                      child: const Text('ඔව්, කතා කරමු!'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : _anotherTopic,
                      child: _busy
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('වෙනත් මාතෘකාවක්'),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.smAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption,
      ),
    );
  }
}
