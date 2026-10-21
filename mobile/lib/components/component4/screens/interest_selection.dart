import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';

class InterestCategory {
  final String id;
  final String sinhalaName;
  final String englishName;

  /// Null for topic-bank categories the app has no picture for; [icon] is shown instead.
  final String? imagePath;
  final String icon;

  InterestCategory({
    required this.id,
    required this.sinhalaName,
    required this.englishName,
    this.imagePath,
    this.icon = '⭐',
  });

  // Pictures the app already has, by topic-bank category id.
  static const images = {
    'animals': 'assets/images/component3/lion_mascot.jpg',
    'animals-and-wildlife': 'assets/images/component3/lion_mascot.jpg',
    'sports': 'assets/images/component3/milo_trophy.jpg',
    'food': 'assets/images/component3/sugarbear_mascot.jpg',
    'food-and-cooking': 'assets/images/component3/sugarbear_mascot.jpg',
    'school': 'assets/images/component4/c4_swara_bot.png',
    'school-life': 'assets/images/component4/c4_swara_bot.png',
    'games-and-toys': 'assets/images/component4/c4_celebration.png',
    'drawing-and-colours': 'assets/images/component4/c4_picture_story.png',
    'art-and-design': 'assets/images/component4/c4_picture_story.png',
    'music': 'assets/images/home/talk_card.png',
    'music-and-dance': 'assets/images/home/talk_card.png',
    'nature-and-garden': 'assets/images/component3/magical_forest_bg.jpg',
    'environment': 'assets/images/component3/magical_forest_bg.jpg',
    'space-and-stars': 'assets/images/component3/space_bg.jpg',
    'the-sea-and-beach': 'assets/images/component3/beach_bg.jpg',
    'holidays-and-trips': 'assets/images/component3/beach_bg.jpg',
    'travel-and-places': 'assets/images/component3/beach_bg.jpg',
    'cartoons-and-stories': 'assets/images/home/story_card.png',
    'books-and-stories': 'assets/images/home/story_card.png',
    'family': 'assets/images/park_family.png',
  };

  factory InterestCategory.fromC4(C4Category c) =>
      InterestCategory(id: c.id, sinhalaName: c.si, englishName: c.en, imagePath: images[c.id], icon: c.icon);
}

/// The category's picture, or its emoji on a soft background when the app has no picture.
class InterestImage extends StatelessWidget {
  final InterestCategory category;
  const InterestImage(this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    final path = category.imagePath;
    if (path != null) return Image.asset(path, fit: BoxFit.cover);
    return Container(
      color: AppColors.primaryWash,
      alignment: Alignment.center,
      child: Text(category.icon, style: const TextStyle(fontSize: 56)),
    );
  }
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
  bool _loading = false;
  String? _error;

  // A live session ranks exactly 5 of the topic bank's categories for the child's age band.
  bool get _needsExactlyFive => C4Flow.isLive;

  @override
  void initState() {
    super.initState();
    if (C4Flow.isLive) _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await C4Flow.loadCategories();
      if (!mounted) return;
      setState(() {
        categories
          ..clear()
          ..addAll(list.map(InterestCategory.fromC4));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException.from(e).message;
        _loading = false;
      });
    }
  }

  void _continue() {
    if (C4Flow.isLive) {
      C4Flow.ranked = [
        for (final c in _selectedCategories) C4Category(id: c.id, si: c.sinhalaName, en: c.englishName, icon: c.icon),
      ];
    }
    // The order is the child's own ranking (1st = most favourite); no familiarity rating.
    context.push('/c4/personalization_processing');
  }

  static String _ordinal(int n) => switch (n) { 1 => '1st', 2 => '2nd', 3 => '3rd', _ => '${n}th' };

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
            const C4Header(currentStep: 2, totalSteps: 14),
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
                    _needsExactlyFive
                        ? 'ඔයා කැමතිම දේවල් 5ක් තෝරන්න: වැඩියෙන්ම කැමති එක මුලින්ම.\nPick your 5 favourites, most favourite first.'
                        : 'ඔයා කැමති දේවල් 5ක් දක්වා තෝරන්න.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _loadCategories, child: const Text('Try again')),
                  ]),
                ),
              )
            else
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
                          InterestImage(category),
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
                                      _ordinal(selectionIndex),
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_selectedCategories.length == 5) ...[
                  Text('ඔයාගේ පිළිවෙළ · Your ranking (drag to change)', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 5 * 40,
                    child: ReorderableListView(
                      buildDefaultDragHandles: false,
                      onReorder: (from, to) => setState(() {
                        final item = _selectedCategories.removeAt(from);
                        _selectedCategories.insert(to > from ? to - 1 : to, item);
                      }),
                      children: [
                        for (var i = 0; i < _selectedCategories.length; i++)
                          SizedBox(
                            key: ValueKey(_selectedCategories[i].id),
                            height: 40,
                            child: Row(children: [
                              SizedBox(width: 36, child: Text(_ordinal(i + 1), style: AppTextStyles.label.copyWith(color: AppColors.primary))),
                              Expanded(child: Text('${_selectedCategories[i].sinhalaName} · ${_selectedCategories[i].englishName}')),
                              ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedCategories.isEmpty || (_needsExactlyFive && _selectedCategories.length < 5)
                        ? null
                        : _continue,
                    child: const Text('Continue'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
