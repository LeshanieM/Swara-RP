import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/psychology_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import '../../data/models/questionnaire_question.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  final String childId;

  const QuestionnaireScreen({super.key, required this.childId});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  int _currentPage = 0;
  final List<Map<String, dynamic>> _questions = DemoData.questionnaireQuestions;

  static const _options = ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(psychologyNotifierProvider(widget.childId));
    final question = _questions[_currentPage];
    final total = _questions.length;
    final answered = state.answers.length;
    final currentAnswer = state.answers[question['id'] as String];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Questionnaire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const DisclaimerBanner(
            message: 'These are caregiver support suggestions, not a psychological diagnosis.',
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${_currentPage + 1} of $total', style: AppTextStyles.bodySmall),
                    Text('$answered answered', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / total,
                    backgroundColor: AppColors.primaryWash,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWash,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question['area'] as String,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    question['text'] as String,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 32),
                  ..._options.asMap().entries.map((e) {
                    final score = e.key;
                    final label = e.value;
                    final isSelected = currentAnswer == score;
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(psychologyNotifierProvider(widget.childId).notifier)
                            .setAnswer(question['id'] as String, score);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryWash : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primary : AppColors.textLight,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.text,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentPage > 0) ...[
                  Expanded(
                    child: SwaraButton(
                      label: 'Back',
                      outlined: true,
                      onPressed: () => setState(() => _currentPage--),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _currentPage < total - 1
                      ? SwaraButton(
                          label: 'Next',
                          onPressed: currentAnswer != null
                              ? () => setState(() => _currentPage++)
                              : null,
                        )
                      : SwaraButton(
                          label: 'Generate Support Report',
                          isLoading: state.isLoading,
                          onPressed: answered == total ? _submit : null,
                          icon: Icons.auto_awesome,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final result = await ref
        .read(psychologyNotifierProvider(widget.childId).notifier)
        .submitQuestionnaire();
    if (result != null && mounted) {
      context.push('/psychology/result', extra: result);
    }
  }
}
