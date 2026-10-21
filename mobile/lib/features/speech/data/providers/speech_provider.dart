import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/audio/wav_recorder.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/storage/storage_service.dart';
import '../models/speech_assessment.dart';

/// Component 1 on the Swara API (/api/c1): the task for an age, the assessment upload,
/// polling until the background analysis finishes, and the child's history and summary.
class SpeechService {
  final ApiClient _api;
  SpeechService(this._api);

  static const _pollEvery = Duration(seconds: 2);
  static const _pollFor = Duration(minutes: 10);

  Future<SpeechTask> task(int age) async {
    try {
      final res = await _api.get('/api/c1/tasks', queryParameters: {'age': age, 'language': 'si'});
      return SpeechTask.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Uploads the recording; returns the assessment id (the API answers 202 and analyses in the background).
  Future<String> submit({
    required RecordedAudio audio,
    required String childId,
    required int age,
    required SpeechTask task,
    SpeechPassage? passage,
    SpeechPicture? picture,
  }) async {
    final form = FormData.fromMap({
      'audio': await audio.toMultipart(audio.name),
      'childId': childId,
      'age': age,
      'taskType': task.taskType,
      'language': 'si',
      if (task.isReading && passage != null) 'passageId': passage.id,
      if (!task.isReading && picture != null) 'pictureId': picture.id,
    });
    try {
      final res = await _api.postMultipart('/api/c1/assessments', form);
      return res.data['assessmentId'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Polls GET /assessments/:id until it is completed (returns the result) or failed (throws).
  Future<SpeechResult> waitForResult(String assessmentId) async {
    final deadline = DateTime.now().add(_pollFor);
    while (DateTime.now().isBefore(deadline)) {
      final Map<String, dynamic> doc;
      try {
        doc = (await _api.get('/api/c1/assessments/$assessmentId')).data;
      } on DioException catch (e) {
        throw ApiException.fromDio(e);
      }
      switch (doc['status']) {
        case 'completed':
          return SpeechResult.fromResult(doc['result']);
        case 'failed':
          throw ApiException(
            doc['error']?['code'] ?? 'analysis_failed',
            doc['error']?['message'] ?? 'The analysis failed.',
          );
      }
      await Future.delayed(_pollEvery);
    }
    throw const ApiException('timeout', 'The analysis is taking too long. Try again later.');
  }

  Future<Map<String, dynamic>> summary(String childId) async {
    try {
      return (await _api.get('/api/c1/children/$childId/summary')).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService(ref.read(apiClientProvider)));

/// The result for one submission; demo mode returns the sample result.
final speechResultProvider = FutureProvider.autoDispose.family<SpeechResult, String?>((ref, assessmentId) async {
  if (StorageService.isDemoMode() || assessmentId == null) return SpeechResult.demo;
  return ref.read(speechServiceProvider).waitForResult(assessmentId);
});

final speechTaskProvider = FutureProvider.autoDispose.family<SpeechTask, int>((ref, age) async {
  if (StorageService.isDemoMode()) {
    return SpeechTask(taskType: age <= 10 ? 'picture_description' : 'reading', ageBand: age <= 10 ? '5-10' : '11-14');
  }
  return ref.read(speechServiceProvider).task(age);
});
