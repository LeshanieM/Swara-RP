import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class PersonalizedQuestionScreen extends StatefulWidget {
  const PersonalizedQuestionScreen({super.key});

  @override
  State<PersonalizedQuestionScreen> createState() => _PersonalizedQuestionScreenState();
}

class _PersonalizedQuestionScreenState extends State<PersonalizedQuestionScreen> {
  bool _showResearchView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 6, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'ඔයා වෙනුවෙන් විශේෂයෙන් සකස් කළ ප්‍රශ්නයක්',
                      style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A question just for you',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                        border: Border.all(color: AppColors.primaryWash, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.format_quote_rounded, color: AppColors.primary.withOpacity(0.5), size: 48),
                          const SizedBox(height: 16),
                          Text(
                            '“ඔයාගේ ප්‍රියතම බල්ලා එක්ක දවසක්ම ගත කරන්න පුළුවන් නම්, ඔයා දෙන්නා මොනවා කරයිද?”',
                            style: AppTextStyles.heading2.copyWith(color: AppColors.text, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'නිවැරදි හෝ වැරදි පිළිතුරක් නැහැ.',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textLight),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'There is no right or wrong answer.',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: AppRadii.lgAll,
                      child: Image.asset(
                        'assets/images/spontaneous_friends.png',
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.push('/c4/preparation'),
                      child: const Text('කතා කරමු (Let\'s Talk)'),
                    ),
                    const SizedBox(height: 32),
                    // Research View
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'Research View',
                          style: AppTextStyles.label.copyWith(color: AppColors.textLight),
                        ),
                        leading: const Icon(Icons.science, color: AppColors.textLight),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _showResearchView = expanded;
                          });
                        },
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: AppRadii.mdAll,
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildResearchRow('Base Topic', 'Animals'),
                                _buildResearchRow('Child Interest', 'Dogs'),
                                _buildResearchRow('Familiarity', '5 / 5'),
                                _buildResearchRow('Age', '9'),
                                _buildResearchRow('Question', 'Personalized'),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildResearchRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
