/// The C1 task for the child's age band, from GET /api/c1/tasks.
class SpeechTask {
  final String taskType; // picture_description | reading
  final String ageBand; // 5-10 | 11-14
  final List<SpeechPassage> passages;
  final List<SpeechPicture> pictures;

  const SpeechTask({required this.taskType, required this.ageBand, this.passages = const [], this.pictures = const []});

  bool get isReading => taskType == 'reading';

  factory SpeechTask.fromJson(Map<String, dynamic> json) => SpeechTask(
        taskType: json['taskType'] ?? 'picture_description',
        ageBand: json['ageBand'] ?? '',
        passages: [for (final p in (json['passages'] as List? ?? const [])) SpeechPassage.fromJson(p)],
        pictures: [for (final p in (json['pictures'] as List? ?? const [])) SpeechPicture.fromJson(p)],
      );
}

class SpeechPassage {
  final String id;
  final String language;
  final String title;
  final String text;

  const SpeechPassage({required this.id, required this.language, required this.title, required this.text});

  factory SpeechPassage.fromJson(Map<String, dynamic> json) => SpeechPassage(
        id: json['id'] ?? '',
        language: json['language'] ?? 'si',
        title: json['title'] ?? '',
        text: json['text'] ?? '',
      );
}

class SpeechPicture {
  final String id;
  final String? imageRef;
  final String promptSi;
  final String promptEn;

  const SpeechPicture({required this.id, this.imageRef, required this.promptSi, required this.promptEn});

  factory SpeechPicture.fromJson(Map<String, dynamic> json) => SpeechPicture(
        id: json['id'] ?? '',
        imageRef: json['imageRef'],
        promptSi: json['prompt']?['si'] ?? '',
        promptEn: json['prompt']?['en'] ?? '',
      );
}

/// What the C1 result screen shows, read from a completed assessment's `result`.
class SpeechResult {
  final double? durationSec;
  final int totalSyllables;
  final int stutteredSyllables;
  final double percentSS;
  final int repetitions;
  final int prolongations;
  final int blocks;
  final int interjections;
  final String typeEn;
  final String typeSi;
  final String severityEn;
  final String severitySi;
  final bool provisional;
  final List<String> warnings;

  const SpeechResult({
    this.durationSec,
    required this.totalSyllables,
    required this.stutteredSyllables,
    required this.percentSS,
    required this.repetitions,
    required this.prolongations,
    required this.blocks,
    this.interjections = 0,
    required this.typeEn,
    required this.typeSi,
    required this.severityEn,
    required this.severitySi,
    this.provisional = true,
    this.warnings = const [],
  });

  static const _types = {
    'sound_repetition': ('Repetition', 'පුනරාවර්තනය'),
    'word_repetition': ('Repetition', 'පුනරාවර්තනය'),
    'prolongation': ('Prolongation', 'දිගු කිරීම'),
    'block': ('Block', 'අවහිරවීම'),
    'interjection': ('Interjection', 'අතරමැදි ශබ්ද'),
  };

  static const _severitySi = {
    'none_very_mild': 'ඉතා මෘදු',
    'mild': 'මෘදු',
    'moderate': 'මධ්‍යම',
    'severe': 'දැඩි',
  };

  factory SpeechResult.fromResult(Map<String, dynamic> r) {
    final counts = (r['counts'] as Map?) ?? const {};
    int count(String k) => (counts[k] as num?)?.toInt() ?? 0;
    // summary.stutterType groups sound and word repetitions and says "Mixed" on a tie.
    final grouped = (r['summary'] as Map?)?['stutterType'];
    final type = grouped == 'Mixed'
        ? ('Mixed', 'මිශ්‍ර')
        : _types[r['primaryType']] ?? ('None', 'කිසිවක් නැත');
    final severity = (r['severity'] as Map?) ?? const {};
    return SpeechResult(
      durationSec: (r['audio']?['durationSec'] as num?)?.toDouble(),
      totalSyllables: (r['syllables']?['total'] as num?)?.toInt() ?? 0,
      stutteredSyllables: (r['stutteredSyllables'] as num?)?.toInt() ?? 0,
      percentSS: (r['percentSS'] as num?)?.toDouble() ?? 0,
      repetitions: count('soundRepetition') + count('wordRepetition'),
      prolongations: count('prolongation'),
      blocks: count('block'),
      interjections: count('interjection'),
      typeEn: type.$1,
      typeSi: type.$2,
      severityEn: severity['displayLabel'] ?? r['summary']?['severity'] ?? '—',
      severitySi: _severitySi[severity['label']] ?? '',
      provisional: severity['provisional'] ?? true,
      warnings: [for (final w in (r['warnings'] as List? ?? const [])) (w['message'] ?? w['code']).toString()],
    );
  }

  /// The values the result screen showed before it was connected (demo mode).
  static const demo = SpeechResult(
    totalSyllables: 312,
    stutteredSyllables: 24,
    percentSS: 7.7,
    repetitions: 12,
    prolongations: 5,
    blocks: 3,
    typeEn: 'Repetition',
    typeSi: 'පුනරාවර්තනය',
    severityEn: 'Moderate',
    severitySi: 'මධ්‍යම',
  );
}

/// Passed from the task screen through the completion screen to the result screen.
class SpeechSubmission {
  final int durationSeconds;

  /// Null in demo mode (nothing was uploaded).
  final String? assessmentId;

  const SpeechSubmission({required this.durationSeconds, this.assessmentId});
}
