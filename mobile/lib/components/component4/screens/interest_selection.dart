import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class InterestCategory {
  final String id;
  final String sinhalaName;
  final String? englishName;
  final String imagePath;

  const InterestCategory({
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
  int _age = 10;

  List<InterestCategory> get categories =>
      _age <= 10 ? _youngerCategories : _olderCategories;

  static const List<String> _youngerNames = [
    'මගේ යාළුවෝ', 'මගේ පවුල', 'මගේ සෙල්ලම්', 'මගේ පාසල',
    'මගේ කැමතිම කෑම', 'සුරතල් සතුන්', 'ක්‍රීඩා', 'කාටූන් සහ ළමා වැඩසටහන්',
    'කතා සහ පොත්', 'චිත්‍ර සහ අත්කම්', 'සංගීතය සහ නැටුම්', 'උපන්දිනය සහ තෑගි',
    'උත්සව', 'ගමන් බිමන්', 'මගේ ගෙදර', 'දිනපතා කරන වැඩ',
    'මගේ ප්‍රියතම දේවල්', 'මගේ අත්දැකීම්', 'මම භාවිත කරන දේවල්', 'ස්වභාවික පරිසරය',
  ];

  static const List<String> _olderNames = [
    'මගේ යාළුවෝ', 'මගේ පවුල', 'පාසල් ජීවිතය', 'විනෝදාංශ', 'ක්‍රීඩා',
    'සංගීතය', 'චිත්‍රපට සහ කතා', 'පොත් සහ කියවීම', 'දුරකථන සහ Apps',
    'මට උදව් කරන පුද්ගලයෝ', 'දිනපතා ජීවිතය', 'ගමන් බිමන්', 'විශේෂ අවස්ථා',
    'කෑම සහ ආහාර', 'සතුන් සහ සොබාදහම', 'පාසල් වැඩසටහන් සහ කණ්ඩායම් වැඩ',
    'අලුත් දේවල් ඉගෙනීම', 'අත්දැකීම් සහ ගැටලු විසඳීම', 'සතුටුදායක මතක',
    'මගේ අනාගත බලාපොරොත්තු',
  ];

  static const List<String> _images = [
    'assets/images/park_family.png', 'assets/images/component3/milo_trophy.jpg',
    'assets/images/component4/c4_swara_bot.png', 'assets/images/component4/c4_celebration.png',
    'assets/images/component4/c4_picture_story.png', 'assets/images/home/talk_card.png',
    'assets/images/component3/lion_mascot.jpg', 'assets/images/home/story_card.png',
    'assets/images/component3/sugarbear_mascot.jpg', 'assets/images/component3/magical_forest_bg.jpg',
    'assets/images/component3/beach_bg.jpg', 'assets/images/component3/space_bg.jpg',
  ];

  static List<InterestCategory> _makeAgeCategories(List<String> names, String prefix) => [
        for (var index = 0; index < names.length; index++)
          InterestCategory(
            id: '${prefix}_$index',
            sinhalaName: names[index],
            englishName: null,
            imagePath: _images[index % _images.length],
          ),
      ];

  static final List<InterestCategory> _youngerCategories =
      _makeAgeCategories(_youngerNames, 'age5_10');
  static final List<InterestCategory> _olderCategories =
      _makeAgeCategories(_olderNames, 'age11_14');

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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('වයස:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _age,
                        items: [
                          for (var age = 5; age <= 14; age++)
                            DropdownMenuItem(value: age, child: Text('$age')),
                        ],
                        onChanged: (age) {
                          if (age == null) return;
                          setState(() {
                            _age = age;
                            _selectedCategories.clear();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(_age <= 10 ? '(5–10)' : '(11–14)'),
                    ],
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
                    'මුලින්ම ඔයා මෙතන තියෙන category 20 බලන්න. බලලා ඒ අතරින් ඔයා කැමතිම දේවල් 5ක්, ඔයාගේ කැමැත්ත වැඩිම එකේ සිට පිළිවෙළට තෝරන්න.',
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
                      transform: Matrix4.identity()
                        ..scaleByDouble(
                          isSelected ? 0.96 : 1.0,
                          isSelected ? 0.96 : 1.0,
                          1.0,
                          1.0,
                        ),
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
                                  AppColors.deepNavy.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                                if (category.englishName != null)
                                  Text(
                                    category.englishName!,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.white.withValues(alpha: 0.9),
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
