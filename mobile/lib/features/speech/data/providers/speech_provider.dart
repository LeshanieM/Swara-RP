import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

enum SpeechRecordState { idle, recording, stopped, uploading, analyzing, done, error }

class SpeechAnalysisState {
  final SpeechRecordState recordState;
  final String? audioPath;
  final Map<String, dynamic>? result;
  final String? error;
  final int recordDuration;

  const SpeechAnalysisState({
    this.recordState = SpeechRecordState.idle,
    this.audioPath,
    this.result,
    this.error,
    this.recordDuration = 0,
  });

  SpeechAnalysisState copyWith({
    SpeechRecordState? recordState,
    String? audioPath,
    Map<String, dynamic>? result,
    String? error,
    int? recordDuration,
  }) {
    return SpeechAnalysisState(
      recordState: recordState ?? this.recordState,
      audioPath: audioPath ?? this.audioPath,
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

  void setAudioPath(String path) {
    state = state.copyWith(audioPath: path, recordState: SpeechRecordState.stopped);
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

  Future<Map<String, dynamic>?> analyze() async {
    if (state.audioPath == null && !StorageService.isDemoMode()) return null;
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

      final formData = await _buildFormData();
      final response = await _api.postMultipart('/api/speech/analyze', formData);
      final result = response.data as Map<String, dynamic>;
      state = state.copyWith(recordState: SpeechRecordState.done, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        recordState: SpeechRecordState.error,
        error: 'Analysis failed. Please try again.',
      );
      return null;
    }
  }

  Future<dynamic> _buildFormData() async {
    // Return FormData for real upload
    // For now build minimal form
    return {};
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
