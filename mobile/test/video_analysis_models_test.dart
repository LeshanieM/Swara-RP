import 'package:flutter_test/flutter_test.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';

Map<String, dynamic> _results() => {
      'analysis_id': 'abc',
      'status': 'completed',
      'video_filename': 'clip.mp4',
      'results': [
        {
          'technology': 'MediaPipe',
          'technology_key': 'mediapipe',
          'status': 'completed',
          'processing_time': 12.45,
          'video': {'duration': 10.0, 'fps': 30.0, 'width': 640, 'height': 480},
          'tracking': {'processed_frames': 290, 'missing_frames': 10, 'tracking_failures': 10},
          'overlay_video_path': '/tmp/x_overlay.mp4',
          'behaviors': {
            'eye_blink': {
              'status': 'supported',
              'detected': true,
              'frequency': 2,
              'total_duration': 0.3,
              'events': [
                {'start_time': 1.0, 'end_time': 1.15, 'duration': 0.15, 'peak_value': 0.1},
                {'start_time': 4.0, 'end_time': 4.15, 'duration': 0.15},
                {'start_time': null, 'end_time': 5.0}, // unusable: skipped
              ],
            },
            'hand_movement': {'status': 'unsupported', 'reason': 'technology_does_not_provide_this_feature'},
          },
        },
        {
          'technology': '3DDFA-V2',
          'technology_key': '3ddfa_v2',
          'status': 'unavailable',
          'reason': 'model_unavailable: weights missing',
          'behaviors': {
            'lip_movement': {'status': 'unavailable', 'reason': 'model_unavailable'},
          },
        },
        {'technology': 'OpenFace', 'technology_key': 'openface', 'status': 'error', 'error': 'runtime_error: boom'},
      ],
      'timeline': {'video_duration': 10.0},
      'evaluation': {'ground_truth_provided': false, 'evaluation_metrics': 'Not available'},
    };

void main() {
  test('parses completed, unavailable and failed technologies', () {
    final r = VideoAnalysisResults.fromJson(_results());
    expect(r.technologies.length, 3);
    expect(r.countWhere(TechStatus.completed), 1);
    expect(r.countWhere(TechStatus.unavailable), 1);
    expect(r.countWhere(TechStatus.failed), 1);

    final mp = r.byKey('mediapipe')!;
    expect(mp.overlayAvailable, isTrue);
    expect(mp.behavior('eye_blink').events.length, 2); // event without start_time skipped
    expect(mp.behavior('eye_blink').eventCount, 2);
    expect(mp.tracking.missingFrames, 10);
    expect(r.durationSeconds, 10.0);
    expect(r.evaluation.groundTruthProvided, isFalse);
  });

  test('missing behaviors are unsupported, never zero-valued "supported"', () {
    final r = VideoAnalysisResults.fromJson(_results());
    final mp = r.byKey('mediapipe')!;
    expect(mp.behavior('hand_movement').support, BehaviorSupport.unsupported);
    expect(mp.behavior('arm_movement').support, BehaviorSupport.unsupported); // not reported at all
    expect(mp.behavior('arm_movement').isSupported, isFalse);
    expect(r.byKey('3ddfa_v2')!.behavior('lip_movement').support, BehaviorSupport.unavailable);
    expect(r.byKey('openface')!.reason, 'runtime_error: boom');
    expect(r.byKey('openface')!.overlayAvailable, isFalse);
  });

  test('empty / malformed payloads do not throw', () {
    final r = VideoAnalysisResults.fromJson(null);
    expect(r.hasResults, isFalse);
    expect(r.durationSeconds, 0);
    expect(AnalysisStatus.fromJson('garbage').status, 'queued');
  });

  test('status derives per-technology state only from backend data', () {
    final s = AnalysisStatus.fromJson({
      'analysis_id': 'abc',
      'status': 'processing',
      'current_technology': '3DDFA-V2',
      'completed': 2,
      'total': 5,
      'technologies_requested': ['mediapipe', 'openface', '3ddfa_v2', 'mmpose'],
      'per_technology_status': {'mediapipe': 'completed', 'openface': 'error'},
    });
    expect(s.statusOf('mediapipe'), TechStatus.completed);
    expect(s.statusOf('openface'), TechStatus.failed);
    expect(s.statusOf('3ddfa_v2'), TechStatus.processing); // matches "3DDFA-V2"
    expect(s.statusOf('mmpose'), TechStatus.waiting);
    expect(s.isTerminal, isFalse);
  });

  test('evaluation metrics parse with nullable values', () {
    final e = EvaluationMetrics.fromJson({
      'ground_truth_provided': true,
      'per_technology': {
        'MediaPipe': {
          'eye_blink': {'evaluated': true, 'precision': 0.5, 'recall': 1.0, 'f1_score': 0.6667, 'frequency_error': -1},
          'lip_movement': {'evaluated': false, 'reason': 'no ground-truth annotations for this behavior'},
        },
      },
    });
    expect(e.groundTruthProvided, isTrue);
    final b = e.perTechnology['MediaPipe']!['eye_blink']!;
    expect(b.f1, closeTo(0.6667, 1e-9));
    expect(b.meanTimingError, isNull);
    expect(e.perTechnology['MediaPipe']!['lip_movement']!.evaluated, isFalse);
  });
}
