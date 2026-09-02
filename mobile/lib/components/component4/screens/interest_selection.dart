import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class InterestCategory {
  final String id;
  final String sinhalaName;
  final String englishName;
  final String imagePath;

  InterestCategory({
    required this.id,
    required this.sinhalaName,
    required this.englishName,
    required this.imagePath,
  });
}

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<InterestCategory> categories = [
    InterestCategory(id: 'animals', sinhalaName: 'සතුන්', englishName: 'Animals', imagePath: 'assets/images/component3/lion_mascot.jpg'),
    InterestCategory(id: 'sports', sinhalaName: 'ක්‍රීඩා', englishName: 'Sports', imagePath: 'assets/images/component3/milo_trophy.jpg'),
    InterestCategory(id: 'food', sinhalaName: 'කෑම', englishName: 'Food', imagePath: 'assets/images/component3/sugarbear_mascot.jpg'),
    InterestCategory(id: 'school', sinhalaName: 'පාසල', englishName: 'School', imagePath: 'assets/images/component4/c4_swara_bot.png'),
    InterestCategory(id: 'games', sinhalaName: 'සෙල්ලම්', englishName: 'Games & Toys', imagePath: 'assets/images/component4/c4_celebration.png'),
    InterestCategory(id: 'art', sinhalaName: 'චිත්‍ර හා කලාව', englishName: 'Art', imagePath: 'assets/images/component4/c4_picture_story.png'),
    InterestCategory(id: 'music', sinhalaName: 'සංගීතය', englishName: 'Music', imagePath: 'assets/images/home/talk_card.png'),
    InterestCategory(id: 'nature', sinhalaName: 'ස්වභාවය', englishName: 'Nature', imagePath: 'assets/images/component3/magical_forest_bg.jpg'),
    InterestCategory(id: 'vehicles', sinhalaName: 'වාහන', englishName: 'Vehicles', imagePath: 'assets/images/component3/space_bg.jpg'),
    InterestCategory(id: 'travel', sinhalaName: 'ගමන් බිමන්', englishName: 'Travel & Places', imagePath: 'assets/images/component3/beach_bg.jpg'),
    InterestCategory(id: 'stories', sinhalaName: 'කතා හා පොත්', englishName: 'Stories & Books', imagePath: 'assets/images/home/story_card.png'),
    InterestCategory(id: 'family', sinhalaName: 'පවුල', englishName: 'Family', imagePath: 'assets/images/park_family.png'),
  ];

  final List<InterestCategory> _selectedCategories = [];

  void _toggleCategory(InterestCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        if (_selectedCategories.length < 5) {
          _selectedCategories.add(category);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 categories allowed.')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 2, totalSteps: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  Text(
                    'ඔයා කැමති මොනවාටද?',
                    style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What do you like?',
                    style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWash,
                      borderRadius: AppRadii.pillAll,
                    ),
                    child: Text(
                      '${_selectedCategories.length} / 5 selected',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ඔයා කැමති දේවල් 5ක් දක්වා තෝරන්න.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategories.contains(category);
                  final selectionIndex = isSelected ? _selectedCategories.indexOf(category) + 1 : 0;

                  return GestureDetector(
                    onTap: () => _toggleCategory(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: Matrix4.identity()..scale(isSelected ? 0.96 : 1.0),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.lgAll,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected ? [] : AppElevation.card,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            category.imagePath,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.deepNavy.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.sinhalaName,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  category.englishName,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, color: AppColors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectionIndex.toString(),
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: ElevatedButton(
                onPressed: _selectedCategories.isEmpty
                    ? null
                    : () {
                        context.push('/c4/familiarity', extra: _selectedCategories);
                      },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
