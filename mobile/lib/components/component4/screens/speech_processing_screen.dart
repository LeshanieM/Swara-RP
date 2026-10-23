import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/core/network/api_exception.dart';

class SpeechProcessingScreen extends StatefulWidget {
  const SpeechProcessingScreen({super.key});

  @override
  State<SpeechProcessingScreen> createState() => _SpeechProcessingScreenState();
}

class _SpeechProcessingScreenState extends State<SpeechProcessingScreen> {
  int _activeStage = 1; // 0 completed, 1 processing

  final List<Map<String, dynamic>> _stages = [
    {'title': 'කථනය පටිගත කළා', 'icon': Icons.mic},
    {'title': 'සිංහල කථනය → ලිඛිත වචන', 'icon': Icons.translate},
    {'title': 'භාෂා විශ්ලේෂණය', 'icon': Icons.analytics},
    {'title': 'සන්නිවේදන ප්‍රතිඵල', 'icon': Icons.assignment},
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  String? _error;

  /// The stages advance while the API transcribes and analyses the sample; the last one waits for it.
  void _startProcessing() async {
    final analysis = C4Flow.isLive ? C4Flow.waitForSample() : Future<void>.value();
    for (int i = 1; i < _stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _activeStage = i;
        });
      }
    }
    try {
      await analysis;
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _activeStage = _stages.length);
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _activeStage >= _stages.length;

    return Scaffold(
      backgroundColor: AppColors.groundRead,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 9, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                child: Column(
                  children: [
                    Text(
                      isComplete ? 'විශ්ලේෂණය සම්පූර්ණයි' : 'ඔයාගේ කථනය විශ්ලේෂණය කරමින්...',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete ? 'විශ්ලේෂණය අවසන්' : 'ඔයාගේ කථනය තේරුම් ගනිමින්...',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    ...List.generate(_stages.length, (index) {
                      return _buildProcessRow(index, _stages[index]['title']!, _stages[index]['icon']);
                    }),
                    const SizedBox(height: 48),
                    if (_error != null) ...[
                      Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        // One sample per session, so recording again starts a new session.
                        onPressed: () => context.go('/c4'),
                        child: const Text('නැවත උත්සාහ කරන්න'),
                      ),
                    ],
                    if (isComplete)
                      ElevatedButton(
                        onPressed: () {
                          Future.microtask(() => context.push('/c4/transcription'));
                        },
                        child: const Text('පිටපත බලන්න'),
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

  Widget _buildProcessRow(int stageIndex, String title, IconData icon) {
    bool isCompleted = _activeStage > stageIndex;
    bool isCurrent = _activeStage == stageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success.withOpacity(0.1) : (isCurrent ? AppColors.primaryWash : AppColors.surfaceRaised),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted ? AppColors.success : (isCurrent ? AppColors.primary : AppColors.textLight.withOpacity(0.5)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isCompleted ? AppColors.text : (isCurrent ? AppColors.primaryDeep : AppColors.textLight.withOpacity(0.5)),
                  ),
                ),
                Text(
                  isCompleted ? 'අවසන්' : (isCurrent ? 'සකසමින්...' : 'බලා සිටියි'),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (isCurrent)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
