import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Films the child's face while they do the C1 speech task (C2 input path A, `in_task_camera`).
/// The video has no sound: the WAV recording is C1's audio, and C2 reuses that assessment's stutter moments.
class TaskCamera {
  CameraController? _controller;
  DateTime? _startedAt;

  CameraController? get controller => _controller;

  /// Video recording during the task needs a phone camera (Android or iOS).
  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Opens the front camera and starts recording. False if the camera can't be used (no permission, no front camera).
  Future<bool> start() async {
    if (!isSupported) return false;
    try {
      final cameras = await availableCameras();
      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull;
      if (front == null) return false;
      final controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      await controller.startVideoRecording();
      _controller = controller;
      _startedAt = DateTime.now();
      return true;
    } catch (error) {
      debugPrint('Task camera unavailable: $error');
      await _close();
      return false;
    }
  }

  /// Stops recording and returns the video file path, or null if nothing usable was recorded
  /// (C2 needs at least 2 seconds).
  Future<String?> stop() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRecordingVideo) {
      await _close();
      return null;
    }
    try {
      final file = await controller.stopVideoRecording();
      final long = _startedAt != null && DateTime.now().difference(_startedAt!) >= const Duration(seconds: 2);
      return long ? file.path : null;
    } catch (error) {
      debugPrint('Task camera stop failed: $error');
      return null;
    } finally {
      await _close();
    }
  }

  Future<void> _close() async {
    final controller = _controller;
    _controller = null;
    _startedAt = null;
    await controller?.dispose();
  }
}
