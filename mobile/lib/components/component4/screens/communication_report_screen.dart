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
        title: const Text('Linguistic & Lexical Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primaryDeep,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfo(),
              const SizedBox(height: 32),
              _buildPersonalizedTaskSelection(),
              const SizedBox(height: 32),
              _buildSpeechSample(),
              const SizedBox(height: 32),
              _buildLanguageProfile(),
              const SizedBox(height: 32),
              _buildLexicalDiversity(),
              const SizedBox(height: 24),
              _buildMLUSection(),
              const SizedBox(height: 24),
              _buildSpeechFlowSection(),
              const SizedBox(height: 32),
              _buildPersonalizedInterpretation(),
              const SizedBox(height: 32),
              _buildObservationSummary(),
              const SizedBox(height: 32),
              _buildSessionComparison(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spontaneous Speech — Sinhala', style: AppTextStyles.heading2.copyWith(color: AppColors.textLight)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.divider,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow('Child ID', 'SW-8472 (Anonymized)'),
              const Divider(),
              _buildInfoRow('Session', '04'),
              const Divider(),
              _buildInfoRow('Date', 'Nov 14, 2024'),
              const Divider(),
              _buildInfoRow('Task Type', 'Picture Sequence Narrative'),
              const Divider(),
              _buildInfoRow('Task ID', 'TSK-PSN-02'),
              const Divider(),
              _buildInfoRow('Analysis Status', '✅ Completed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
          Text(value, style: AppTextStyles.heading3),
        ],
      ),
    );
  }

  Widget _buildSpeechSample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speech Transcript', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“මගේ බල්ලාගේ නම ටොමී. එයා මාත් එක්ක සෙල්ලම් කරන්න ගොඩක් කැමතියි. අපි හැමදාම හවසට සෙල්ලම් කරනවා. එයා ගොඩක් හොඳයි.”',
                style: AppTextStyles.heading3.copyWith(
                  height: 1.6,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text('00:00 - 00:18', style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language Profile', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildProfileItem('Lexical Diversity', 'Detected vocabulary diversity during the session.'),
              const Divider(height: 24),
              _buildProfileItem('Utterance Length', 'Observed average utterance length.'),
              const Divider(height: 24),
              _buildProfileItem('Speech Rate', 'Observed speaking rate.'),
              const Divider(height: 24),
              _buildProfileItem('Pausing', 'Observed pause frequency and duration.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(String label, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(desc, style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
            ],
          ),
        ),
      ],
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

  Widget _buildMLUSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mean Length of Utterance', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryWash,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Column(
            children: [
              const Text('MLU', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
              const SizedBox(height: 8),
              const Text('3.5', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primaryDeep)),
              const SizedBox(height: 8),
              Text('Average length of analyzed utterances.', style: AppTextStyles.caption.copyWith(color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechFlowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speech Flow', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.divider,
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildFlowRow('Speech Rate', '2.8 words/sec', 0.6),
              const SizedBox(height: 16),
              _buildFlowRow('Pause Frequency', '12 pauses', 0.4),
              const SizedBox(height: 16),
              _buildFlowRow('Avg Pause Duration', '0.9s', 0.3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlowRow(String label, String value, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
            Text(value, style: AppTextStyles.heading3),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: AppColors.surfaceRaised,
          color: AppColors.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
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

  Widget _buildObservationSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language Observations', style: AppTextStyles.heading2),
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
                  const Text('🤖', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Automated Observation', style: AppTextStyles.label.copyWith(color: AppColors.primaryDeep)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• A broader range of words was observed in this session compared to the previous one.\n'
                '• Average utterance length was slightly higher than in the previous session.\n'
                '• Speech rate remained relatively stable across the session.',
                style: AppTextStyles.bodySmall.copyWith(height: 1.6),
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
                        'This observation is generated from the analyzed speech sample and should be reviewed by a qualified SLP.',
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

  Widget _buildSessionComparison() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Language Journey\n(Session Progress)', style: AppTextStyles.heading2),
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
          const SizedBox(height: 12),
          Text('Trend observed:', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'Lexical diversity showed an increasing trend across the recorded sessions.',
            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTaskSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personalized Task Selection', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Previous Session Profile', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              _buildProfileListItem('Component 1: Stable stuttering frequency observed in reading tasks.'),
              _buildProfileListItem('Component 2: No significant secondary behaviors detected.'),
              _buildProfileListItem('Component 3: Completed structured breathing activity successfully.'),
              _buildProfileListItem('Component 4 (Previous): High lexical diversity in picture description.'),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text('Recommended Speaking Task', style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('🖼️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text('Picture Sequence Narrative', style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDeep)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Selection Rationale', style: AppTextStyles.label.copyWith(color: AppColors.textLight)),
              const SizedBox(height: 4),
              Text(
                '“This task was selected to obtain spontaneous narrative speech while maintaining a structured speaking context.”',
                style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.text))),
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
