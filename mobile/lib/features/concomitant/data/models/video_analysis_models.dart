/// Dart models for the Component 2 computer-vision video analysis.
///
/// They mirror the payloads produced by the FastAPI service and relayed by the
/// Node API (`/api/concomitant/video-analysis`). Parsing is deliberately
/// tolerant: every field may be missing or null, technologies may be
/// unavailable/failed, and a technology never has to report every behavior.
/// Nothing here invents values - absent data stays `null`.
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

/// Lower-cases and strips punctuation so `3DDFA-V2`, `3ddfa_v2` and `3DDFA V2`
/// all compare equal. Used to match the backend's display name
/// (`current_technology`) to a technology key.
String normalizeTechName(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Display names for technology keys the backend has not reported on yet
/// (e.g. while still waiting). Only used as a label - never for capabilities.
const Map<String, String> kTechnologyDisplayNames = {
  'mediapipe': 'MediaPipe',
  'openface': 'OpenFace',
  'openseeface': 'OpenSeeFace',
  '3ddfa_v2': '3DDFA-V2',
  'mmpose': 'MMPose',
};

/// Canonical behavior order (presentation order only; the backend decides what
/// each technology supports).
const List<String> kCanonicalBehaviors = [
  'eye_blink',
  'lip_movement',
  'jaw_movement',
  'facial_movement',
  'head_movement',
  'hand_movement',
  'arm_movement',
];

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Per-technology state, as shown on the processing and results screens.
enum TechStatus { waiting, processing, completed, unavailable, failed, unknown }

TechStatus techStatusFromString(String? s) {
  switch (s) {
    case 'completed':
      return TechStatus.completed;
    case 'unavailable':
      return TechStatus.unavailable;
    case 'error':
    case 'failed':
      return TechStatus.failed;
    case 'processing':
      return TechStatus.processing;
    case 'queued':
    case 'waiting':
    case null:
      return TechStatus.waiting;
    default:
      return TechStatus.unknown;
  }
}

/// Whether a technology can produce a signal for one behavior.
/// `unsupported` (technology cannot) is never conflated with `unavailable`
/// (could, but cannot run right now) or `error` (ran and failed).
enum BehaviorSupport { supported, unsupported, unavailable, error, unknown }

BehaviorSupport behaviorSupportFromString(String? s) {
  switch (s) {
    case 'supported':
      return BehaviorSupport.supported;
    case 'unsupported':
      return BehaviorSupport.unsupported;
    case 'unavailable':
      return BehaviorSupport.unavailable;
    case 'error':
      return BehaviorSupport.error;
    default:
      return BehaviorSupport.unknown;
  }
}

// ---------------------------------------------------------------------------
// Events / behaviors
// ---------------------------------------------------------------------------

class BehaviorEvent {
  final double startTime;
  final double endTime;
  final double duration;
  final double? peakValue;

  const BehaviorEvent({
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.peakValue,
  });

  /// Returns null when the event has no usable start/end (it is then skipped
  /// rather than drawn at a made-up position).
  static BehaviorEvent? tryParse(dynamic json) {
    final m = _map(json);
    final start = _double(m['start_time']);
    final end = _double(m['end_time']);
    if (start == null || end == null) return null;
    return BehaviorEvent(
      startTime: start,
      endTime: end < start ? start : end,
      duration: _double(m['duration']) ?? (end - start),
      peakValue: _double(m['peak_value']),
    );
  }
}

class BehaviorResult {
  final String key;
  final BehaviorSupport support;
  final bool detected;
  final int frequency;
  final double totalDuration;
  final List<BehaviorEvent> events;
  final String? reason;
  final Map<String, dynamic> featureSummary;

  const BehaviorResult({
    required this.key,
    required this.support,
    this.detected = false,
    this.frequency = 0,
    this.totalDuration = 0,
    this.events = const [],
    this.reason,
    this.featureSummary = const {},
  });

  /// A behavior the technology did not report at all.
  const BehaviorResult.notReported(this.key)
      : support = BehaviorSupport.unsupported,
        detected = false,
        frequency = 0,
        totalDuration = 0,
        events = const [],
        reason = null,
        featureSummary = const {};

  bool get isSupported => support == BehaviorSupport.supported;

  /// Event count. Backend `frequency` is the number of events in the video.
  int get eventCount => frequency;

  factory BehaviorResult.fromJson(String key, dynamic json) {
    final m = _map(json);
    final events = _list(m['events'])
        .map(BehaviorEvent.tryParse)
        .whereType<BehaviorEvent>()
        .toList(growable: false);
    return BehaviorResult(
      key: key,
      support: behaviorSupportFromString(_string(m['status'])),
      detected: m['detected'] == true,
      frequency: _int(m['frequency']) ?? events.length,
      totalDuration: _double(m['total_duration']) ?? 0,
      events: events,
      reason: _string(m['reason']),
      featureSummary: _map(m['feature_summary']),
    );
  }
}

// ---------------------------------------------------------------------------
// Video / tracking
// ---------------------------------------------------------------------------

class VideoMeta {
  final double? duration;
  final double? fps;
  final int? width;
  final int? height;
  final int? totalFrames;

  const VideoMeta({this.duration, this.fps, this.width, this.height, this.totalFrames});

  factory VideoMeta.fromJson(dynamic json) {
    final m = _map(json);
    return VideoMeta(
      duration: _double(m['duration']),
      fps: _double(m['fps']),
      width: _int(m['width']),
      height: _int(m['height']),
      totalFrames: _int(m['total_frames']),
    );
  }

  bool get hasDuration => (duration ?? 0) > 0;
  String? get resolution => (width ?? 0) > 0 && (height ?? 0) > 0 ? '${width}x$height' : null;
}

class TrackingMetrics {
  final int? processedFrames;
  final int? missingFrames;
  final int? trackingFailures;
  final int? totalFramesRead;

  /// Only present if the technology reports a confidence value.
  final double? meanConfidence;
  final Map<String, dynamic> raw;

  const TrackingMetrics({
    this.processedFrames,
    this.missingFrames,
    this.trackingFailures,
    this.totalFramesRead,
    this.meanConfidence,
    this.raw = const {},
  });

  bool get isEmpty => raw.isEmpty;

  factory TrackingMetrics.fromJson(dynamic json) {
    final m = _map(json);
    return TrackingMetrics(
      processedFrames: _int(m['processed_frames']),
      missingFrames: _int(m['missing_frames']),
      trackingFailures: _int(m['tracking_failures']),
      totalFramesRead: _int(m['total_frames_read']),
      meanConfidence: _double(m['mean_confidence'] ?? m['average_confidence'] ?? m['confidence']),
      raw: m,
    );
  }
}

// ---------------------------------------------------------------------------
// Technology result
// ---------------------------------------------------------------------------

class TechnologyResult {
  final String key; // e.g. "mediapipe"
  final String name; // display name, e.g. "MediaPipe"
  final String? version;
  final TechStatus status;
  final String? rawStatus;
  final String? reason; // reason (unavailable) or error (failed)
  final double? processingTime;
  final VideoMeta video;
  final TrackingMetrics tracking;
  final Map<String, BehaviorResult> behaviors;
  final bool overlayAvailable;
  final Map<String, dynamic> thresholdsUsed;
  final List<String> preprocessingNotes;

  const TechnologyResult({
    required this.key,
    required this.name,
    required this.status,
    this.rawStatus,
    this.version,
    this.reason,
    this.processingTime,
    this.video = const VideoMeta(),
    this.tracking = const TrackingMetrics(),
    this.behaviors = const {},
    this.overlayAvailable = false,
    this.thresholdsUsed = const {},
    this.preprocessingNotes = const [],
  });

  bool get isCompleted => status == TechStatus.completed;

  /// Never null: a behavior the technology did not report is "unsupported".
  BehaviorResult behavior(String key) => behaviors[key] ?? BehaviorResult.notReported(key);

  BehaviorSupport supportFor(String behaviorKey) => behavior(behaviorKey).support;

  /// Total number of events over every supported behavior.
  int get totalEvents =>
      behaviors.values.where((b) => b.isSupported).fold<int>(0, (sum, b) => sum + b.eventCount);

  factory TechnologyResult.fromJson(dynamic json) {
    final m = _map(json);
    final name = _string(m['technology']) ?? _string(m['technology_key']) ?? 'Unknown technology';
    final key = _string(m['technology_key']) ?? normalizeTechName(name);
    final rawStatus = _string(m['status']);

    final behaviors = <String, BehaviorResult>{};
    _map(m['behaviors']).forEach((k, v) => behaviors[k] = BehaviorResult.fromJson(k, v));

    return TechnologyResult(
      key: key,
      name: name,
      version: _string(m['technology_version']),
      status: techStatusFromString(rawStatus),
      rawStatus: rawStatus,
      reason: _string(m['reason']) ?? _string(m['error']),
      processingTime: _double(m['processing_time']),
      video: VideoMeta.fromJson(m['video']),
      tracking: TrackingMetrics.fromJson(m['tracking']),
      behaviors: behaviors,
      overlayAvailable: m['overlay_available'] == true || _string(m['overlay_video_path']) != null,
      thresholdsUsed: _map(m['thresholds_used']),
      preprocessingNotes: _list(m['preprocessing_notes']).map((e) => e.toString()).toList(growable: false),
    );
  }
}

// ---------------------------------------------------------------------------
// Live status
// ---------------------------------------------------------------------------

class AnalysisStatus {
  final String analysisId;

  /// queued | processing | completed | failed
  final String status;
  final String? currentTechnology; // display name
  final int completed;
  final int total;
  final List<String> requested; // technology keys
  final Map<String, TechStatus> perTechnology; // key -> final status

  const AnalysisStatus({
    required this.analysisId,
    required this.status,
    this.currentTechnology,
    this.completed = 0,
    this.total = 0,
    this.requested = const [],
    this.perTechnology = const {},
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isTerminal => isCompleted || isFailed;

  /// Status of one requested technology, derived only from what the backend
  /// reported: a finished result, else "processing" if it is the current one,
  /// else "waiting".
  TechStatus statusOf(String techKey) {
    final done = perTechnology[techKey];
    if (done != null) return done;
    final current = currentTechnology;
    if (current != null && normalizeTechName(current) == normalizeTechName(techKey)) {
      return TechStatus.processing;
    }
    return TechStatus.waiting;
  }

  int countOf(TechStatus s) => requested.where((k) => statusOf(k) == s).length;

  factory AnalysisStatus.fromJson(dynamic json) {
    final m = _map(json);
    final per = <String, TechStatus>{};
    _map(m['per_technology_status']).forEach((k, v) => per[k] = techStatusFromString(_string(v)));
    final requested = _list(m['technologies_requested']).map((e) => e.toString()).toList(growable: false);
    return AnalysisStatus(
      analysisId: _string(m['analysis_id']) ?? '',
      status: _string(m['status']) ?? 'queued',
      currentTechnology: _string(m['current_technology']),
      completed: _int(m['completed']) ?? 0,
      total: _int(m['total']) ?? requested.length,
      requested: requested,
      perTechnology: per,
    );
  }
}

// ---------------------------------------------------------------------------
// Evaluation (ground truth)
// ---------------------------------------------------------------------------

class BehaviorEvaluation {
  final bool evaluated;
  final String? reason;
  final int? truePositives;
  final int? falsePositives;
  final int? falseNegatives;
  final double? precision;
  final double? recall;
  final double? f1;
  final int? frequencyError;
  final double? meanTimingError; // seconds, mean absolute
  final double? meanDurationError; // seconds, mean absolute
  final double? minIou;

  const BehaviorEvaluation({
    required this.evaluated,
    this.reason,
    this.truePositives,
    this.falsePositives,
    this.falseNegatives,
    this.precision,
    this.recall,
    this.f1,
    this.frequencyError,
    this.meanTimingError,
    this.meanDurationError,
    this.minIou,
  });

  factory BehaviorEvaluation.fromJson(dynamic json) {
    final m = _map(json);
    return BehaviorEvaluation(
      evaluated: m['evaluated'] == true,
      reason: _string(m['reason']),
      truePositives: _int(m['true_positives']),
      falsePositives: _int(m['false_positives']),
      falseNegatives: _int(m['false_negatives']),
      precision: _double(m['precision']),
      recall: _double(m['recall']),
      f1: _double(m['f1_score']),
      frequencyError: _int(m['frequency_error']),
      meanTimingError: _double(m['mean_event_timing_error_s']),
      meanDurationError: _double(m['mean_duration_error_s']),
      minIou: _double(m['min_iou_for_match']),
    );
  }
}

class EvaluationMetrics {
  final bool groundTruthProvided;

  /// technology display name -> behavior key -> evaluation
  final Map<String, Map<String, BehaviorEvaluation>> perTechnology;

  const EvaluationMetrics({this.groundTruthProvided = false, this.perTechnology = const {}});

  factory EvaluationMetrics.fromJson(dynamic json) {
    final m = _map(json);
    final out = <String, Map<String, BehaviorEvaluation>>{};
    _map(m['per_technology']).forEach((tech, behaviors) {
      final inner = <String, BehaviorEvaluation>{};
      _map(behaviors).forEach((b, e) => inner[b] = BehaviorEvaluation.fromJson(e));
      out[tech] = inner;
    });
    return EvaluationMetrics(groundTruthProvided: m['ground_truth_provided'] == true, perTechnology: out);
  }
}

// ---------------------------------------------------------------------------
// Full results
// ---------------------------------------------------------------------------

class VideoAnalysisResults {
  final String analysisId;
  final String status; // completed | failed | ...
  final String? videoFilename;
  final List<TechnologyResult> technologies;
  final double? timelineDuration;
  final EvaluationMetrics evaluation;
  final String? error;
  final String? comparisonNote;

  const VideoAnalysisResults({
    required this.analysisId,
    required this.status,
    this.videoFilename,
    this.technologies = const [],
    this.timelineDuration,
    this.evaluation = const EvaluationMetrics(),
    this.error,
    this.comparisonNote,
  });

  bool get isFailed => status == 'failed';
  bool get hasResults => technologies.isNotEmpty;

  int countWhere(TechStatus s) => technologies.where((t) => t.status == s).length;

  TechnologyResult? byKey(String key) {
    for (final t in technologies) {
      if (t.key == key) return t;
    }
    return null;
  }

  /// Video metadata as measured by the first technology that reported it.
  VideoMeta get videoMeta {
    for (final t in technologies) {
      if (t.video.hasDuration) return t.video;
    }
    return technologies.isEmpty ? const VideoMeta() : technologies.first.video;
  }

  /// Length of the time axis: backend timeline duration, else measured video
  /// duration, else the end of the last event. 0 when nothing is known.
  double get durationSeconds {
    final t = timelineDuration ?? 0;
    if (t > 0) return t;
    final v = videoMeta.duration ?? 0;
    if (v > 0) return v;
    var end = 0.0;
    for (final tech in technologies) {
      for (final b in tech.behaviors.values) {
        for (final e in b.events) {
          if (e.endTime > end) end = e.endTime;
        }
      }
    }
    return end;
  }

  /// Canonical behaviors first, then any extra behavior keys the backend sent.
  List<String> get behaviorKeys {
    final keys = <String>[...kCanonicalBehaviors];
    for (final t in technologies) {
      for (final k in t.behaviors.keys) {
        if (!keys.contains(k)) keys.add(k);
      }
    }
    return keys;
  }

  factory VideoAnalysisResults.fromJson(dynamic json) {
    final m = _map(json);
    return VideoAnalysisResults(
      analysisId: _string(m['analysis_id']) ?? '',
      status: _string(m['status']) ?? 'unknown',
      videoFilename: _string(m['video_filename']),
      technologies: _list(m['results']).map(TechnologyResult.fromJson).toList(growable: false),
      timelineDuration: _double(_map(m['timeline'])['video_duration']),
      evaluation: EvaluationMetrics.fromJson(m['evaluation']),
      error: _string(m['error']),
      comparisonNote: _string(_map(m['comparison'])['note']),
    );
  }
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

class VideoAnalysisSummary {
  final String analysisId;
  final String? filename;
  final int? sizeBytes;
  final String status; // queued | processing | completed | failed
  final DateTime? createdAt;
  final int completed;
  final int total;
  final bool groundTruthProvided;

  const VideoAnalysisSummary({
    required this.analysisId,
    required this.status,
    this.filename,
    this.sizeBytes,
    this.createdAt,
    this.completed = 0,
    this.total = 0,
    this.groundTruthProvided = false,
  });

  bool get isTerminal => status == 'completed' || status == 'failed';

  factory VideoAnalysisSummary.fromJson(dynamic json) {
    final m = _map(json);
    final video = _map(m['video']);
    final progress = _map(m['progress']);
    return VideoAnalysisSummary(
      analysisId: _string(m['analysisId']) ?? '',
      filename: _string(video['filename']),
      sizeBytes: _int(video['sizeBytes']),
      status: _string(m['status']) ?? 'queued',
      createdAt: DateTime.tryParse(_string(m['createdAt']) ?? '')?.toLocal(),
      completed: _int(progress['completed']) ?? 0,
      total: _int(progress['total']) ?? 0,
      groundTruthProvided: m['groundTruthProvided'] == true,
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
  final Duration? duration;

  const SelectedVideo({
    required this.name,
    required this.sizeBytes,
    this.path,
    this.bytes,
    this.duration,
  });

  SelectedVideo copyWith({Duration? duration}) => SelectedVideo(
        name: name,
        sizeBytes: sizeBytes,
        path: path,
        bytes: bytes,
        duration: duration ?? this.duration,
      );
}

/// Optional researcher-supplied ground-truth annotations (JSON file).
class GroundTruthAttachment {
  final String fileName;
  final String json; // raw JSON text, forwarded unchanged
  final int annotationCount;

  const GroundTruthAttachment({
    required this.fileName,
    required this.json,
    required this.annotationCount,
  });
}
