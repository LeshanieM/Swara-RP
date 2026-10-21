import 'camera_engagement_camera_interface.dart';

class BrowserEngagementCameraImpl implements BrowserEngagementCamera {
  @override
  bool get isRunning => false;

  @override
  Future<void> start({
    required CameraFaceSampleCallback onSample,
    required void Function(Object error) onError,
  }) async {
    throw UnsupportedError('Browser camera measurement is only available on web.');
  }

  @override
  Future<void> stop() async {}
}
