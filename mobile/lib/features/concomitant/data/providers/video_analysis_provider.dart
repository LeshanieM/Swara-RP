import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/network/api_exception.dart';
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
      'Unable to connect to the analysis service. Please check the backend connection. · විශ්ලේෂණ සේවාවට සම්බන්ධ විය නොහැක. සේවා සම්බන්ධතාව පරීක්ෂා කරන්න.';

  factory VideoAnalysisException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final api = ApiException.fromDio(e);
    final serverMsg = api.isNetwork ? null : api.message;

    if (status == null) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return const VideoAnalysisException(
          VideoAnalysisErrorKind.connection,
          'The video upload timed out. Try a smaller or shorter video, or use a faster connection. · වීඩියෝව උඩුගත කිරීමට වැඩි කාලයක් ගත විය. කුඩා හෝ කෙටි වීඩියෝවක් හෝ වේගවත් සම්බන්ධතාවක් භාවිත කරන්න.',
        );
      }
      return const VideoAnalysisException(VideoAnalysisErrorKind.connection, connectionMessage);
    }
    if (status == 401 || (status == 403 && !api.needsParentMode)) {
      final demo = StorageService.isDemoMode();
      return VideoAnalysisException(
        VideoAnalysisErrorKind.unauthorized,
        demo
            ? 'Video analysis needs a real signed-in account. Demo mode has no server session - '
                'sign out and log in with a registered account. · වීඩියෝ විශ්ලේෂණයට ලියාපදිංචි ගිණුමකින් පුරනය වන්න.'
            : (status == 401
                ? 'Your session has expired. Please sign in again. · ඔබේ සැසිය කල් ඉකුත් වී ඇත. නැවත පුරනය වන්න.'
                : '${api.message} · කරුණාකර නැවත උත්සාහ කරන්න.'),
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    if (status == 404) {
      return VideoAnalysisException(
        VideoAnalysisErrorKind.notFound,
        'This analysis was not found. It may have been deleted - please start a new analysis. · මෙම විශ්ලේෂණය සොයාගත නොහැක. එය මකා දමා තිබිය හැකියි. නව විශ්ලේෂණයක් අරඹන්න.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    if (status == 502 || status == 503 || status == 504) {
      return VideoAnalysisException(
        VideoAnalysisErrorKind.server,
        serverMsg ?? 'The server could not reach the vision service. Make sure it is running. · සේවාදායකයට දෘශ්‍ය සේවාවට සම්බන්ධ විය නොහැක. එය ක්‍රියාත්මකදැයි බලන්න.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    if (status >= 400 && status < 500) {
      return VideoAnalysisException(
        VideoAnalysisErrorKind.badRequest,
        serverMsg ?? 'The request was rejected by the server. · සේවාදායකය ඉල්ලීම පිළිගත්තේ නැත.',
        statusCode: status,
        serverMessage: serverMsg,
      );
    }
    return VideoAnalysisException(
      VideoAnalysisErrorKind.server,
      serverMsg ?? 'The analysis service reported an error. Please try again. · විශ්ලේෂණ සේවාවේ ගැටලුවක් ඇති විය. නැවත උත්සාහ කරන්න.',
      statusCode: status,
      serverMessage: serverMsg,
    );
  }

  static VideoAnalysisException from(Object e) {
    if (e is VideoAnalysisException) return e;
    if (e is DioException) return VideoAnalysisException.fromDio(e);
    return VideoAnalysisException(VideoAnalysisErrorKind.unknown, 'Something went wrong: $e · ගැටලුවක් ඇති විය.');
  }

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Service (Swara API /api/c2)
// ---------------------------------------------------------------------------

class VideoAnalysisService {
  final ApiClient _api;
  VideoAnalysisService(this._api);

  static const _base = '/api/c2/analyses';

  /// Uploads the ONE selected video as a parent upload (path B) and returns the analysis id.
  /// The API extracts the audio track and runs it through C1 to find the stutter moments,
  /// so ages 11–14 need the reading passage the child read in the video.
  Future<String> start({
    required String childId,
    required int age,
    required SelectedVideo video,
    String? passageId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final MultipartFile file;
      if (video.path != null && !kIsWeb) {
        file = await MultipartFile.fromFile(video.path!, filename: video.name);
      } else if (video.bytes != null) {
        file = MultipartFile.fromBytes(video.bytes!, filename: video.name);
      } else if (video.readStream != null) {
        file = MultipartFile.fromStream(() => video.readStream!, video.sizeBytes, filename: video.name);
      } else {
        throw const VideoAnalysisException(
          VideoAnalysisErrorKind.badRequest,
          'Could not read the selected video from the device.',
        );
      }
      final form = FormData.fromMap({
        'childId': childId,
        'age': age,
        'inputPath': 'parent_upload',
        'videoConsent': 'true',
        'language': 'si',
        if (passageId != null) 'passageId': passageId,
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

  /// Uploads the face video filmed during a C1 task (path A). C2 uses that C1 assessment's stutter moments,
  /// waiting for it if its analysis is still running, so no second C1 assessment is made.
  Future<String> startInTask({
    required String childId,
    required int age,
    required String c1AssessmentId,
    required String videoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'childId': childId,
        'age': age,
        'inputPath': 'in_task_camera',
        'videoConsent': 'true',
        'c1AssessmentId': c1AssessmentId,
        'video': await MultipartFile.fromFile(videoPath, filename: 'task.mp4'),
      });
      final res = await _api.postMultipart(_base, form);
      final id = res.data is Map ? res.data['analysisId'] : null;
      if (id is! String || id.isEmpty) {
        throw const VideoAnalysisException(VideoAnalysisErrorKind.server, 'The server did not return an analysis id.');
      }
      return id;
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }

  /// Status and, once completed, the result (one document).
  Future<VideoAnalysis> get(String id) async {
    try {
      final res = await _api.get('$_base/$id');
      return VideoAnalysis.fromJson(res.data);
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }

  Future<List<VideoAnalysis>> history(String childId) async {
    try {
      final res = await _api.get('/api/c2/children/$childId/analyses', queryParameters: {'limit': 10});
      final items = res.data is Map ? res.data['items'] : null;
      if (items is! List) return const [];
      return items.map(VideoAnalysis.fromJson).toList(growable: false);
    } on DioException catch (e) {
      throw VideoAnalysisException.fromDio(e);
    }
  }
}

final videoAnalysisServiceProvider = Provider<VideoAnalysisService>(
  (ref) => VideoAnalysisService(ref.watch(apiClientProvider)),
);

// ---------------------------------------------------------------------------
// Video selection (one video only)
// ---------------------------------------------------------------------------

const kAllowedVideoExtensions = ['mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv'];

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
        withData: kIsWeb, // Web needs in-memory bytes; native platforms prefer a path or stream.
        withReadStream: !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS),
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final ext = (f.extension ?? f.name.split('.').last).toLowerCase();
      final path = kIsWeb ? null : f.path;
      final readStream = kIsWeb ? null : f.readStream;

      String? err;
      if (!kAllowedVideoExtensions.contains(ext)) {
        err = 'Unsupported format (.$ext). Use: ${kAllowedVideoExtensions.join(', ')}. · සහාය නොදක්වන ආකෘතියකි. ලැයිස්තුවෙන් ආකෘතියක් තෝරන්න.';
      } else if (f.size <= 0) {
        err = 'The selected file is empty or unreadable. · තෝරාගත් ගොනුව හිස් හෝ කියවිය නොහැක.';
      } else if (path == null && f.bytes == null && readStream == null) {
        err = 'Could not read the file from the device. · උපාංගයෙන් ගොනුව කියවිය නොහැක.';
      } else if (f.size > AppConstants.maxVideoSizeMb * 1024 * 1024) {
        err = 'The video is larger than ${AppConstants.maxVideoSizeMb} MB. Please choose a shorter clip. · වීඩියෝව ${AppConstants.maxVideoSizeMb} MB ට වඩා විශාලයි. කෙටි වීඩියෝවක් තෝරන්න.';
      }
      state = err != null
          ? SelectedVideoState(video: state.video, error: err)
          : SelectedVideoState(
              video: SelectedVideo(name: f.name, sizeBytes: f.size, path: path, bytes: f.bytes, readStream: readStream),
            );
    } catch (_) {
      state = SelectedVideoState(video: state.video, error: 'Could not open the file picker. · ගොනු තේරීම විවෘත කළ නොහැකි විය.');
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
  Future<String?> start({required String childId, required int age, String? passageId}) async {
    if (state.isUploading) return null;
    final video = _ref.read(selectedVideoProvider).video;
    if (video == null) {
      state = const VideoAnalysisStartState(error: 'Please select a video before starting the analysis. · විශ්ලේෂණය ආරම්භ කිරීමට පෙර වීඩියෝවක් තෝරන්න.');
      return null;
    }
    state = const VideoAnalysisStartState(isUploading: true);
    try {
      final id = await _ref.read(videoAnalysisServiceProvider).start(
            childId: childId,
            age: age,
            passageId: passageId,
            video: video,
            onProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              state = VideoAnalysisStartState(isUploading: true, progress: sent / total);
            },
          );
      if (mounted) state = const VideoAnalysisStartState();
      return id;
    } catch (e) {
      final ex = VideoAnalysisException.from(e);
      final msg = switch (ex.kind) {
        VideoAnalysisErrorKind.connection || VideoAnalysisErrorKind.unauthorized => ex.message,
        _ => 'Video upload failed · වීඩියෝව උඩුගත කිරීමට නොහැකි විය. ${ex.message}',
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
  final VideoAnalysis? status;
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
      final s = await _service.get(analysisId);
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
    FutureProvider.autoDispose.family<VideoAnalysis, String>((ref, id) {
  return ref.watch(videoAnalysisServiceProvider).get(id);
});

final videoAnalysisHistoryProvider =
    FutureProvider.autoDispose.family<List<VideoAnalysis>, String>((ref, childId) {
  return ref.watch(videoAnalysisServiceProvider).history(childId);
});
