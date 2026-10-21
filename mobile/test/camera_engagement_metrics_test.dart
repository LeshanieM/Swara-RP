import 'package:flutter_test/flutter_test.dart';
import 'package:swara/features/therapy/engagement/camera_engagement_metrics.dart';

void main() {
  group('CameraEngagementSnapshot.estimateEngagement', () {
    test('treats missing face data as unavailable', () {
      final score = CameraEngagementSnapshot.estimateEngagement(
        detectedFaceFrames: 0,
        lookingAtScreen: 1,
        eyesOpen: 1,
        smileProbability: 1,
        responseRate: 1,
        responseSpeed: 1,
        completionFraction: 1,
      );

      expect(score, isNull);
    });

    test('scores available camera and activity signals in range', () {
      final score = CameraEngagementSnapshot.estimateEngagement(
        detectedFaceFrames: 10,
        lookingAtScreen: 0.8,
        eyesOpen: 0.9,
        smileProbability: 0.6,
        responseRate: 0.5,
        responseSpeed: null,
        completionFraction: 0.75,
      );

      expect(score, closeTo(0.7205, 0.001));
      expect(score, inInclusiveRange(0, 1));
    });

    test('does not score when visual features are missing', () {
      final score = CameraEngagementSnapshot.estimateEngagement(
        detectedFaceFrames: 3,
        lookingAtScreen: null,
        eyesOpen: null,
        smileProbability: null,
        responseRate: 1,
        responseSpeed: 1,
        completionFraction: 1,
      );

      expect(score, isNull);
    });
  });
}
