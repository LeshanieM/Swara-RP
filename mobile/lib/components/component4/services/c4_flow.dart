import 'package:swara/core/audio/wav_recorder.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/auth/data/models/user_model.dart';
import 'c4_service.dart';

/// One interest category from the topic bank.
class C4Category {
  final String id;
  final String si;
  final String en;
  final String icon;
  const C4Category({required this.id, required this.si, required this.en, this.icon = '⭐'});

  factory C4Category.fromJson(Map<String, dynamic> json) => C4Category(
        id: json['id'] as String,
        si: json['title']?['si'] ?? json['id'],
        en: json['title']?['en'] ?? json['id'],
        icon: json['icon'] ?? '⭐',
      );
}

/// What the C4 screens show for one session. Demo mode uses [C4View.demo], the values the
/// screens had before they were connected; live sessions fill it from the API.
class C4View {
  final String topicSi;
  final String topicEn;
  final String categorySi;
  final String categoryEn;
  final String ageBand;
  final String level;
  final int? categoryRank;
  final double? probability;
  final String questionSi;
  final String transcript;
  final String transcriptKind;
  final double? durationSec;
  final int utterances;
  final int totalWords;
  final int ndw;
  final double? mlu;
  final List<String> flags;

  /// `personalised`, or `fixed` for a session from the fixed topic sequence.
  final String mode;

  /// Stuttered syllables per 100 in this answer, from C1's model (C4 sends every recording to C1); null when C1
  /// could not assess it.
  final double? percentSS;

  const C4View({
    required this.topicSi,
    required this.topicEn,
    required this.categorySi,
    required this.categoryEn,
    required this.ageBand,
    required this.level,
    this.categoryRank,
    this.probability,
    required this.questionSi,
    this.transcript = '',
    this.transcriptKind = 'asr',
    this.durationSec,
    this.utterances = 0,
    this.totalWords = 0,
    this.ndw = 0,
    this.mlu,
    this.flags = const [],
    this.mode = 'personalised',
    this.percentSS,
  });

  bool get isFixed => mode == 'fixed';

  static const demo = C4View(
    topicSi: 'මගේ ප්‍රියතම සත්වයා',
    topicEn: 'My Favourite Animal',
    categorySi: 'සතුන්',
    categoryEn: 'Animals',
    ageBand: '7–12',
    level: 'පහසු',
    categoryRank: 1,
    questionSi: 'ඔයාගේ ප්‍රියතම බල්ලා එක්ක දවසක්ම ගත කරන්න පුළුවන් නම්, ඔයා දෙන්නා මොනවා කරයිද?',
    transcript:
        'මම පාසල් යන්න ගොඩක් ආසයි. එහේ ගොඩක් යාළුවෝ ඉන්නවා. අපි එකට සෙල්ලම් කරනවා. මගේ ප්‍රියතම විෂය තමයි චිත්‍ර. අද අපි මලක් ඇන්දා. ටීචර් කිව්වා මම ලස්සනට පාට කළා කියලා. හෙටත් මම ලස්සන චිත්‍රයක් අඳින්න ඕනේ.',
    durationSec: 84,
    utterances: 12,
    totalWords: 62,
    ndw: 37,
    mlu: 5.2,
    percentSS: 4.8,
  );
}

/// The previous and the current session for the comparison screen.
class C4Comparison {
  final double? mluBefore, mluNow;
  final int? ndwBefore, ndwNow;
  final double? durationBefore, durationNow;
  final double? percentSSBefore, percentSSNow;
  const C4Comparison({
    this.mluBefore, this.mluNow, this.ndwBefore, this.ndwNow, this.durationBefore, this.durationNow,
    this.percentSSBefore, this.percentSSNow,
  });

  bool get hasPrevious => mluBefore != null || ndwBefore != null;

  static const demo = C4Comparison(
      mluBefore: 4.1, mluNow: 5.2, ndwBefore: 28, ndwNow: 37, durationBefore: 65, durationNow: 84, percentSSBefore: 6.2, percentSSNow: 4.8);
}

