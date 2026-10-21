import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swara/core/engagement/camera_features.dart';

/// The shared check in server/contracts: the phone's features must equal the ones the model was trained on.
void main() {
  final fixture = jsonDecode(File('../server/contracts/c3/engagement-camera-features.example.json').readAsStringSync())
      as Map<String, dynamic>;

  test('C3 camera features: the window features follow the Python definition', () {
    for (final c in fixture['cases'] as List) {
      final samples = [
        for (final s in c['samples'] as List)
          s['face'] == true
              ? FaceSample(
                  t: Duration.zero,
                  face: true,
                  yaw: (s['yaw'] as num).toDouble(),
                  pitch: (s['pitch'] as num).toDouble(),
                  eyeOpen: (s['eyeOpen'] as num?)?.toDouble(),
                  smile: (s['smile'] as num?)?.toDouble())
              : const FaceSample.noFace(Duration.zero),
      ];
      final got = CameraFeatures.window(samples);
      expect(got.keys.toList(), fixture['features'], reason: c['name']);
      (c['expected'] as Map).forEach((k, v) {
        if (v == null) {
          expect(got[k], isNull, reason: '${c['name']}: $k');
        } else {
          expect(got[k], closeTo((v as num).toDouble(), 1e-6), reason: '${c['name']}: $k');
        }
      });
    }
  });

  test('C3 camera features: 10-second windows, a short tail joins the last window', () {
    // 23.6 s at 5 frames a second: windows 0–10, 10–20 and a 3.6 s tail, kept because it is over 3 s.
    final samples = [
      for (var i = 0; i < 118; i++)
        FaceSample(t: Duration(milliseconds: i * 200), face: i % 10 != 0, yaw: i < 50 ? 2 : 30, pitch: 1, eyeOpen: 0.9, smile: 0.1),
    ];
    final w = CameraFeatures.windows(samples);
    expect(w, hasLength(3));
    expect(w[0]['facePresentRatio'], 0.9);
    expect(w[0]['lookAwayRatio'], 0.0);
    expect(w[1]['lookAwayRatio'], 1.0);
    expect([for (final x in w) x['durationSec']], [10.0, 10.0, 3.6]);

    final short = CameraFeatures.windows(samples.sublist(0, 55)); // 0–10.8 s: the 0.8 s tail joins window 0
    expect(short, hasLength(1));
    expect(short[0]['durationSec'], closeTo(11.0, 1e-9));

    expect(CameraFeatures.payload(const []), isNull);
    final p = CameraFeatures.payload(samples)!;
    expect(p['windows'], hasLength(3));
    expect(p['facePresentRatio'], closeTo(0.8983, 1e-9));
  });
}
