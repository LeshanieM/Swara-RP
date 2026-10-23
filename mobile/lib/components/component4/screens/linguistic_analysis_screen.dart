import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/services/c4_flow.dart';

class LinguisticAnalysisScreen extends StatefulWidget {
  const LinguisticAnalysisScreen({super.key});

  @override
  State<LinguisticAnalysisScreen> createState() => _LinguisticAnalysisScreenState();
}

class _LinguisticAnalysisScreenState extends State<LinguisticAnalysisScreen> {
  int _activeStage = 0; // 0: audio, 1: MLU, 2: NDW, 3: duration, 4: complete
  int _mluStep = 0;
  int _ndwStep = 0;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() async {
    // Audio summary shows first
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _activeStage = 1);
    
    // MLU calculation
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _mluStep = i);
    }
    
    if (mounted) setState(() => _activeStage = 2);

    // NDW calculation
    for (int i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() => _ndwStep = i);
    }

    if (mounted) setState(() => _activeStage = 3);
    
    // Duration
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) setState(() => _activeStage = 4);
  }

  @override
  Widget build(BuildContext context) {
    final v = C4Flow.view;
    final duration = fmtClock(v.durationSec);
    final mlu = v.mlu == null ? '—' : v.mlu!.toStringAsFixed(1);
    return Scaffold(
      backgroundColor: AppColors.groundRead,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 11, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _activeStage == 4 ? 'විශ්ලේෂණය සම්පූර්ණයි' : 'ඔයාගේ කථනය විශ්ලේෂණය කරමින්...',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeStage == 4 ? 'විශ්ලේෂණය සම්පූර්ණයි · Analysis complete' : 'කථනය විශ්ලේෂණය කරමින් · Analysing speech',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 24),

                    // Audio Summary Card
                    _buildCard(
                      title: 'පටිගත කළ කථනය · Recorded speech',
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq, color: AppColors.primary, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('සිංහල කථනය', style: AppTextStyles.titleMedium),
                                Text(duration, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // MLU Calculation
                    if (_activeStage >= 1)
                      _buildCard(
                        title: 'ප්‍රකාශන දිග · MLU',
                        subtitle: 'සාමාන්‍ය ප්‍රකාශන දිග',
                        child: Column(
                          children: [
                            if (_mluStep >= 1) _buildCalcStep('ප්‍රකාශන · Utterances', '${v.utterances}'),
                            if (_mluStep >= 2) _buildCalcStep('මුළු වචන · Total words', '${v.totalWords}'),
                            if (_mluStep >= 3) _buildCalcStep('වචන ÷ ප්‍රකාශන · Words ÷ utterances', '${v.totalWords} ÷ ${v.utterances}'),
                            if (_mluStep >= 4)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  children: [
                                    Text(mlu, style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 48)),
                                    Text('වචන / ප්‍රකාශනය', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // NDW Calculation
                    if (_activeStage >= 2)
                      _buildCard(
                        title: 'වෙනස් වචන · Unique words',
                        subtitle: 'වෙනස් වචන ගණන',
                        child: Column(
                          children: [
                            if (_ndwStep >= 1) _buildCalcStep('පිටපතේ වචන · Transcript words', '${v.totalWords}'),
                            if (_ndwStep >= 2) _buildCalcStep('වෙනස් වචන · Unique words', '${v.ndw}'),
                            if (_ndwStep >= 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Column(
                                  children: [
                                    Text('${v.ndw}', style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 48)),
                                    Text('වෙනස් වචන', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Response Duration
                    if (_activeStage >= 3)
                      _buildCard(
                        title: 'කථන කාලය · Speech duration',
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ආරම්භය: 00:00', style: AppTextStyles.bodySmall),
                                const Icon(Icons.arrow_forward, size: 16, color: AppColors.textLight),
                                Text('අවසානය: $duration', style: AppTextStyles.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(duration, style: AppTextStyles.heading1.copyWith(color: AppColors.primaryDeep, fontSize: 32)),
                            Text('මුළු කථන පිළිතුරු කාලය', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),
                    
                    if (_activeStage < 4)
                      Column(
                        children: [
                          Text('විශ්ලේෂණ ප්‍රගතිය', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (_activeStage * 25 + (_mluStep * 5) + (_ndwStep * 5)) / 100.0,
                          ),
                        ],
                      ),

                    if (_activeStage == 4)
                      ElevatedButton(
                        onPressed: () => context.push('/c4/results'),
                        child: const Text('ප්‍රතිඵල බලන්න →'),
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

  Widget _buildCard({required String title, String? subtitle, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.mdAll,
        border: Border.all(color: AppColors.primaryLight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge.copyWith(color: AppColors.text)),
          if (subtitle != null) ...[
            Text(subtitle, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCalcStep(String title, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodySmall)),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.divider),
          const SizedBox(width: 8),
          Text(result, style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
        ],
      ),
    );
  }
}
