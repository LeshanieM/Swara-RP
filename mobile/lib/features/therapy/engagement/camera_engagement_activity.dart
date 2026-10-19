import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'camera_engagement_metrics.dart';
import 'camera_engagement_camera_interface.dart';
import 'camera_engagement_camera_stub.dart'
    if (dart.library.js_interop) 'camera_engagement_camera_web.dart'
    as browser_camera;

class CameraEngagementActivityTracker extends ChangeNotifier {
  CameraEngagementActivityTracker();

  final BrowserEngagementCamera _browserCamera =
      browser_camera.BrowserEngagementCameraImpl();
  FaceDetector? _faceDetector;
  CameraController? _cameraController;
  DateTime? _lastFrameProcessedAt;
  bool _isProcessingFrame = false;
  bool _isStarting = false;
  bool _isDisposed = false;
  bool _cameraWasEnabled = false;
  String? _error;
  int _processedFrames = 0;
  int _faceFrames = 0;
  int _lookingAtScreenFrames = 0;
  int _gazeSamples = 0;
  int _openEyeCount = 0;
  int _eyeSamples = 0;
  double _smileTotal = 0;
  int _smileSamples = 0;

  bool get cameraEnabled => kIsWeb
      ? _browserCamera.isRunning
      : _cameraController?.value.isStreamingImages ?? false;
  bool get isStarting => _isStarting;
  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  bool get isBrowser => kIsWeb;
  String? get error => _error;

  double get faceVisibility =>
      _processedFrames == 0 ? 0 : _faceFrames / _processedFrames;

