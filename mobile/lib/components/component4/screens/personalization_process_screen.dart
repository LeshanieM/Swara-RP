import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/core/network/api_exception.dart';

class PersonalizationProcessScreen extends StatefulWidget {
  const PersonalizationProcessScreen({super.key});

  @override
  State<PersonalizationProcessScreen> createState() => _PersonalizationProcessScreenState();
}

class _PersonalizationProcessScreenState extends State<PersonalizationProcessScreen> {
  int _activeStage = 0;
  Future<void>? _session;
  String? _error;

  /// The stage cards: the chosen topic's category and its rank, the child's age and the topic itself.
  List<Map<String, String>> get _stages {
    final ready = !C4Flow.isLive || C4Flow.session != null;
    final v = C4Flow.view;
    return [
      {'title': ready ? v.categoryEn : '...', 'subtitle': 'Your Interests'},
      {'title': ready && v.categoryRank != null ? 'Favourite no. ${v.categoryRank} of 5' : 'Ranking', 'subtitle': 'Your Ranking'},
      {'title': C4Flow.isLive ? 'Age: ${C4Flow.child?.age ?? ''}' : 'Age: 9', 'subtitle': 'Child Profile'},
      {'title': 'Matching validated topics...', 'subtitle': 'SLP Topic Bank'},
      {'title': ready ? (v.topicEn.isEmpty ? v.topicSi : v.topicEn) : '...', 'subtitle': v.isFixed ? "Today's Topic" : 'Personalized Topic'},
    ];
  }

  @override
  void initState() {
    super.initState();
    if (C4Flow.isLive) _session = _prepare();
    _startAnimation();
  }

  /// Saves a new ranking from onboarding (if there is one), then starts today's session.
  Future<void> _prepare() async {
    try {
      if (C4Flow.ranked.length == 5) await C4Flow.saveProfile();
      await C4Flow.startSession();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
      rethrow;
    }
  }

  void _startAnimation() async {
    for (int i = 0; i < _stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        setState(() {
          _activeStage = i;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 1500));
    try {
      await _session;
    } catch (_) {
      return; // the error card is showing
    }
    if (mounted) {
      // The parent checklist comes once, after the interests are saved; it sets the starting level.
      context.push(C4Flow.isLive && !C4Flow.checklistDone ? '/c4/checklist' : '/c4/topic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 4, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ඔයාට ගැළපෙන මාතෘකාවක් සොයමින්...',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Finding a topic just for you...',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (_error != null) ...[
                      Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _activeStage = 0;
                            _session = _prepare();
                          });
                          _startAnimation();
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                    for (int i = 0; i < _stages.length; i++) ...[
                      _buildStageCard(i),
                      if (i < _stages.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _activeStage >= i ? 1.0 : 0.2,
                            child: const Icon(Icons.arrow_downward, color: AppColors.primaryLight),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(int index) {
    final isActive = _activeStage == index;
    final isCompleted = _activeStage > index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryWash
            : (isCompleted ? AppColors.surfaceRaised : AppColors.surface),
        borderRadius: AppRadii.lgAll,
        border: Border.all(
          color: isActive ? AppColors.primary : (isCompleted ? AppColors.divider : Colors.transparent),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? AppElevation.card : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  _stages[index]['title']!,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isActive || isCompleted ? AppColors.primaryDeep : AppColors.textLight.withOpacity(0.5),
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isActive || isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    _stages[index]['subtitle']!,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),
          if (isActive)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}