/// State of the C4 flow across its screens (onboarding → session → recording → sample).
class C4Flow {
  static ChildRef? child;
  static List<C4Category> categories = const [];
  static List<C4Category> ranked = const [];
  static Map<String, dynamic>? session;

  /// The profile's ranked category ids, favourite first.
  static List<String> rankedIds = const [];
  static String? sampleId;
  static Map<String, dynamic>? sample;
  /// The answer, kept on the device for "Listen to Recording".
  static RecordedAudio? recording;

  static bool get isLive => !StorageService.isDemoMode();

  static ChildRef _child() {
    final c = child;
    if (c == null) throw const ApiException('no_child', 'Choose a child on the therapist home first.');
    return c;
  }

  static Future<List<C4Category>> loadCategories() async {
    final res = await C4Service.categories(_child().age);
    categories = [for (final c in (res['categories'] as List? ?? const [])) C4Category.fromJson(Map<String, dynamic>.from(c as Map))];
    return categories;
  }

  /// Whether the parent has answered the checklist for the child's current age band.
  static bool checklistDone = false;

  static Future<bool> hasProfile() async {
    final profile = await C4Service.profile(_child().childId);
    if (profile == null) return false;
    rankedIds = [for (final id in (profile['rankedCategories'] as List? ?? const [])) id.toString()];
    checklistDone = profile['checklist']?['startingLevel'] != null;
    return rankedIds.length == 5;
  }

  /// Saves the parent's corrected transcript; the sample comes back re-measured.
  static Future<void> correctTranscript(String text) async {
    sample = await C4Service.editTranscript(sampleId!, text);
  }

  /// Saves the child's 5 favourite interests in the child's own order, 1st (most favourite) to 5th.
  static Future<void> saveProfile() async {
    rankedIds = [for (final x in ranked) x.id];
    final c = _child();
    await C4Service.saveProfile(c.childId, c.age, rankedIds);
  }

  /// Every session is personalised: one topic from the child's ranked interests (the server also weighs C3's
  /// progress, C4's band and the stuttering rate, and doesn't repeat a topic until all 25 were used).
  static Future<void> startSession() async {
    final c = _child();
    session = await C4Service.startSession(c.childId);
    sampleId = null;
    sample = null;
    recording = null;
  }

  static Future<void> anotherTopic() async {
    session = await C4Service.anotherTopic(session!['id'] as String);
  }

  /// The child didn't understand the question: logs the skip and shows the next follow-up.
  static Future<bool> skipFollowUp() async {
    session = await C4Service.skipFollowUp(session!['id'] as String);
    return session!['prompts']?['current'] != null;
  }

  /// Shows the next follow-up question; returns false when none are left.
  static Future<bool> nextPrompt() async {
    session = await C4Service.nextPrompt(session!['id'] as String);
    return session!['prompts']?['current'] != null;
  }

  static Future<void> upload(RecordedAudio audio) async {
    recording = audio;
    sampleId = await C4Service.uploadRecording(session!['id'] as String, audio);
  }

