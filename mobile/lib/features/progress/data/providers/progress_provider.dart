import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';

class ProgressComponent {
  final String id;
  final String title;
  final String conclusion;
  final bool finalized;
  final bool available;

  const ProgressComponent({
    required this.id,
    required this.title,
    required this.conclusion,
    required this.finalized,
    this.available = true,
  });
}

class OverallProgress {
  /// improved | no_clear_change | needs_attention | insufficient_data
  final String status;
  final List<String> reasons;
  final int points;
  final String childId;
  final List<ProgressComponent> components;
  final bool firstSteps;
  final bool threeDayStreak;
  final bool speechBuddy;

  const OverallProgress({
    required this.status,
    required this.reasons,
    required this.points,
    required this.childId,
    required this.components,
    required this.firstSteps,
    required this.threeDayStreak,
    required this.speechBuddy,
  });

  int get finalizedCount =>
      components.where((component) => component.finalized).length;
  bool get allFinalized =>
      components.isNotEmpty && finalizedCount == components.length;

  String toReport() {
    final output = StringBuffer()
      ..writeln('SWARA - COMBINED PROGRESS REPORT')
      ..writeln('Child ID: $childId')
      ..writeln('Generated: ${DateTime.now().toLocal()}')
      ..writeln()
      ..writeln('OVERALL CONCLUSION: ${_verdictLabel(status)}')
      ..writeln(
          'Component conclusions: $finalizedCount/${components.length} final');

    for (final reason in reasons) {
      output.writeln('- $reason');
    }
    output.writeln();
    output.writeln('COMPONENT RESULTS');
    for (final component in components) {
      final state = !component.available
          ? 'DATA UNAVAILABLE'
          : component.finalized
              ? 'FINAL'
              : 'WAITING FOR FINAL RESULT';
      output.writeln();
      output.writeln('${component.id} - ${component.title} [$state]');
      output.writeln(component.conclusion);
    }
    output
      ..writeln()
      ..writeln(
          'This report supports progress discussions and is not a diagnosis.');
    return output.toString();
  }

  static String _verdictLabel(String value) => switch (value) {
        'improved' => 'Improved',
        'needs_attention' => 'Needs attention',
        'no_clear_change' => 'No clear change yet',
        'insufficient_data' => 'Not enough completed measurements yet',
        _ => 'Could not load the conclusion',
      };

  static const demo = OverallProgress(
    status: 'improved',
    reasons: [
      'Stuttering went down from 8.8% to 5.5% of syllables.',
      'Therapy sessions are going better (C3).',
    ],
    points: 6,
    childId: 'CH-001',
    components: [
      ProgressComponent(
        id: 'C1',
        title: 'කථන ප්‍රවාහය සහ ගොතගැසීම',
        conclusion: 'මධ්‍යම මට්ටම · නවතම කථන ප්‍රතිඵල තිබේ.',
        finalized: true,
      ),
      ProgressComponent(
        id: 'C2',
        title: 'ද්විතීයික හැසිරීම්',
        conclusion: 'ද්විතීයික හැසිරීම් දක්නට ලැබුණේ නැහැ.',
        finalized: true,
      ),
      ProgressComponent(
        id: 'C3',
        title: 'චිකිත්සක ක්‍රියාකාරකම්',
        conclusion: 'චිකිත්සක සාර්ථකත්ව ලකුණක් තිබේ.',
        finalized: true,
      ),
      ProgressComponent(
        id: 'C4',
        title: 'භාෂා ලක්ෂණ',
        conclusion: 'භාෂා නියැදි විශ්ලේෂණය කර ඇත.',
        finalized: true,
      ),
    ],
    firstSteps: true,
    threeDayStreak: true,
    speechBuddy: true,
  );
}

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

int _asInt(Object? value) => value is num ? value.toInt() : 0;

String _percent(Object? value) =>
    value is num ? '${value.toStringAsFixed(1)}%' : '—';

String _humanize(String? value) => switch (value) {
      'none_very_mild' => 'ඉතා සුළු',
      'mild' => 'සුළු',
      'moderate' => 'මධ්‍යම',
      'severe' => 'දැඩි',
      'gaining' => 'දියුණු වෙමින්',
      'stable' => 'ස්ථාවර',
      'below' => 'ආරම්භක මට්ටමට වඩා පහළ',
      'baseline_building' => 'ආරම්භක මට්ටම ගොඩනගමින්',
      _ => value ?? 'විශ්ලේෂණය අවසන්',
    };

