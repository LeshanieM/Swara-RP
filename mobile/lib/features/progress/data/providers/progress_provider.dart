import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';

/// One line per component for the "Clinical Summary" card.
class ClinicalSummary {
  final String c1;
  final String c2;
  final String c3;
  final String c4;
  const ClinicalSummary({required this.c1, required this.c2, required this.c3, required this.c4});

  static const demo = ClinicalSummary(
    c1: 'Moderate',
    c2: 'Research analysis',
    c3: 'Storytelling',
    c4: 'Increasing lexical diversity',
  );
}

const _notYet = 'Not assessed yet';

String _trend(String? t) => switch (t) {
      'improving' => 'improving',
      'needs_attention' => 'needs attention',
      'stable' => 'stable',
      _ => '',
    };

String _withTrend(String text, String? trend) => _trend(trend).isEmpty ? text : '$text (${_trend(trend)})';

/// The active child's latest result from each component's summary on the API.
final clinicalSummaryProvider = FutureProvider.autoDispose<ClinicalSummary>((ref) async {
  final child = ref.watch(activeChildProvider);
  if (StorageService.isDemoMode() || child == null) return ClinicalSummary.demo;
  final api = ref.read(apiClientProvider);
  Future<Map<String, dynamic>?> get(String path) async {
    try {
      return Map<String, dynamic>.from((await api.get(path)).data as Map);
    } catch (_) {
      return null;
    }
  }

  final id = child.childId;
  final results = await Future.wait([
    get('/api/c1/children/$id/summary'),
    get('/api/c2/children/$id/summary'),
    get('/api/c3/children/$id/summary'),
    get('/api/c4/children/$id/summary'),
  ]);
  final (c1, c2, c3, c4) = (results[0], results[1], results[2], results[3]);

  const severity = {'none_very_mild': 'Very mild', 'mild': 'Mild', 'moderate': 'Moderate', 'severe': 'Severe'};
  final latest = c1?['latest'] as Map?;
  final c1Line = latest == null
      ? _notYet
      : _withTrend(
          '${severity[latest['severity']] ?? latest['severity']} · ${(latest['percentSS'] as num?)?.toStringAsFixed(1) ?? '—'} %SS',
          (c1?['byTask'] as Map?)?[latest['taskType']]?['trend'] as String?,
        );

  final c2Line = switch (c2?['c2Flag']) {
    'yes' => 'Secondary behaviours seen',
    'no' => 'No secondary behaviours seen',
    _ => _notYet,
  };

  final tss = c3?['tss'] as Map?;
  final c3Line = tss?['latest'] == null ? _notYet : _withTrend('Therapy Success Score ${tss!['latest']}', tss['trend'] as String?);

  const bands = {
    'gaining': 'Gaining',
    'stable': 'Stable',
    'below': 'Below usual level',
    'baseline_building': 'Building the starting level',
    'not_reliable': 'Answer too short to judge',
  };
  final pss = (c4?['stuttering']?['spontaneousPercentSS'] as num?)?.toStringAsFixed(1);
  final c4Line = (c4?['completedSamples'] as num? ?? 0) == 0
      ? _notYet
      : _withTrend('${bands[c4!['band']] ?? 'Sample analysed'}${pss == null ? '' : ' · $pss %SS'}', c4['trend'] as String?);

  return ClinicalSummary(c1: c1Line, c2: c2Line, c3: c3Line, c4: c4Line);
});

/// The overall verdict across C1–C4 (GET /api/children/:id/progress) and the earned achievements.
class OverallProgress {
  /// improved | no_clear_change | needs_attention | insufficient_data
  final String status;
  final List<String> reasons;
  final int points;
  final bool firstSteps; // at least one therapy activity done
  final bool threeDayStreak; // 3 days in a row with a completed therapy session
  final bool speechBuddy; // 5 speech samples (C1 assessments + C4 answers)
  const OverallProgress({
    required this.status,
    required this.reasons,
    required this.points,
    required this.firstSteps,
    required this.threeDayStreak,
    required this.speechBuddy,
  });

  static const demo = OverallProgress(
    status: 'improved',
    reasons: ['Stuttering went down from 8.8% to 5.5% of syllables.', 'Therapy sessions are going better (C3).'],
    points: 6,
    firstSteps: true,
    threeDayStreak: true,
    speechBuddy: true,
  );
}

final overallProgressProvider = FutureProvider.autoDispose<OverallProgress?>((ref) async {
  final child = ref.watch(activeChildProvider);
  if (StorageService.isDemoMode() || child == null) return OverallProgress.demo;
  final api = ref.read(apiClientProvider);
  try {
    final res = await Future.wait([
      api.get('/api/children/${child.childId}/progress'),
      api.get('/api/c3/children/${child.childId}/summary'),
    ]);
    final p = Map<String, dynamic>.from(res[0].data as Map);
    final c3 = Map<String, dynamic>.from(res[1].data as Map);
    final verdict = p['verdict'] as Map? ?? const {};
    final points = (p['percentSS']?['points'] as num?)?.toInt() ?? 0;
    return OverallProgress(
      status: verdict['status'] as String? ?? 'insufficient_data',
      reasons: [for (final r in (verdict['reasons'] as List? ?? const [])) r.toString()],
      points: points,
      firstSteps: ((c3['stars'] as num?) ?? 0) > 0,
      threeDayStreak: ((c3['streakDays'] as num?) ?? 0) >= 3,
      speechBuddy: points >= 5,
    );
  } catch (_) {
    return null;
  }
});