  Future<void> start() async {
    if (_isStarting || cameraEnabled || _isDisposed) return;
    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        await _browserCamera.start(
          onSample: _recordFaceSample,
          onError: _recordBrowserError,
        );
        _cameraWasEnabled = true;
        return;
      }
      if (!isSupported) {
        throw StateError(
            'Live camera measurement is available in Chrome, Android, and iOS.');
      }

      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final frontCamera = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final camera = frontCamera.isNotEmpty ? frontCamera.first : cameras.first;
      final controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      _cameraController = controller;
      await controller.initialize();
      if (_isDisposed) {
        await _disposeCamera();
        return;
      }
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.startImageStream(_processCameraImage);
      if (_isDisposed) {
        await _disposeCamera();
        return;
      }
      _cameraWasEnabled = true;
    } on CameraException catch (error, stackTrace) {
      debugPrint('Activity camera initialization failed: $error\n$stackTrace');
      _error = error.code.toLowerCase().contains('permission')
          ? 'Camera permission was not granted. The activity can continue without camera measurement.'
          : 'The camera could not start: ${error.description ?? error.code}';
      await _releaseCamera();
    } catch (error, stackTrace) {
      debugPrint('Activity camera initialization failed: $error\n$stackTrace');
      _error = error.toString();
      await _releaseCamera();
    } finally {
      _isStarting = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> stop() async {
    await _releaseCamera();
    if (!_isDisposed) notifyListeners();
  }

  Future<CameraEngagementSnapshot?> completeActivity({
    required int durationSeconds,
    required int responseCount,
    required int targetCount,
    required double completionFraction,
    int parentHelpLevel = 0,
  }) async {
    if (!_cameraWasEnabled) return null;
    await stop();

    final lookingAtScreen =
        _gazeSamples == 0 ? null : _lookingAtScreenFrames / _gazeSamples;
    final eyesOpen = _eyeSamples == 0 ? null : _openEyeCount / _eyeSamples;
    final smileProbability =
        _smileSamples == 0 ? null : _smileTotal / _smileSamples;
    final responseRate = targetCount == 0 ? null : responseCount / targetCount;
    final snapshot = CameraEngagementSnapshot(
      recordedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      cameraEnabled: true,
      engagementScore: CameraEngagementSnapshot.estimateEngagement(
        detectedFaceFrames: _faceFrames,
        lookingAtScreen: lookingAtScreen,
        eyesOpen: eyesOpen,
        smileProbability: smileProbability,
        responseRate: responseRate,
        responseSpeed: null,
        completionFraction: completionFraction,
      ),
      faceVisibility: faceVisibility,
      lookingAtScreen: lookingAtScreen,
      eyesOpen: eyesOpen,
      smileProbability: smileProbability,
      processedFrames: _processedFrames,
      responseCount: responseCount,
      targetCount: targetCount,
      averageResponseSeconds: null,
      completionFraction: completionFraction.clamp(0.0, 1.0).toDouble(),
      endedEarly: completionFraction < 1,
      parentHelpLevel: parentHelpLevel,
    );

    try {
      await CameraEngagementSnapshot.saveLatest(snapshot);
    } catch (error, stackTrace) {
      debugPrint(
          'Could not save activity engagement summary: $error\n$stackTrace');
      _error =
          'The activity is complete, but its engagement summary could not be saved.';
      if (!_isDisposed) notifyListeners();
    }
    return snapshot;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || !cameraEnabled || _isDisposed) return;
    final now = DateTime.now();
    if (_lastFrameProcessedAt != null &&
        now.difference(_lastFrameProcessedAt!).inMilliseconds < 900) {
      return;
    }
    _isProcessingFrame = true;
    _lastFrameProcessedAt = now;
    try {
      final controller = _cameraController;
      if (controller == null || image.planes.isEmpty) return;
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      final rotation = InputImageRotationValue.fromRawValue(
        controller.description.sensorOrientation,
      );
      if (format == null || rotation == null) {
        throw StateError(
            'The camera image format or orientation is unsupported by ML Kit.');
      }

      final plane = image.planes.first;
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
      final detector = _faceDetector;
      if (detector == null) {
        throw StateError(
            'Face detection was not initialized for this activity.');
      }
      final faces = await detector.processImage(inputImage);
      final face = faces.isEmpty ? null : faces.first;
      _recordFaceSample(
        faceDetected: face != null,
        headPitch: face?.headEulerAngleX,
        headYaw: face?.headEulerAngleY,
        leftEyeOpen: face?.leftEyeOpenProbability,
        rightEyeOpen: face?.rightEyeOpenProbability,
        smileProbability: face?.smilingProbability,
      );
      if (!_isDisposed) notifyListeners();
    } catch (error, stackTrace) {
      debugPrint(
          'On-device activity face detection failed: $error\n$stackTrace');
      _error = 'Face detection stopped: $error';
      await _disposeCamera();
      if (!_isDisposed) notifyListeners();
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _recordFaceSample({
    required bool faceDetected,
    double? headPitch,
    double? headYaw,
    double? leftEyeOpen,
    double? rightEyeOpen,
    double? smileProbability,
  }) {
    if (_isDisposed) return;
    _processedFrames++;
    if (!faceDetected) {
      if (kIsWeb) notifyListeners();
      return;
    }
    _faceFrames++;

    if (headPitch != null && headYaw != null) {
      _gazeSamples++;
      if (headYaw.abs() <= 18 && headPitch.abs() <= 18) {
        _lookingAtScreenFrames++;
      }
    }
    for (final eye in [leftEyeOpen, rightEyeOpen]) {
      if (eye != null) {
        _eyeSamples++;
        if (eye >= 0.45) _openEyeCount++;
      }
    }
    if (smileProbability != null) {
      _smileTotal += smileProbability;
      _smileSamples++;
    }
    if (kIsWeb) notifyListeners();
  }

  void _recordBrowserError(Object error) {
    if (_isDisposed) return;
    _error = 'Browser face detection stopped: $error';
    notifyListeners();
  }

  Future<void> _releaseCamera() async {
    if (kIsWeb) {
      try {
        await _browserCamera.stop();
      } catch (error, stackTrace) {
        debugPrint('Could not stop browser camera: $error\n$stackTrace');
        _error = 'The browser camera could not be stopped cleanly.';
      }
      return;
    }
    await _disposeCamera();
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (error, stackTrace) {
      debugPrint('Could not stop activity camera stream: $error\n$stackTrace');
      _error = 'The camera stream could not be stopped cleanly.';
    } finally {
      try {
        await controller.dispose();
      } catch (error, stackTrace) {
        debugPrint('Could not dispose activity camera: $error\n$stackTrace');
        _error = 'The camera could not be released cleanly.';
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_releaseCamera());
    final detector = _faceDetector;
    if (detector != null) unawaited(detector.close());
    super.dispose();
  }
}

class CameraEngagementActivityPanel extends StatefulWidget {
  const CameraEngagementActivityPanel({
    required this.tracker,
    super.key,
  });

  final CameraEngagementActivityTracker tracker;

  @override
  State<CameraEngagementActivityPanel> createState() =>
      _CameraEngagementActivityPanelState();
}

class _CameraEngagementActivityPanelState
    extends State<CameraEngagementActivityPanel> {
  bool _consentConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tracker,
      builder: (context, _) {
        final tracker = widget.tracker;
        final isActive = tracker.cameraEnabled;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  isActive ? const Color(0xFF43A047) : const Color(0xFFB8D5ED),
            ),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive
                        ? Icons.videocam_rounded
                        : Icons.face_retouching_natural,
                    color: isActive
                        ? const Color(0xFF388E3C)
                        : const Color(0xFF0066CC),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isActive ? 'Camera check is on' : 'Optional camera check',
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF43A047),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isActive
                    ? 'Measuring during this activity · face visible ${(tracker.faceVisibility * 100).round()}%'
                    : 'With parent or guardian permission, measure engagement while the child does this activity.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                tracker.isBrowser
                    ? 'Video stays in this browser and is never saved or uploaded. Face detection runs on-device; its runtime is downloaded from jsDelivr. This optional research measure is not clinically validated.'
                    : 'Video stays on this device and is never saved or uploaded. This optional research measure is not clinically validated.',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _consentConfirmed,
                onChanged: isActive
                    ? null
                    : (confirmed) => setState(
                          () => _consentConfirmed = confirmed ?? false,
                        ),
                title: const Text(
                  'I confirm parent/guardian consent and required research approval are in place.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF263238)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: tracker.isStarting ||
                              (!isActive &&
                                  (!_consentConfirmed || !tracker.isSupported))
                          ? null
                          : () => isActive ? tracker.stop() : tracker.start(),
                  icon: Icon(
                    isActive
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    size: 18,
                  ),
                  label: Text(
                    tracker.isStarting
                        ? 'Starting camera...'
                        : isActive
                            ? 'Turn off'
                            : 'Turn on during activity',
                  ),
                ),
              ),
              if (!tracker.isSupported)
                const Text(
                  'Camera measurement is available in Chrome/Edge, Android, and iOS.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              if (tracker.error != null)
                Text(
                  tracker.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }
}
