/// Dart models for Component 2 (video-based secondary behaviours) on the Swara API
/// (`/api/c2/analyses`). For every stutter moment C1 found, the API reports whether the
/// face (FG: eye, lip, jaw, cheek) or the head (HM) moved unusually *for this child*.
///
/// Parsing is tolerant: any field may be missing or null, and absent data stays `null`.
library;

// ---------------------------------------------------------------------------
// Safe JSON helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> _list(dynamic v) => v is List ? v : const <dynamic>[];

double? _double(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _int(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _string(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

DateTime? _date(dynamic v) => DateTime.tryParse(_string(v) ?? '')?.toLocal();

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

/// State of one processing stage, as shown on the processing screen.
enum TechStatus { waiting, processing, completed, unavailable, failed, unknown }

/// The job's stages in order. `awaiting_stutter_events` waits for the linked C1
/// assessment (the video's own audio track) to find the stutter moments.
const List<(String, String)> kAnalysisStages = [
  ('queued', 'Video received'),
  ('awaiting_stutter_events', 'Finding stutter moments in the audio'),
  ('processing', 'Face and head movement at each stutter moment'),
];

const Set<String> kTerminalStatuses = {'completed', 'failed', 'not_assessed'};

/// The signals C2 measures; FG covers the face ones, HM the head.
const List<String> kSignals = ['eye', 'lip', 'jaw', 'cheek', 'head'];

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

class VideoMeta {
  final double? duration;
  final double? fps;
  final double? analysedFps;
  final int? width;
  final int? height;
  final int? framesAnalysed;
  final double? faceDetectedRatio;

  const VideoMeta({this.duration, this.fps, this.analysedFps, this.width, this.height, this.framesAnalysed, this.faceDetectedRatio});

  String? get resolution => (width != null && height != null) ? '${width}x$height' : null;

  /// Frames where no face was found, from the face-detected share.
  int? get missingFrames => (framesAnalysed != null && faceDetectedRatio != null)
      ? (framesAnalysed! * (1 - faceDetectedRatio!)).round()
      : null;

  factory VideoMeta.fromJson(dynamic json) {
    final m = _map(json);
    return VideoMeta(
      duration: _double(m['durationSec']),
      fps: _double(m['fps']),
      analysedFps: _double(m['analysedFps']),
      width: _int(m['width']),
      height: _int(m['height']),
      framesAnalysed: _int(m['framesAnalysed']),
      faceDetectedRatio: _double(m['faceDetectedRatio']),
    );
  }
}

/// How far one signal moved from the child's fluent baseline during a moment (in SD).
class SignalDeviation {
  final double? deviation;
  final String? direction;
  final String? topFeature;
  final bool exceeds;

  const SignalDeviation({this.deviation, this.direction, this.topFeature, this.exceeds = false});

  factory SignalDeviation.fromJson(dynamic json) {
    final m = _map(json);
    return SignalDeviation(
      deviation: _double(m['deviation']),
      direction: _string(m['direction']),
      topFeature: _string(m['topFeature']),
      exceeds: m['exceeds'] == true,
    );
  }
}

class CategoryCall {
  final bool present;
  final double? score;
  const CategoryCall({this.present = false, this.score});

  factory CategoryCall.fromJson(dynamic json) {
    final m = _map(json);
    return CategoryCall(present: m['present'] == true, score: _double(m['score']));
  }
}

class StutterMoment {
  final int index;
  final double start;
  final double end;
  final List<String> types;
  final bool assessed;
  final CategoryCall fg;
  final CategoryCall hm;
  final Map<String, SignalDeviation> signals;
  final List<String> explanation;

  const StutterMoment({
    required this.index,
    required this.start,
    required this.end,
    this.types = const [],
    this.assessed = true,
    this.fg = const CategoryCall(),
    this.hm = const CategoryCall(),
    this.signals = const {},
    this.explanation = const [],
  });

  factory StutterMoment.fromJson(dynamic json) {
    final m = _map(json);
    final categories = _map(m['categories']);
    final signals = _map(m['signals']);
    return StutterMoment(
      index: _int(m['index']) ?? 0,
      start: _double(m['start']) ?? 0,
      end: _double(m['end']) ?? 0,
      types: _list(m['types']).map((t) => t.toString()).toList(growable: false),
      assessed: m['assessed'] != false,
      fg: CategoryCall.fromJson(categories['FG']),
      hm: CategoryCall.fromJson(categories['HM']),
      signals: {for (final e in signals.entries) e.key: SignalDeviation.fromJson(e.value)},
      explanation: _list(m['explanation']).map((t) => t.toString()).toList(growable: false),
    );
  }
}

class BehaviourEvent {
  final String category; // FG | HM
  final String signal;
  final double start;
  final double end;
  final double? peakDeviation;

  const BehaviourEvent({required this.category, required this.signal, required this.start, required this.end, this.peakDeviation});

  factory BehaviourEvent.fromJson(dynamic json) {
    final m = _map(json);
    return BehaviourEvent(
      category: _string(m['category']) ?? '',
      signal: _string(m['signal']) ?? '',
      start: _double(m['start']) ?? 0,
      end: _double(m['end']) ?? 0,
      peakDeviation: _double(m['peakDeviation']),
    );
  }
}

class C2Result {
  final VideoMeta video;
  final String? detector;
  final bool detectorFallback;
  final String? baselineSource;
  final List<StutterMoment> moments;
  final List<BehaviourEvent> behaviourEvents;
  final int momentsTotal;
  final int momentsAssessed;
  final int momentsWithBehaviour;
  final int fgCount;
  final int hmCount;

  /// True / false, or null when no moment could be assessed (never "no behaviour").
  final bool? hasSecondaryBehaviors;
  final double? concomitantScore;
  final List<String> warnings;
  final double? processingSeconds;

  const C2Result({
    this.video = const VideoMeta(),
    this.detector,
    this.detectorFallback = false,
    this.baselineSource,
    this.moments = const [],
    this.behaviourEvents = const [],
    this.momentsTotal = 0,
    this.momentsAssessed = 0,
    this.momentsWithBehaviour = 0,
    this.fgCount = 0,
    this.hmCount = 0,
    this.hasSecondaryBehaviors,
    this.concomitantScore,
    this.warnings = const [],
    this.processingSeconds,
  });

  List<StutterMoment> get assessedMoments => moments.where((m) => m.assessed).toList(growable: false);

  /// Mean and peak deviation of one signal over the assessed stutter moments.
  (double?, double?) deviationOf(String signal) {
    final values = assessedMoments.map((m) => m.signals[signal]?.deviation).whereType<double>().toList();
    if (values.isEmpty) return (null, null);
    final mean = values.reduce((a, b) => a + b) / values.length;
    final peak = values.reduce((a, b) => a > b ? a : b);
    return (mean, peak);
  }

  /// Moments where this signal went past its threshold.
  int exceedCount(String signal) => assessedMoments.where((m) => m.signals[signal]?.exceeds == true).length;

  factory C2Result.fromJson(dynamic json) {
    final m = _map(json);
    final counts = _map(m['counts']);
    final detector = _map(m['detector']);
    final processingMs = _double(m['processingMs']);
    return C2Result(
      video: VideoMeta.fromJson(m['video']),
      detector: _string(detector['name']),
      detectorFallback: detector['fallback'] == true,
      baselineSource: _string(_map(m['baseline'])['source']),
      moments: _list(m['stutterMoments']).map(StutterMoment.fromJson).toList(growable: false),
      behaviourEvents: _list(m['behaviourEvents']).map(BehaviourEvent.fromJson).toList(growable: false),
      momentsTotal: _int(counts['momentsTotal']) ?? 0,
      momentsAssessed: _int(counts['momentsAssessed']) ?? 0,
      momentsWithBehaviour: _int(counts['momentsWithBehaviour']) ?? 0,
      fgCount: _int(counts['FG']) ?? 0,
      hmCount: _int(counts['HM']) ?? 0,
      hasSecondaryBehaviors: m['hasSecondaryBehaviors'] is bool ? m['hasSecondaryBehaviors'] as bool : null,
      concomitantScore: _double(m['concomitantScore']),
      warnings: _list(m['warnings'])
          .map((w) => _string(_map(w)['message']) ?? _string(_map(w)['code']) ?? '')
          .where((w) => w.isNotEmpty)
          .toList(growable: false),
      processingSeconds: processingMs == null ? null : processingMs / 1000,
    );
  }
}

// ---------------------------------------------------------------------------
// Analysis (GET /api/c2/analyses/:id) and history items
// ---------------------------------------------------------------------------

class VideoAnalysis {
  final String id;
  final String status; // queued | awaiting_stutter_events | processing | completed | failed | not_assessed
  final String? filename;
  final int? sizeBytes;
  final DateTime? createdAt;
  final String? errorCode;
  final String? errorMessage;
  final C2Result? result;

  const VideoAnalysis({
    required this.id,
    required this.status,
    this.filename,
    this.sizeBytes,
    this.createdAt,
    this.errorCode,
    this.errorMessage,
    this.result,
  });

  bool get isTerminal => kTerminalStatuses.contains(status);
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isNotAssessed => status == 'not_assessed';

  /// Where each stage stands for the processing screen.
  TechStatus stageStatus(String stage) {
    if (isCompleted) return TechStatus.completed;
    final order = kAnalysisStages.map((s) => s.$1).toList();
    final current = order.indexOf(status);
    final index = order.indexOf(stage);
    if (isFailed) return current == -1 || index >= current ? TechStatus.failed : TechStatus.completed;
    if (current == -1) return TechStatus.unknown;
    if (index < current) return TechStatus.completed;
    if (index == current) return stage == 'queued' ? TechStatus.waiting : TechStatus.processing;
    return TechStatus.waiting;
  }

  factory VideoAnalysis.fromJson(dynamic json) {
    final m = _map(json);
    final video = _map(m['video']);
    final error = _map(m['error']);
    return VideoAnalysis(
      id: _string(m['id']) ?? _string(m['analysisId']) ?? '',
      status: _string(m['status']) ?? 'queued',
      filename: _string(video['originalName']),
      sizeBytes: _int(video['sizeBytes']),
      createdAt: _date(m['createdAt']),
      errorCode: _string(error['code']),
      errorMessage: _string(error['message']),
      result: m['result'] is Map ? C2Result.fromJson(m['result']) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Local (device) selections
// ---------------------------------------------------------------------------

/// The one video chosen on the device. On web only [bytes] exist (no path).
class SelectedVideo {
  final String name;
  final int sizeBytes;
  final String? path;
  final List<int>? bytes;
  final Stream<List<int>>? readStream;
  final Duration? duration;

  const SelectedVideo({
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
    this.readStream,
    this.duration,
  });

  SelectedVideo copyWith({Duration? duration}) => SelectedVideo(
        name: name,
        sizeBytes: sizeBytes,
        path: path,
        bytes: bytes,
        readStream: readStream,
        duration: duration ?? this.duration,
      );
}
