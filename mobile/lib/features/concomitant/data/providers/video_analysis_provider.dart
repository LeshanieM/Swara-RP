import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/concomitant/data/models/video_analysis_models.dart';

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------

enum VideoAnalysisErrorKind { connection, unauthorized, notFound, badRequest, server, unknown }

/// A backend/network failure with a message that is safe to show to the user.
class VideoAnalysisException implements Exception {
  final VideoAnalysisErrorKind kind;
  final String message;
  final int? statusCode;

  /// Raw message sent by the server (if any), e.g. "Unsupported video format".
  final String? serverMessage;

  const VideoAnalysisException(this.kind, this.message, {this.statusCode, this.serverMessage});

  static const connectionMessage =
      'Unable to connect to the analysis service. Please check the backend connection.';

  factory VideoAnalysisException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final serverMsg = data is Map && data['message'] != null ? data['message'].toString() : null;

    if (status == null) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return const VideoAnalysisException(
          VideoAnalysisErrorKind.connection,
          'The video upload timed out. Try a smaller or shorter video, or use a faster connection.',
        );
      }
      return const VideoAnalysisException(VideoAnalysisErrorKind.connection, connectionMessage);
    }
    if (status == 401 || status == 403) {
      final demo = StorageService.isDemoMode();
      return VideoAnalysisException(
        VideoAnalysisErrorKind.unauthorized,
        demo
            ? 'Video analysis needs a real signed-in account. Demo mode has no backend session - '
                'sign out and log in with a registered account.'
            : 'Your session is not authorised for this analysis. Please sign in again.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    if (status == 404) {
      return VideoAnalysisException(
        VideoAnalysisErrorKind.notFound,
        'This analysis was not found. The analysis service may have been restarted - '
        'please start a new analysis.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    if (status == 502 || status == 503 || status == 504) {
      return VideoAnalysisException(
        VideoAnalysisErrorKind.server,
        'The server could not reach the computer-vision service. '
        'Make sure the FastAPI service is running.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    if (status >= 400 && status < 500) {
      return VideoAnalysisException(
        VideoAnalysisErrorKind.badRequest,
        serverMsg ?? 'The request was rejected by the server.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    return VideoAnalysisException(
      VideoAnalysisErrorKind.server,
      serverMsg ?? 'The analysis service reported an error. Please try again.',
      statusCode: status,
      serverMessage: serverMsg,
    );
  }

  static VideoAnalysisException from(Object e) {
    if (e is VideoAnalysisException) return e;
    if (e is DioException) return VideoAnalysisException.fromDio(e);
    return VideoAnalysisException(VideoAnalysisErrorKind.unknown, 'Something went wrong: $e');
  }

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Service (Flutter -> Node -> FastAPI)
// ---------------------------------------------------------------------------

class VideoAnalysisService {
  final ApiClient _api;
  VideoAnalysisService(this._api);

  static const _base = '/api/concomitant/video-analysis';

  /// Uploads the ONE selected video and returns the analysis id.
  Future<String> start({
    required String childId,
    required SelectedVideo video,
    String technologies = 'all',
    bool generateOverlay = false,
    String? groundTruthJson,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final MultipartFile file;
      if (video.path != null && !kIsWeb) {
        file = await MultipartFile.fromFile(video.path!, filename: video.name);
      } else if (video.bytes != null) {
        file = MultipartFile.fromBytes(video.bytes!, filename: video.name);
      } else {
        throw const VideoAnalysisException(
          VideoAnalysisErrorKind.badRequest,
          'Could not read the selected video from the device.',
        );
      }
      final form = FormData.fromMap({
        'childId': childId,
        'technologies': technologies,
        'generateOverlay': generateOverlay.toString(),
        if (groundTruthJson != null) 'groundTruth': groundTruthJson,
        'video': file,
      });
      final res = await _api.postMultipart(_base, form, onSendProgress: onProgress);
      final id = res.data is Map ? res.data['analysisId'] : null;
      if (id is! String || id.isEmpty) {
        throw const VideoAnalysisException(
            VideoAnalysisErrorKind.server, 'The server did not return an analysis id.');
      }
      return id;
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }

  Future<AnalysisStatus> status(String id) async {
    try {
      final res = await _api.get('$_base/$id');
      return AnalysisStatus.fromJson(res.data);
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }

  Future<VideoAnalysisResults> results(String id) async {
    try {
      final res = await _api.get('$_base/$id/results');
      return VideoAnalysisResults.fromJson(res.data);
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }

  Future<List<VideoAnalysisSummary>> history(String childId) async {
    try {
      final res = await _api.get('$_base/history/$childId');
      final data = res.data;
      if (data is! List) return const [];
      return data.map(VideoAnalysisSummary.fromJson).toList(growable: false);
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }

  /// URL + headers for the annotated video of one technology. Browsers cannot
  /// send headers from a <video> element, so on web the token is a query param.
  Future<({String url, Map<String, String> headers})> overlaySource(String id, String techKey) async {
    final token = await StorageService.getToken();
    final url = '${AppConstants.baseUrl}$_base/$id/overlay/$techKey';
    if (kIsWeb) {
      return (url: token == null ? url : '$url?access_token=${Uri.encodeQueryComponent(token)}', headers: <String, String>{});
    }
    return (url: url, headers: <String, String>{if (token != null) 'Authorization': 'Bearer $token'});
  }
}

final videoAnalysisServiceProvider = Provider<VideoAnalysisService>(
  (ref) => VideoAnalysisService(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// Video selection (one video only)
// ---------------------------------------------------------------------------

const kAllowedVideoExtensions = ['mp4', 'mov', 'webm', 'avi', 'mkv'];

class SelectedVideoState {
  final SelectedVideo? video;
  final String? error;
  const SelectedVideoState({this.video, this.error});
}

class SelectedVideoNotifier extends StateNotifier<SelectedVideoState> {
  SelectedVideoNotifier() : super(const SelectedVideoState());

  Future<void> pick() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: kIsWeb, // web has no file path; native streams from disk
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final ext = (f.extension ?? f.name.split('.').last).toLowerCase();
      final path = kIsWeb ? null : f.path;

      String? err;
      if (!kAllowedVideoExtensions.contains(ext)) {
        err = 'Unsupported format (.$ext). Use: ${kAllowedVideoExtensions.join(', ')}.';
      } else if (f.size <= 0) {
        err = 'The selected file is empty or unreadable.';
      } else if (path == null && f.bytes == null) {
        err = 'Could not read the file from the device.';
      } else if (f.size > AppConstants.maxVideoSizeMb * 1024 * 1024) {
        err = 'The video is larger than ${AppConstants.maxVideoSizeMb} MB. Please choose a shorter clip.';
      }
      state = err != null
          ? SelectedVideoState(video: state.video, error: err)
          : SelectedVideoState(
              video: SelectedVideo(name: f.name, sizeBytes: f.size, path: path, bytes: f.bytes),
            );
    } catch (_) {
      state = SelectedVideoState(video: state.video, error: 'Could not open the file picker.');
    }
  }

  void setDuration(Duration d) {
    final v = state.video;
    if (v == null || v.duration == d) return;
    state = SelectedVideoState(video: v.copyWith(duration: d));
  }

  void clear() => state = const SelectedVideoState();
}

final selectedVideoProvider =
    StateNotifierProvider<SelectedVideoNotifier, SelectedVideoState>((ref) => SelectedVideoNotifier());

/// Whether to ask the backend for annotated (overlay) videos.
final generateOverlayProvider = StateProvider<bool>((ref) => false);

/// Optional ground-truth annotations attached by a researcher.
class GroundTruthNotifier extends StateNotifier<GroundTruthAttachment?> {
  GroundTruthNotifier() : super(null);

  /// Returns an error message, or null on success / cancel.
  Future<String?> pick() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) return null;
      final f = res.files.first;
      final bytes = f.bytes;
      if (bytes == null) return 'Could not read the annotation file.';
      final text = utf8.decode(bytes);
      final decoded = jsonDecode(text);
      final annotations = decoded is Map ? decoded['annotations'] : null;
      if (annotations is! List || annotations.isEmpty) {
        return 'The JSON must contain a non-empty "annotations" list.';
      }
      state = GroundTruthAttachment(fileName: f.name, json: text, annotationCount: annotations.length);
      return null;
    } on FormatException {
      return 'The selected file is not valid JSON.';
    } catch (_) {
      return 'Could not read the annotation file.';
    }
  }

  void clear() => state = null;
}

final groundTruthProvider =
    StateNotifierProvider<GroundTruthNotifier, GroundTruthAttachment?>((ref) => GroundTruthNotifier());

/// analysisId -> the local video used for it (lets the overlay screen show the
/// original next to the annotated video; the backend never keeps raw video).
final localVideoByAnalysisProvider = StateProvider<Map<String, SelectedVideo>>((ref) => const {});

// ---------------------------------------------------------------------------
// Analysis creation ("VideoAnalysisProvider")
// ---------------------------------------------------------------------------

class VideoAnalysisStartState {
  final bool isUploading;
  final double progress; // 0..1
  final String? error;
  const VideoAnalysisStartState({this.isUploading = false, this.progress = 0, this.error});
}

class VideoAnalysisController extends StateNotifier<VideoAnalysisStartState> {
  final Ref _ref;
  VideoAnalysisController(this._ref) : super(const VideoAnalysisStartState());

  /// Uploads the selected video and creates the analysis.
  /// Returns the analysis id, or null (with [state].error set) on failure.
  Future<String?> start({required String childId}) async {
    if (state.isUploading) return null;
    final video = _ref.read(selectedVideoProvider).video;
    if (video == null) {
      state = const VideoAnalysisStartState(error: 'Please select a video before starting the analysis.');
      return null;
    }
    state = const VideoAnalysisStartState(isUploading: true);
    try {
      final id = await _ref.read(videoAnalysisServiceProvider).start(
            childId: childId,
            video: video,
            generateOverlay: _ref.read(generateOverlayProvider),
            groundTruthJson: _ref.read(groundTruthProvider)?.json,
            onProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              state = VideoAnalysisStartState(isUploading: true, progress: sent / total);
            },
          );
      _ref.read(localVideoByAnalysisProvider.notifier).update((m) => {...m, id: video});
      if (mounted) state = const VideoAnalysisStartState();
      return id;
    } catch (e) {
      final ex = VideoAnalysisException.from(e);
      final msg = switch (ex.kind) {
        VideoAnalysisErrorKind.connection || VideoAnalysisErrorKind.unauthorized => ex.message,
        _ => 'Video upload failed. ${ex.message}',
      };
      if (mounted) state = VideoAnalysisStartState(error: msg);
      return null;
    }
  }

  void clearError() {
    if (state.error != null && !state.isUploading) state = const VideoAnalysisStartState();
  }
}

final videoAnalysisProvider =
    StateNotifierProvider<VideoAnalysisController, VideoAnalysisStartState>(
        (ref) => VideoAnalysisController(ref));

// ---------------------------------------------------------------------------
// Live status polling ("VideoAnalysisStatusProvider")
// ---------------------------------------------------------------------------

class StatusPollState {
  final AnalysisStatus? status;
  final VideoAnalysisException? error;
  final int consecutiveFailures;
  const StatusPollState({this.status, this.error, this.consecutiveFailures = 0});
}

class StatusPoller extends StateNotifier<StatusPollState> {
  final VideoAnalysisService _service;
  final String analysisId;
  Timer? _timer;
  bool _busy = false;

  StatusPoller(this._service, this.analysisId) : super(const StatusPollState()) {
    poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => poll());
  }

  Future<void> poll() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      final s = await _service.status(analysisId);
      if (!mounted) return;
      state = StatusPollState(status: s);
      if (s.isTerminal) _timer?.cancel();
    } catch (e) {
      if (!mounted) return;
      final ex = VideoAnalysisException.from(e);
      state = StatusPollState(
        status: state.status,
        error: ex,
        consecutiveFailures: state.consecutiveFailures + 1,
      );
      // Auth / not-found will not fix themselves; keep retrying only transient errors.
      if (ex.kind == VideoAnalysisErrorKind.unauthorized || ex.kind == VideoAnalysisErrorKind.notFound) {
        _timer?.cancel();
      }
    } finally {
      _busy = false;
    }
  }

  /// Manual retry after polling stopped or the connection dropped.
  void retryNow() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => poll());
    }
    poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final videoAnalysisStatusProvider =
    StateNotifierProvider.autoDispose.family<StatusPoller, StatusPollState, String>(
  (ref, id) => StatusPoller(ref.watch(videoAnalysisServiceProvider), id),
);

// ---------------------------------------------------------------------------
// Results / history / selections
// ---------------------------------------------------------------------------

final videoAnalysisResultsProvider =
    FutureProvider.autoDispose.family<VideoAnalysisResults, String>((ref, id) {
  return ref.watch(videoAnalysisServiceProvider).results(id);
});

final videoAnalysisHistoryProvider =
    FutureProvider.autoDispose.family<List<VideoAnalysisSummary>, String>((ref, childId) {
  return ref.watch(videoAnalysisServiceProvider).history(childId);
});

/// Technology key chosen on the timeline / overlay screens (per analysis).
final selectedTechnologyProvider = StateProvider.family<String?, String>((ref, analysisId) => null);

/// Behaviors visible on the timeline (per analysis). null = all behaviors.
final selectedBehaviorsProvider = StateProvider.family<Set<String>?, String>((ref, analysisId) => null);

/// analysisId|techKey -> annotated-video URL + auth headers.
final overlaySourceProvider = FutureProvider.autoDispose
    .family<({String url, Map<String, String> headers}), String>((ref, arg) {
  final parts = arg.split('|');
  return ref.watch(videoAnalysisServiceProvider).overlaySource(parts[0], parts[1]);
});
