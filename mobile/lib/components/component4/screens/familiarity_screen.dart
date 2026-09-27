import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/screens/interest_selection.dart';

class FamiliarityScreen extends StatefulWidget {
  final List<InterestCategory> selectedCategories;

  const FamiliarityScreen({super.key, required this.selectedCategories});

  @override
  State<FamiliarityScreen> createState() => _FamiliarityScreenState();
}

class _FamiliarityScreenState extends State<FamiliarityScreen> {
  int _currentIndex = 0;
  int? _selectedFamiliarity;
  final Map<String, int> _familiarityScores = {};

  final List<Map<String, dynamic>> familiarityLevels = [
    {'score': 1, 'sinhala': 'හුරු නැහැ', 'english': 'Not familiar'},
    {'score': 2, 'sinhala': 'ටිකක්', 'english': 'A little'},
    {'score': 3, 'sinhala': 'මධ්‍යමයි', 'english': 'Somewhat'},
    {'score': 4, 'sinhala': 'ගොඩක් හුරුයි', 'english': 'Very familiar'},
    {'score': 5, 'sinhala': 'මම ගොඩක් දන්නවා!', 'english': 'I know a lot!'},
  ];

  void _nextCategory() {
    if (_selectedFamiliarity != null) {
      _familiarityScores[widget.selectedCategories[_currentIndex].id] = _selectedFamiliarity!;
      if (_currentIndex < widget.selectedCategories.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedFamiliarity = null;
        });
      } else {
        context.push('/c4/personalization_processing', extra: {
          'categories': widget.selectedCategories,
          'scores': _familiarityScores,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCategories.isEmpty) return const SizedBox();

    final currentCategory = widget.selectedCategories[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 3, totalSteps: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'මේ දේවල් ගැන ඔයාට කොච්චර හුරුද?',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How familiar are these things to you?',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Interest ${_currentIndex + 1} of ${widget.selectedCategories.length}',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.lgAll,
                        boxShadow: AppElevation.card,
                        image: DecorationImage(
                          image: AssetImage(currentCategory.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.lgAll,
                          gradient: LinearGradient(
                            colors: [Colors.transparent, AppColors.deepNavy.withOpacity(0.8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentCategory.sinhalaName,
                              style: AppTextStyles.heading2.copyWith(color: AppColors.white),
                            ),
                            Text(
                              currentCategory.englishName,
                              style: AppTextStyles.body.copyWith(color: AppColors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'මේ ගැන ඔයා කොච්චර දන්නවාද?',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How much do you know about this?',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ...familiarityLevels.map((level) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFamiliarity = level['score'];
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedFamiliarity == level['score'] ? AppColors.primaryWash : AppColors.surfaceRaised,
                                borderRadius: AppRadii.mdAll,
                                border: Border.all(
                                  color: _selectedFamiliarity == level['score'] ? AppColors.primary : AppColors.divider,
                                  width: 2,
                                ),
                                boxShadow: _selectedFamiliarity == level['score'] ? [] : AppElevation.card,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _selectedFamiliarity == level['score'] ? AppColors.primary : AppColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      level['score'].toString(),
                                      style: TextStyle(
                                        color: _selectedFamiliarity == level['score'] ? AppColors.white : AppColors.textLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          level['sinhala'],
                                          style: AppTextStyles.titleMedium.copyWith(
                                            color: _selectedFamiliarity == level['score'] ? AppColors.primaryDeep : AppColors.text,
                                          ),
                                        ),
                                        Text(
                                          level['english'],
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: ElevatedButton(
                onPressed: _selectedFamiliarity == null ? null : _nextCategory,
                child: Text(_currentIndex < widget.selectedCategories.length - 1 ? 'Next' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
