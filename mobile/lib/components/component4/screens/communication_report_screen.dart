import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class CommunicationReportScreen extends StatelessWidget {
  const CommunicationReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spontaneous Speech Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImportantMLConcept(),
              const SizedBox(height: 32),
              _buildLexicalDiversity(),
              const SizedBox(height: 24),
              _buildUtteranceProduction(),
              const SizedBox(height: 32),
              _buildPersonalizedInterpretation(),
              const SizedBox(height: 32),
              _buildPersonalizedLanguageResult(),
              const SizedBox(height: 32),
              _buildSessionComparison(),
              const SizedBox(height: 32),
              _buildPersonalizedNextActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportantMLConcept() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primaryDeep),
              const SizedBox(width: 8),
              Text('How this activity was chosen', style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Child History + Component 1 + Component 2 + Component 3 + Previous Component 4 Results\n↓\nPersonalization Model\n↓\nTopic / Activity Selection',
            style: AppTextStyles.caption.copyWith(height: 1.6, color: AppColors.text),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLexicalDiversity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lexical Diversity', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('NDW', '38', 'Number of Different Words')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('MATTR', '0.48', 'Moving-Average Type-Token Ratio')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('VocD', '51', 'Vocabulary Diversity Estimate')),
          ],
        ),
      ],
    );
  }

  Widget _buildUtteranceProduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Utterance / Language Production', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard('MLU', '3.1', 'Mean Length of Utterance')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Speech Rate', '2.8 w/s', 'Words per second')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Pause Freq.', '12', 'Number of pauses')),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Avg Pause', '0.9s', 'Average pause duration')),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildPersonalizedInterpretation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language-Based Findings', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Observed Language Pattern', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Text(
                '“Compared with the child\'s previous session, the current sample shows increased lexical diversity and longer average utterances.”',
                style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _buildTrendRow('NDW', '38', '45', true),
              _buildTrendRow('MATTR', '0.48', '0.54', true),
              _buildTrendRow('MLU', '3.1', '3.5', true),
              _buildTrendRow('VocD', '51', '57', true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendRow(String label, String oldVal, String newVal, bool up) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: AppTextStyles.label)),
          Text('$oldVal → ', style: AppTextStyles.bodySmall),
          Text(newVal, style: AppTextStyles.label),
          const SizedBox(width: 8),
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: up ? AppColors.success : AppColors.error),
        ],
      ),
    );
  }

  Widget _buildPersonalizedLanguageResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Child\'s Language Profile', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatusRow('Vocabulary Diversity', 'Increasing', AppColors.success)),
                  Expanded(child: _buildStatusRow('Utterance Length', 'Increasing', AppColors.success)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatusRow('Speech Rate', 'Stable', AppColors.warning)),
                  Expanded(child: _buildStatusRow('Pausing', 'Variable', AppColors.warning)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Overall Language Observation', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Text(
                '“The child demonstrated increased lexical diversity and longer utterances in the current spontaneous speech sample compared with previous sessions. Vocabulary variety showed an increasing trend, while speech rate remained relatively stable.”',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These results describe observed speech and language patterns and are intended to support SLP review. They are not a clinical diagnosis.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 6),
            Text(status, style: AppTextStyles.label.copyWith(color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionComparison() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Language Development\nAcross Sessions', style: AppTextStyles.heading2),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session comparison filter opened (Mock)')),
                  );
                },
                icon: const Icon(Icons.filter_list, size: 16),
                label: const Text('Compare Sessions'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                '[Line Chart]\nSession 1 → Session 2 → Session 3 → Session 4\nNDW: 38 → 41 → 45 → 49',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlternativesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alternative Activities', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primary),
                title: const Text('Picture Description'),
                subtitle: const Text('Focus on vocabulary'),
                trailing: const Icon(Icons.check_circle, color: AppColors.success),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected Picture Description')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                title: const Text('Open Conversation'),
                subtitle: const Text('Focus on spontaneous utterances'),
                trailing: const Icon(Icons.circle_outlined),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected Open Conversation')),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAssignSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              Text('Activity Assigned', style: AppTextStyles.heading2),
            ],
          ),
          content: Text(
            'The recommended activity has been successfully assigned to the child\'s dashboard for their next session.',
            style: AppTextStyles.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              child: const Text('Return Home'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPersonalizedNextActivity() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested Next Speaking Activity', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: AppColors.surfaceRaised,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Recommended: Story Retelling', style: AppTextStyles.heading3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Reason:', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    '“Previous sessions showed successful performance during picture description. A slightly more open-ended storytelling activity may provide an opportunity to observe spontaneous vocabulary and utterance production.”',
                    style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showAlternativesBottomSheet(context),
                          child: const Text('View Alternatives'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showAssignSuccessDialog(context),
                          child: const Text('Assign Activity'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'AI-generated suggestion for SLP review',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