  /// Polls the sample until its analysis is completed (or throws when it failed).
  static Future<Map<String, dynamic>> waitForSample() async {
    final deadline = DateTime.now().add(const Duration(minutes: 15));
    while (DateTime.now().isBefore(deadline)) {
      final s = await C4Service.sample(sampleId!);
      if (s['status'] == 'completed') return sample = s;
      if (s['status'] == 'failed') {
        throw ApiException(s['error']?['code'] ?? 'analysis_failed', s['error']?['message'] ?? 'The analysis failed.');
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    throw const ApiException('timeout', 'The analysis is taking too long. Try again later.');
  }

  static String _categoryTitle(String? id) =>
      categories.where((c) => c.id == id).map((c) => c.en).firstOrNull ??
      (id ?? '').split('-').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  static String _categoryTitleSi(String? id) =>
      categories.where((c) => c.id == id).map((c) => c.si).firstOrNull ?? 'කැමති මාතෘකාව';

  static const _levels = {'emerging': 'පහසු', 'developing': 'මධ්‍යම', 'established': 'විවෘත ප්‍රශ්න'};

  /// The current session (and sample, once analysed) in the shape the screens show.
  static C4View get view {
    final s = session;
    if (!isLive || s == null) return C4View.demo;
    final topic = Map<String, dynamic>.from(s['topic'] as Map? ?? const {});
    final chosen = s['selection']?['chosen'];
    final categoryId = topic['categoryId'] as String?;
    final rank = rankedIds.indexOf(categoryId ?? '') + 1;
    final current = s['prompts']?['current']?['text'] ?? topic['mainPrompt'];
    final smp = sample;
    final measures = smp?['analysis']?['measures'] as Map? ?? const {};
    final versions = smp?['transcripts'] as List? ?? const [];
    final currentVersion = (smp?['currentVersion'] as num?)?.toInt() ?? versions.length;
    final transcript = versions.isEmpty
        ? (smp?['asr']?['text'] ?? '')
        : (versions[(currentVersion - 1).clamp(0, versions.length - 1)]['text'] ?? '');
    return C4View(
      topicSi: topic['title']?['si'] ?? '',
      topicEn: topic['title']?['en'] ?? '',
      categorySi: _categoryTitleSi(categoryId),
      categoryEn: _categoryTitle(categoryId),
      ageBand: (s['ageBand'] as String? ?? '').replaceAll('-', '–'),
      level: _levels[topic['level']] ?? (topic['level'] ?? '').toString(),
      categoryRank: rank > 0 ? rank : null,
      probability: (chosen?['probability'] as num?)?.toDouble(),
      questionSi: current?['si'] ?? '',
      transcript: transcript.toString(),
      transcriptKind: versions.isEmpty ? 'asr' : (versions.last['kind'] ?? 'asr').toString(),
      durationSec: (smp?['asr']?['audio']?['durationSec'] as num?)?.toDouble(),
      utterances: (measures['utteranceCount'] as num?)?.toInt() ?? 0,
      totalWords: (measures['totalWords'] as num?)?.toInt() ?? 0,
      ndw: (measures['ndwAll'] as num?)?.toInt() ?? 0,
      mlu: (measures['mluWords'] as num?)?.toDouble(),
      flags: [for (final f in (smp?['analysis']?['flags'] as List? ?? const [])) f.toString()],
      mode: s['mode'] as String? ?? 'personalised',
      percentSS: smp?['stuttering']?['status'] == 'assessed'
          ? ((smp?['stuttering']?['percentSSCurrent'] ?? smp?['stuttering']?['percentSS']) as num?)?.toDouble()
          : null,
    );
  }

  /// The last two analysed sessions from the progress series.
  static Future<C4Comparison> comparison() async {
    if (!isLive) return C4Comparison.demo;
    final p = await C4Service.progress(_child().childId);
    final series = [for (final x in (p['series'] as List? ?? const [])) Map<String, dynamic>.from(x as Map)];
    if (series.isEmpty) return const C4Comparison();
    final now = series.last;
    final before = series.length > 1 ? series[series.length - 2] : null;
    // The progress series has no duration, so read the previous sample itself.
    double? durationBefore;
    if (before != null) {
      try {
        final prev = await C4Service.sample(before['sampleId'] as String);
        durationBefore = (prev['asr']?['audio']?['durationSec'] as num?)?.toDouble();
      } catch (_) {}
    }
    return C4Comparison(
      mluBefore: (before?['mluWords'] as num?)?.toDouble(),
      mluNow: (now['mluWords'] as num?)?.toDouble(),
      ndwBefore: (before?['ndwAll'] as num?)?.toInt(),
      ndwNow: (now['ndwAll'] as num?)?.toInt(),
      durationBefore: durationBefore,
      durationNow: view.durationSec,
      percentSSBefore: (before?['spontaneousPercentSS'] as num?)?.toDouble(),
      percentSSNow: (now['spontaneousPercentSS'] as num?)?.toDouble() ?? view.percentSS,
    );
  }
}

String fmtClock(double? seconds) {
  if (seconds == null) return '—';
  final s = seconds.round();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
