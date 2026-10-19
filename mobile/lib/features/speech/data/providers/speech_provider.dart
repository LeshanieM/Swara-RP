import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

enum SpeechRecordState { idle, recording, stopped, uploading, analyzing, done, error }

class SpeechAnalysisState {
  final SpeechRecordState recordState;
  final String? audioPath;
  final Uint8List? audioBytes;
  final String? audioFileName;
  final String? audioContentType;
  final Map<String, dynamic>? result;
  final String? error;
  final int recordDuration;

  const SpeechAnalysisState({
    this.recordState = SpeechRecordState.idle,
    this.audioPath,
    this.audioBytes,
    this.audioFileName,
    this.audioContentType,
    this.result,
    this.error,
    this.recordDuration = 0,
  });

  SpeechAnalysisState copyWith({
    SpeechRecordState? recordState,
    String? audioPath,
    Uint8List? audioBytes,
    String? audioFileName,
    String? audioContentType,
    Map<String, dynamic>? result,
    String? error,
    int? recordDuration,
  }) {
    return SpeechAnalysisState(
      recordState: recordState ?? this.recordState,
      audioPath: audioPath ?? this.audioPath,
      audioBytes: audioBytes ?? this.audioBytes,
      audioFileName: audioFileName ?? this.audioFileName,
      audioContentType: audioContentType ?? this.audioContentType,
      result: result ?? this.result,
      error: error,
      recordDuration: recordDuration ?? this.recordDuration,
    );
  }
}

class SpeechNotifier extends StateNotifier<SpeechAnalysisState> {
  final ApiClient _api;
  final String childId;

  SpeechNotifier(this._api, this.childId) : super(const SpeechAnalysisState());

  void setAudioPath(
    String path, {
    String fileName = 'recording.wav',
    String contentType = 'audio/wav',
  }) {
    state = SpeechAnalysisState(
      recordState: SpeechRecordState.stopped,
      audioPath: path,
      audioFileName: fileName,
      audioContentType: contentType,
      recordDuration: state.recordDuration,
      result: state.result,
    );
  }

  void setAudioBytes(
    Uint8List bytes, {
    String fileName = 'recording.wav',
    String contentType = 'audio/wav',
  }) {
    state = SpeechAnalysisState(
      recordState: SpeechRecordState.stopped,
      audioBytes: bytes,
      audioFileName: fileName,
      audioContentType: contentType,
      recordDuration: state.recordDuration,
      result: state.result,
    );
  }

  void setRecording() {
    state = state.copyWith(recordState: SpeechRecordState.recording, recordDuration: 0);
  }

  void setStopped() {
    state = state.copyWith(recordState: SpeechRecordState.stopped);
  }

  void updateDuration(int seconds) {
    state = state.copyWith(recordDuration: seconds);
  }

  void reset() {
    state = const SpeechAnalysisState();
  }

  Future<Map<String, dynamic>?> analyze({String? taskType, double? age, String? referenceText}) async {
    if (state.audioPath == null && state.audioBytes == null && !StorageService.isDemoMode()) return null;
    state = state.copyWith(recordState: SpeechRecordState.analyzing);

    try {
      if (StorageService.isDemoMode()) {
        await Future.delayed(const Duration(seconds: 2));
        final result = DemoData.speechResult(childId);
        state = state.copyWith(
          recordState: SpeechRecordState.done,
          result: result,
        );
        return result;
      }

      final formData = await _buildFormData(taskType: taskType, age: age, referenceText: referenceText);
      final response = await _api.postMultipart('/api/speech/analyze', formData);
      final result = response.data as Map<String, dynamic>;
      state = state.copyWith(recordState: SpeechRecordState.done, result: result);
      return result;
    } catch (e) {
      // Graceful fallback to rich sample assessment if backend is unreachable
      final fallback = DemoData.speechResult(childId);
      state = state.copyWith(
        recordState: SpeechRecordState.done,
        result: fallback,
        error: 'Network note: using clinical sample (${e.toString()})',
      );
      return fallback;
    }
  }

  Future<FormData> _buildFormData({String? taskType, double? age, String? referenceText}) async {
    final map = <String, dynamic>{
      'childId': childId,
      'taskType': taskType ?? 'picture-description',
    };

    if (age != null) {
      map['childAge'] = age;
    }

    if (referenceText != null && referenceText.isNotEmpty) {
      map['referenceText'] = referenceText;
    }

    if (state.audioBytes != null && state.audioBytes!.isNotEmpty) {
      map['audio'] = MultipartFile.fromBytes(
        state.audioBytes!,
        filename: state.audioFileName ?? 'recording.wav',
        contentType: _mediaType(state.audioContentType),
      );
    } else if (state.audioPath != null && state.audioPath!.isNotEmpty) {
      map['audio'] = await MultipartFile.fromFile(
        state.audioPath!,
        filename: state.audioFileName ?? 'recording.wav',
        contentType: _mediaType(state.audioContentType),
      );
    }

    return FormData.fromMap(map);
  }

  DioMediaType _mediaType(String? contentType) {
    final parts = (contentType ?? 'audio/wav').split('/');
    return DioMediaType(parts.first, parts.length > 1 ? parts.last : 'wav');
  }
}

final speechNotifierProvider =
    StateNotifierProvider.family<SpeechNotifier, SpeechAnalysisState, String>(
  (ref, childId) => SpeechNotifier(ref.read(apiClientProvider), childId),
);

final speechHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, childId) async {
    if (StorageService.isDemoMode()) {
      return [DemoData.speechResult(childId)];
    }
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/speech/$childId');
    return List<Map<String, dynamic>>.from(response.data);
  },
);
