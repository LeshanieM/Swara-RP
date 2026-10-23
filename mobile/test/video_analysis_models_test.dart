import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';

/// The vision service's real response, which the API stores as the analysis `result`.
Map<String, dynamic> _contract() => jsonDecode(
      File('../server/contracts/c2/analyze-video.response.example.json').readAsStringSync(),
    ) as Map<String, dynamic>;

Map<String, dynamic> _doc(String status, {Map<String, dynamic>? result, Map<String, dynamic>? error}) => {
      'id': '6650a0c2f1b2c3d4e5f60718',
      'childId': 'CH-001',
      'status': status,
      'createdAt': '2026-10-18T10:00:00.000Z',
      'video': {'originalName': 'clip.mp4', 'sizeBytes': 1048576, 'deleted': true},
      if (result != null) 'result': result,
      if (error != null) 'error': error,
    };

void main() {
  test('parses a completed analysis from the C2 contract', () {
    final a = VideoAnalysis.fromJson(_doc('completed', result: _contract()));
    expect(a.isCompleted, isTrue);
    expect(a.isTerminal, isTrue);
    expect(a.filename, 'clip.mp4');

    final r = a.result!;
    expect(r.momentsTotal, 7);
    expect(r.fgCount, 3);
    expect(r.hmCount, 2);
    expect(r.hasSecondaryBehaviors, isTrue);
    expect(r.concomitantScore, closeTo(0.571, 1e-9));
    expect(r.moments, hasLength(7));
    expect(r.moments.first.signals.keys, containsAll(kSignals));
    expect(r.video.resolution, '640x360');
    expect(r.video.missingFrames, 0);

    final (mean, peak) = r.deviationOf('jaw');
    expect(mean, isNotNull);
    expect(peak! >= mean!, isTrue);
    expect(r.moments.where((m) => m.explanation.isNotEmpty), isNotEmpty);
  });

  test('stages follow the job status', () {
    final waiting = VideoAnalysis.fromJson(_doc('awaiting_stutter_events'));
    expect(waiting.stageStatus('queued'), TechStatus.completed);
    expect(waiting.stageStatus('awaiting_stutter_events'), TechStatus.processing);
    expect(waiting.stageStatus('processing'), TechStatus.waiting);
    expect(waiting.isTerminal, isFalse);

    final failed = VideoAnalysis.fromJson(
      _doc('failed', error: {'code': 'vision_unavailable', 'message': 'The vision service is down.'}),
    );
    expect(failed.isTerminal, isTrue);
    expect(failed.errorMessage, 'The vision service is down.');
    expect(failed.stageStatus('processing'), TechStatus.failed);

    expect(VideoAnalysis.fromJson(_doc('not_assessed')).isTerminal, isTrue);
  });

  test('a moment without enough face is not assessed, and missing fields stay null', () {
    final r = C2Result.fromJson({
      'stutterMoments': [
        {'index': 0, 'start': 1, 'end': 2, 'assessed': false, 'signals': {}},
      ],
      'hasSecondaryBehaviors': null,
    });
    expect(r.assessedMoments, isEmpty);
    expect(r.hasSecondaryBehaviors, isNull);
    expect(r.deviationOf('eye'), (null, null));
    expect(r.concomitantScore, isNull);
  });
}