final overallProgressProvider =
    FutureProvider.autoDispose<OverallProgress?>((ref) async {
  final child = ref.watch(activeChildProvider);
  if (StorageService.isDemoMode()) return OverallProgress.demo;
  if (child == null) return null;

  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/children/${child.childId}/progress');
  final payload = _asMap(response.data);
  final verdict = _asMap(payload['verdict']);
  final evidence = _asMap(payload['evidence']);
  final c1 = _asMap(evidence['c1']);
  final c2 = _asMap(evidence['c2']);
  // Read C2 from its own summary endpoint as well. Older deployed combined-progress
  // handlers may not yet include the latest C2 result, even though C2 has finished.
  try {
    final c2Response = await api.get('/api/c2/children/${child.childId}/summary');
    final c2Summary = _asMap(c2Response.data);
    if (c2Summary.isNotEmpty) {
      c2
        ..['available'] = true
        ..['flag'] = c2Summary['c2Flag']
        ..['hasVideo'] = c2Summary['hasVideo']
        ..['completedAnalyses'] = c2Summary['completedAnalyses']
        ..['notAssessedCount'] = c2Summary['notAssessedCount']
        ..['latest'] = c2Summary['latest']
        ..['trend'] = c2Summary['trend'];
    }
  } catch (_) {
    // Keep the combined response if the optional direct C2 summary is unavailable.
  }
  final c3 = _asMap(evidence['c3']);
  final c4 = _asMap(evidence['c4']);

  final c1Available = c1['available'] != false;
  final c1Count = _asInt(c1['assessments']);
  final c1Final = c1Available && c1Count > 0;
  final c1Conclusion = !c1Available
      ? 'දත්ත ලබාගත නොහැක.'
      : c1Final
          ? '${_humanize(c1['severity'] as String?)} · ${_percent(c1['latestPercentSS'])} %SS · අවසන් ඇගයීම් $c1Countක්.'
          : 'පළමු අවසන් කථන ඇගයීම බලාපොරොත්තුවෙන්.';

  final c2Available = c2['available'] != false;
  final c2Latest = _asMap(c2['latest']);
  final c2HasFinal = c2Latest.isNotEmpty;
  final c2Flag = c2['flag'] as String?;
  final c2Conclusion = !c2Available
      ? 'දත්ත ලබාගත නොහැක.'
      : !c2HasFinal
          ? 'අවසන් වීඩියෝ විශ්ලේෂණයක් බලාපොරොත්තුවෙන්.'
          : c2Flag == 'yes'
              ? 'ද්විතීයික හැසිරීම් දක්නට ලැබුණා.'
              : c2Flag == 'no'
                  ? 'ද්විතීයික හැසිරීම් දක්නට ලැබුණේ නැහැ.'
                  : c2Latest['status'] == 'not_assessed'
                      ? 'වීඩියෝව ඇගයීමට ලක් කර නැහැ.'
                      : 'විශ්ලේෂණය අවසන්; ඇගයිය හැකි ගොතගැසීම් අවස්ථා නොතිබුණා.';

  final c3Available = c3['available'] != false;
  final c3Latest = c3['tssLatest'];
  final c3Final = c3Available && c3Latest is num;
  final c3Conclusion = !c3Available
      ? 'දත්ත ලබාගත නොහැක.'
      : c3Final
          ? 'නවතම TSS ලකුණ ${c3Latest.toStringAsFixed(1)} · අවසන් සැසි ${_asInt(c3['sessions'])}ක්.'
          : 'අවසන් ලකුණක් සහිත චිකිත්සක සැසියක් බලාපොරොත්තුවෙන්.';

  final c4Available = c4['available'] != false;
  final c4Samples = _asInt(c4['samples']);
  final c4Final = c4Available && c4Samples > 0;
  final c4Percent = c4['latestPercentSS'];
  final c4Band = c4['band'] as String?;
  final c4SpeechDetail = c4Percent is num
      ? '${_percent(c4Percent)} spontaneous speech stuttered · '
      : '';
  final c4Conclusion = !c4Available
      ? 'දත්ත ලබාගත නොහැක.'
      : c4Final
          ? '${_humanize(c4Band)} · $c4SpeechDetailඅවසන් නියැදි $c4Samplesක්.'
          : 'පළමු අවසන් භාෂා නියැදිය බලාපොරොත්තුවෙන්.';

  final components = <ProgressComponent>[
    ProgressComponent(
        id: 'C1',
        title: 'කථන ප්‍රවාහය සහ ගොතගැසීම',
        conclusion: c1Conclusion,
        finalized: c1Final,
        available: c1Available),
    ProgressComponent(
        id: 'C2',
        title: 'ද්විතීයික හැසිරීම්',
        conclusion: c2Conclusion,
        finalized: c2Available && c2HasFinal,
        available: c2Available),
    ProgressComponent(
        id: 'C3',
        title: 'චිකිත්සක ක්‍රියාකාරකම්',
        conclusion: c3Conclusion,
        finalized: c3Final,
        available: c3Available),
    ProgressComponent(
        id: 'C4',
        title: 'භාෂා ලක්ෂණ',
        conclusion: c4Conclusion,
        finalized: c4Final,
        available: c4Available),
  ];

  Map<String, dynamic> c3Summary = {};
  try {
    c3Summary = _asMap(
        (await api.get('/api/c3/children/${child.childId}/summary')).data);
  } catch (_) {
    // The combined report still works if the optional achievement counters are unavailable.
  }
  final points = _asInt(_asMap(payload['percentSS'])['points']);

  return OverallProgress(
    status: verdict['status'] as String? ?? 'insufficient_data',
    reasons: [
      for (final reason in (verdict['reasons'] as List? ?? const []))
        reason.toString()
    ],
    points: points,
    childId: child.childId,
    components: components,
    firstSteps: _asInt(c3Summary['stars']) > 0,
    threeDayStreak: _asInt(c3Summary['streakDays']) >= 3,
    speechBuddy: points >= 5,
  );
});
