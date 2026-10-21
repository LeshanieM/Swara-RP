import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_features.dart';

/// The front camera during a C3 activity, read by ML Kit face detection on the phone.
/// It is opened at activity start and closed at activity end.
///
/// Only per-frame numbers are kept (face visible, head yaw and pitch, eye-open and smile
/// probabilities); frames are never stored or sent. [stop] returns the activity's
/// 10-second window features for the server's engagement model.
class EngagementCamera {
  EngagementCamera._();
  static final instance = EngagementCamera._();

  /// Android and iOS support on-device features; web supports preview only.
  /// Other platforms keep using the activity-log engagement signals.
  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// True while the camera is reading frames, for the preview and camera-on badge.
  final ValueNotifier<bool> running = ValueNotifier(false);

  /// Latest local face-presence result. This identifies a visible face, not a person.
  final ValueNotifier<bool?> facePresent = ValueNotifier(null);

  /// Live controller for the in-activity preview. It is null when the camera is off.
  CameraController? get previewController => running.value ? _controller : null;

  static const _frameInterval =
      Duration(milliseconds: 200); // about 5 frames a second, as in training
  static const _maxRun = Duration(minutes: 10);
  CameraController? _controller;
  CameraDescription? _camera;
  FaceDetector? _detector;
  final List<FaceSample> _samples = [];
  DateTime? _startedAt;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;
  Timer? _limit;
  Future<void>? _starting;

  /// Starts reading frames. Returns false if the camera can't be used (unsupported, no permission, no front camera).
  Future<bool> start() async {
    if (!isSupported) return false;
    if (_controller != null) return true;
    final starting = _starting ??= _open();
    try {
      await starting;
    } finally {
      _starting = null;
    }
    return _controller != null;
  }

  Future<void> _open() async {
    try {
      final cameras = await availableCameras();
      final front = cameras
              .where((c) => c.lensDirection == CameraLensDirection.front)
              .firstOrNull ??
          // Some browsers report webcams as external when facingMode is unavailable.
          (kIsWeb ? cameras.firstOrNull : null);
      if (front == null) return;
      final controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      // The web camera plugin provides a browser preview, but ML Kit face detection
      // is native-only. On web, keep the preview live and use log-based scoring.
      if (!kIsWeb) {
        _detector = FaceDetector(
          options: FaceDetectorOptions(
              enableClassification: true,
              performanceMode: FaceDetectorMode.fast,
              minFaceSize: 0.15),
        );
      }
      _camera = front;
      _controller = controller;
      _samples.clear();
      _startedAt = null; // activity window starts immediately after camera open
      facePresent.value = null;
      if (!kIsWeb) await controller.startImageStream(_onFrame);
      _limit = Timer(_maxRun, () => stop());
      running.value = true;
    } catch (error) {
      // Permission refused or camera busy: the activity goes on, scored from its logs.
      debugPrint('Engagement camera unavailable: $error');
      await _close();
    }
  }

  /// Begin a per-activity feature window without reopening the session camera.
  Future<void> beginActivityWindow() async {
    if (_controller == null) await start();
    _samples.clear();
    _startedAt = _controller == null ? null : DateTime.now();
  }

  /// End the current activity's feature window while keeping live preview and face checks running.
  Map<String, Object?>? endActivityWindow() {
    if (_startedAt == null) return null;
    final samples = List<FaceSample>.of(_samples);
    _samples.clear();
    _startedAt = null;
    return CameraFeatures.payload(samples);
  }

  Future<void> _onFrame(CameraImage image) async {
    final now = DateTime.now();
    if (_busy || now.difference(_lastFrame) < _frameInterval) return;
    _busy = true;
    _lastFrame = now;
    try {
      final input = _inputImage(image);
      final detector = _detector;
      if (input == null || detector == null) return;
      final faces = await detector.processImage(input);
      facePresent.value = faces.isNotEmpty;
      final activityStartedAt = _startedAt;
      if (activityStartedAt == null) return;
      final t = now.difference(activityStartedAt);
      if (faces.isEmpty) {
        _samples.add(FaceSample.noFace(t));
        return;
      }
      // The largest face is the child in front of the phone.
      final face = faces
          .reduce((a, b) => a.boundingBox.width >= b.boundingBox.width ? a : b);
      final eyes = [face.leftEyeOpenProbability, face.rightEyeOpenProbability]
          .whereType<double>()
          .toList();
      _samples.add(FaceSample(
        t: t,
        face: true,
        yaw: face.headEulerAngleY ?? 0,
        pitch: face.headEulerAngleX ?? 0,
        eyeOpen:
            eyes.isEmpty ? null : eyes.reduce((a, b) => a + b) / eyes.length,
        smile: face.smilingProbability,
      ));
    } catch (error) {
      debugPrint('Engagement camera frame skipped: $error');
    } finally {
      _busy = false;
    }
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Camera frame → ML Kit input (the conversion in the google_mlkit_commons example).
  InputImage? _inputImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      final device = _orientations[controller.value.deviceOrientation];
      if (device == null) return null;
      rotation = InputImageRotationValue.fromRawValue(
          (camera.sensorOrientation + device) % 360); // front camera
    }
    if (rotation == null) return null;
    // CameraX streams NV21 data under the YUV_420 label when asked for nv21.
    final format = defaultTargetPlatform == TargetPlatform.android
        ? InputImageFormat.nv21
        : InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null || image.planes.isEmpty) return null;
    final bytes = image.planes.length == 1
        ? image.planes.first.bytes
        : Uint8List.fromList([for (final p in image.planes) ...p.bytes]);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Stops the camera and returns the activity's `camera` block, or null if no frame was read.
  Future<Map<String, Object?>?> stop() async {
    await _starting;
    final payload = endActivityWindow();
    await _close();
    return payload;
  }

  Future<void> _close() async {
    _limit?.cancel();
    _limit = null;
    final controller = _controller;
    _controller = null;
    _camera = null;
    _startedAt = null;
    running.value = false;
    facePresent.value = null;
    try {
      if (controller != null && controller.value.isStreamingImages)
        await controller.stopImageStream();
      await controller?.dispose();
    } catch (error) {
      debugPrint('Engagement camera close: $error');
    }
    await _detector?.close();
    _detector = null;
    _samples.clear();
  }
}
