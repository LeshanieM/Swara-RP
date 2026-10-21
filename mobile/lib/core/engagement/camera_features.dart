import 'dart:math' as math;

/// One analysed camera frame for C3 engagement: numbers from ML Kit, never the image.
class FaceSample {
  /// Time since the activity started.
  final Duration t;
  final bool face;
  final double yaw;
  final double pitch;
  final double? eyeOpen;
  final double? smile;

  const FaceSample({required this.t, required this.face, this.yaw = 0, this.pitch = 0, this.eyeOpen, this.smile});

  const FaceSample.noFace(this.t)
      : face = false,
        yaw = 0,
        pitch = 0,
        eyeOpen = null,
        smile = null;
}

/// The C3 engagement camera features, the same definition as
/// server/vision-service/app/engagement/features.py (the model is trained on those numbers from DAiSEE).
/// server/contracts/c3/engagement-camera-features.example.json checks that both sides agree.
class CameraFeatures {
  static const windowSec = 10.0; // DAiSEE clips are 10 s
  static const lookAwayYawDeg = 25.0;
  static const lookAwayPitchDeg = 20.0;
  static const eyesClosedBelow = 0.3;

  /// A shorter final window than this joins the one before it; it is too short to describe.
  static const minLastWindowSec = 3.0;

  /// Frames analysed per second on the phone, as in the DAiSEE extraction (build_engagement.py --target-fps).
  static const framesPerSec = 5.0;

  static double? _mean(List<double> xs) => xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

  // Population SD (ddof 0), as in the Python definition.
  static double? _std(List<double> xs) {
    final m = _mean(xs);
    if (m == null) return null;
    return math.sqrt(xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / xs.length);
  }

  static double? _share(List<bool> flags) => flags.isEmpty ? null : flags.where((f) => f).length / flags.length;

  /// One window's features. Everything but facePresentRatio is over the frames with a face only, and is null
  /// when there is none: the server treats that as missing data, not as a disengaged child.
  static Map<String, double?> window(List<FaceSample> samples) {
    final faces = samples.where((s) => s.face).toList();
    final yaw = [for (final s in faces) s.yaw];
    final pitch = [for (final s in faces) s.pitch];
    final eyes = [for (final s in faces) if (s.eyeOpen != null) s.eyeOpen!];
    final smiles = [for (final s in faces) if (s.smile != null) s.smile!];
    return {
      'facePresentRatio': samples.isEmpty ? 0.0 : faces.length / samples.length,
      'yawStdDeg': _std(yaw),
      'pitchStdDeg': _std(pitch),
      'yawAbsMeanDeg': _mean([for (final v in yaw) v.abs()]),
      'pitchAbsMeanDeg': _mean([for (final v in pitch) v.abs()]),
      'lookAwayRatio': _share([
        for (var i = 0; i < yaw.length; i++) yaw[i].abs() > lookAwayYawDeg || pitch[i].abs() > lookAwayPitchDeg
      ]),
      'eyeOpenMean': _mean(eyes),
      'eyesClosedRatio': _share([for (final e in eyes) e < eyesClosedBelow]),
      'smileMean': _mean(smiles),
    };
  }

  static double? _round(double? v) => v == null ? null : (v * 10000).roundToDouble() / 10000;

  /// Cuts an activity's samples into 10-second windows, each with its duration and features.
  static List<Map<String, Object?>> windows(List<FaceSample> samples) {
    if (samples.isEmpty) return const [];
    final groups = <int, List<FaceSample>>{};
    for (final s in samples) {
      groups.putIfAbsent((s.t.inMilliseconds / 1000 / windowSec).floor(), () => []).add(s);
    }
    final keys = groups.keys.toList()..sort();
    final lastSec = samples.last.t.inMilliseconds / 1000 - keys.last * windowSec;
    // A short tail joins the window before it, so no window is described from a second or two.
    if (keys.length > 1 && lastSec < minLastWindowSec) {
      groups[keys[keys.length - 2]]!.addAll(groups.remove(keys.last)!);
      keys.removeLast();
    }
    // Each window runs to the next one's start; the last to its final frame plus one frame interval.
    final endSec = samples.last.t.inMilliseconds / 1000 + 1 / framesPerSec;
    return [
      for (var i = 0; i < keys.length; i++)
        {
          'durationSec': _round((i + 1 < keys.length ? keys[i + 1] * windowSec : endSec) - keys[i] * windowSec),
          for (final e in window(groups[keys[i]]!).entries) e.key: _round(e.value),
        },
    ];
  }

  /// The `camera` block of a C3 activity result: the windows, plus the overall face ratio for older servers.
  static Map<String, Object?>? payload(List<FaceSample> samples) {
    if (samples.isEmpty) return null;
    return {
      'windows': windows(samples),
      'facePresentRatio': _round(samples.where((s) => s.face).length / samples.length),
    };
  }
}
