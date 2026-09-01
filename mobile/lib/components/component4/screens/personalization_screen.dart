import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personalized Speaking Activity'),
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
              Text(
                'Child Performance Profile',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              _buildPerformanceGrid(),
              const SizedBox(height: 32),
              Text(
                'Recommended Activity',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              _buildRecommendedActivityCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProfileSection(
                'Fluency',
                [
                  'Stuttering severity: Moderate',
                  'Speech rate: 2.8 words/sec',
                  'Pause frequency: Elevated',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfileSection(
                'Secondary Behaviors',
                [
                  'Eye blinking: Mild',
                  'Head movement: Low',
                  'Facial tension: Moderate',
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProfileSection(
                'Previous Therapy Activities',
                [
                  'Picture description',
                  'Storytelling',
                  'Conversation',
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildProfileSection(
                'Previous Language Performance',
                [
                  'NDW: 38',
                  'MATTR: 0.48',
                  'VocD: 51',
                  'MLU: 3.1',
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSection(String title, List<String> items) {
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
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.textLight)),
                    Expanded(child: Text(item, style: AppTextStyles.bodySmall)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendedActivityCard(BuildContext context) {
    return Builder(
      builder: (context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surfaceRaised,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“Describe what is happening in this picture.”',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildBadge('Category', 'Picture Description'),
                  const SizedBox(width: 12),
                  _buildBadge('Difficulty', 'Moderate', color: AppColors.warning),
                ],
              ),
              const SizedBox(height: 16),
              Text('Reason:', style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(
                '“Selected to encourage spontaneous vocabulary use and longer utterances while remaining appropriate for the child\'s recent performance.”',
                style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alternative topic generation requested (Mock)')),
                        );
                      },
                      child: const Text('Choose Another'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/c4/record');
                      },
                      child: const Text('Start Activity'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'AI personalization model recommendation',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
          Text(value, style: AppTextStyles.label.copyWith(color: color)),
        ],
      ),
    );
  }
}
