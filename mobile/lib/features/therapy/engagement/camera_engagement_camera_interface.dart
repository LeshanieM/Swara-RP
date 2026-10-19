typedef CameraFaceSampleCallback = void Function({
  required bool faceDetected,
  double? headPitch,
  double? headYaw,
  double? leftEyeOpen,
  double? rightEyeOpen,
  double? smileProbability,
});

abstract interface class BrowserEngagementCamera {
  bool get isRunning;

  Future<void> start({
    required CameraFaceSampleCallback onSample,
    required void Function(Object error) onError,
  });

  Future<void> stop();
}
