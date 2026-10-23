import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/components/component4/screens/interest_selection.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/components/component4/services/c4_service.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/widgets/parent_pin_dialog.dart';

class NextSessionScreen extends ConsumerStatefulWidget {
  const NextSessionScreen({super.key});

  @override
  ConsumerState<NextSessionScreen> createState() => _NextSessionScreenState();
}

class _NextSessionScreenState extends ConsumerState<NextSessionScreen> {
  Map<String, dynamic>? _summary;
  bool _savingBand = false;

  static const _bands = {
    'gaining': 'දියුණු වෙමින්',
    'stable': 'ස්ථාවර',
    'below': 'සාමාන්‍ය මට්ටමට වඩා පහළ',
    'baseline_building': 'ආරම්භක මට්ටම සකසමින්',
    'not_reliable': 'තීරණය කිරීමට පිළිතුර ඉතා කෙටියි',
  };

  // The bands a parent can confirm or choose; the others (baseline, too short) are not judgements.
  static const _comparable = ['below', 'stable', 'gaining'];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    final child = C4Flow.child;
    if (C4Flow.isLive && child != null) {
      C4Service.summary(child.childId).then((s) {
        if (mounted) setState(() => _summary = s);
      }).catchError((_) {});
    }
  }

  /// The parent agrees with the band, or picks another one; an override becomes the band shown everywhere.
  Future<void> _reviewBand(String sampleId, String decision, {String? band}) async {
    if (!await ensureParentMode(context, ref)) return;
    setState(() => _savingBand = true);
    try {
      await C4Service.confirmBand(sampleId, decision, band: band);
      _loadSummary();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiException.from(e).message)));
    } finally {
      if (mounted) setState(() => _savingBand = false);
    }
  }

  Widget _bandReview() {
    final latest = _summary?['latest'] as Map?;
    final sampleId = latest?['sampleId'] as String?;
    final computed = latest?['bandComputed'] as String?;
    if (sampleId == null || !_comparable.contains(computed)) return const SizedBox.shrink();
    final current = latest?['band'] as String?;
    final confirmed = latest?['bandConfirmed'] == true;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.lgAll,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('දෙමාපියන් සඳහා: මෙය නිවැරදි ලෙස පෙනෙනවාද?', style: AppTextStyles.label),
        const SizedBox(height: 4),
        Text(
          confirmed
              ? 'සුරකින ලදී: ${_bands[current]}.'
              : 'දරුවාගේ ආරම්භක මට්ටම සමඟ සැසඳූ විට අද මට්ටම: ${_bands[computed]}.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final b in _comparable)
            ChoiceChip(
              label: Text(_bands[b]!),
              selected: current == b,
              onSelected: _savingBand
                  ? null
                  : (_) => b == computed ? _reviewBand(sampleId, 'confirm') : _reviewBand(sampleId, 'override', band: b),
            ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = C4Flow.view;
    final live = C4Flow.isLive;
    final currentId = C4Flow.session?['topic']?['categoryId'] as String?;
    // Another of the child's favourite categories: the next topic is drawn from these.
    final nextId = C4Flow.rankedIds.where((id) => id != currentId).firstOrNull;
    final nextTitle = live
        ? (C4Flow.categories.where((c) => c.id == nextId).map((c) => c.si).firstOrNull ?? 'වෙනත් මාතෘකාවක්')
        : 'ක්‍රීඩා';
    final nextRank = live ? (nextId == null ? null : C4Flow.rankedIds.indexOf(nextId) + 1) : 2;
    final concrete = C4Flow.session?['progressSignal']?['preferConcrete'] == true;
    final band = _bands[_summary?['band']];
    return Scaffold(
      backgroundColor: AppColors.groundHome,
      body: SafeArea(
        child: Column(
          children: [
            const C4Header(currentStep: 14, totalSteps: 14),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'ඊළඟ වතාවේ',
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ඊළඟ වතාවේ',
                      style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ඔයාගේ පෙර සැසියේ තොරතුරු භාවිත කර ඊළඟ කථන ක්‍රියාකාරකම පුද්ගලීකරණය කළ හැක.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'පෙර සැසියේ තොරතුරු අනුව ඊළඟ කථන ක්‍රියාකාරකම සකසමු.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Previous Topic
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: AppRadii.lgAll,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadii.mdAll,
                            child: Image.asset(
                              live
                                  ? InterestCategory.images[currentId] ?? 'assets/images/spontaneous_friends.png'
                                  : 'assets/images/component3/lion_mascot.jpg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.categorySi, style: AppTextStyles.titleLarge),
                                Text('පෙර මාතෘකාව', style: AppTextStyles.caption),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text('කැමතිම ${v.categoryRank ?? '—'} වන වර්ගය · 5න්', style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                    const SizedBox(width: 4),
                                    Text('තත්ත්වය: සම්පූර්ණයි', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Icon(Icons.arrow_downward, color: AppColors.primary, size: 32),
                    ),

                    // Next Topic
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        borderRadius: AppRadii.lgAll,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: AppElevation.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDeep,
                              borderRadius: AppRadii.xsAll,
                            ),
                            child: Text(
                              'ඊළඟට ගැළපෙන ක්‍රියාකාරකම',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: AppRadii.mdAll,
                                child: Image.asset(
                                  live
                                      ? InterestCategory.images[nextId] ?? 'assets/images/spontaneous_friends.png'
                                      : 'assets/images/component3/milo_trophy.jpg',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nextTitle, style: AppTextStyles.titleLarge),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_half, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 4),
                                        Text('කැමතිම ${nextRank ?? '—'} වන වර්ගය · 5න්', style: AppTextStyles.caption),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('ප්‍රශ්න ආකාරය:', style: AppTextStyles.caption),
                                    Text(
                                      concrete ? 'සරල සහ පැහැදිලි' : 'සරල සිට විවෘත ප්‍රශ්න දක්වා',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.bold),
                                    ),
                                    if (band != null) ...[
                                      const SizedBox(height: 8),
                                      Text('භාෂා මට්ටම: $band', style: AppTextStyles.caption),
                                    ],
                                    if (_summary?['stuttering']?['spontaneousPercentSS'] is num) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                          'මෙම පිළිතුරේ පැකිළීම්: ${(_summary!['stuttering']['spontaneousPercentSS'] as num).toStringAsFixed(1)} %SS',
                                          style: AppTextStyles.caption),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (live) _bandReview(),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('ක්‍රියාකාරකම අවසන් කරන්න'),
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
}
