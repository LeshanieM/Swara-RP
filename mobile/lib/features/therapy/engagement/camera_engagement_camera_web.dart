import 'dart:async';
import 'dart:js_interop';

import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:web/web.dart' as web;

import 'camera_engagement_camera_interface.dart';

class BrowserEngagementCameraImpl implements BrowserEngagementCamera {
  web.MediaStream? _stream;
  web.HTMLVideoElement? _video;
  FaceDetector? _detector;
  Timer? _samplingTimer;
  CameraFaceSampleCallback? _onSample;
  void Function(Object error)? _onError;
  bool _isRunning = false;
  bool _isProcessing = false;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start({
    required CameraFaceSampleCallback onSample,
    required void Function(Object error) onError,
  }) async {
    if (_isRunning) return;
    _onSample = onSample;
    _onError = onError;

    try {
      configureLiteRtWebLoader(
        wasmUrl: 'https://cdn.jsdelivr.net/npm/@litertjs/core@2.4.0/wasm/',
      );
      _detector = await FaceDetector.create(
        model: FaceDetectionModel.frontCamera,
        meshPoolSize: 1,
      );

      final constraints = web.MediaStreamConstraints(
        video: <String, Object>{
          'facingMode': 'user',
          'width': <String, Object>{'ideal': 640},
          'height': <String, Object>{'ideal': 480},
        }.jsify()!,
        audio: false.toJS,
      );
      _stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        ..playsInline = true;
      video.style
        ..position = 'fixed'
        ..left = '-10000px'
        ..top = '0'
        ..width = '1px'
        ..height = '1px'
        ..opacity = '0'
        ..pointerEvents = 'none';
      _video = video;
      video.srcObject = _stream;
      web.document.body?.append(video);
      await video.play().toDart;
      await _waitUntilVideoReady(video);

      _isRunning = true;
      _samplingTimer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => unawaited(_sampleFrame()),
      );
    } catch (error, stackTrace) {
      debugPrint(
          'Browser camera engagement failed to start: $error\n$stackTrace');
      await stop();
      rethrow;
    }
  }

  Future<void> _waitUntilVideoReady(web.HTMLVideoElement video) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (video.videoWidth > 0 && video.videoHeight > 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('The browser camera did not provide a video frame.');
  }

  Future<void> _sampleFrame() async {
    final video = _video;
    final detector = _detector;
    if (!_isRunning || _isProcessing || video == null || detector == null) {
      return;
    }
    _isProcessing = true;
    try {
      final faces = await detector.detectFacesFromVideo(
        video,
        mode: FaceDetectionMode.full,
      );
      final face = faces.isEmpty ? null : faces.first;
      _onSample?.call(
        faceDetected: face != null,
        headPitch: face?.headEulerAngleX,
        headYaw: face?.headEulerAngleY,
        leftEyeOpen: face?.leftEyeOpenProbability,
        rightEyeOpen: face?.rightEyeOpenProbability,
        smileProbability: face?.smilingProbability,
      );
    } catch (error, stackTrace) {
      debugPrint(
          'Browser on-device face detection failed: $error\n$stackTrace');
      _onError?.call(error);
      await stop();
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> stop() async {
    _samplingTimer?.cancel();
    _samplingTimer = null;
    _isRunning = false;

    final stream = _stream;
    _stream = null;
    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
    }

    final video = _video;
    _video = null;
    if (video != null) {
      video.srcObject = null;
      video.remove();
    }

    final detector = _detector;
    _detector = null;
    await detector?.dispose();
    _onSample = null;
    _onError = null;
  }
}
