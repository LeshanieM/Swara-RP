import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

class CommunicationState {
  final bool isLoading;
  final int currentTaskIndex;
  final Map<String, dynamic>? result;
  final String? audioPath;
  final String? error;

  const CommunicationState({
    this.isLoading = false,
    this.currentTaskIndex = 0,
    this.result,
    this.audioPath,
    this.error,
  });

  CommunicationState copyWith({
    bool? isLoading,
    int? currentTaskIndex,
    Map<String, dynamic>? result,
    String? audioPath,
    String? error,
  }) {
    return CommunicationState(
      isLoading: isLoading ?? this.isLoading,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      result: result ?? this.result,
      audioPath: audioPath ?? this.audioPath,
      error: error,
    );
  }
}

class CommunicationNotifier extends StateNotifier<CommunicationState> {
  final ApiClient _api;
  final String childId;

  CommunicationNotifier(this._api, this.childId) : super(const CommunicationState());

  void setAudioPath(String path) => state = state.copyWith(audioPath: path);

  void selectTask(int index) => state = state.copyWith(currentTaskIndex: index);

  Future<Map<String, dynamic>?> analyze(int taskIndex) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (StorageService.isDemoMode()) {
        await Future.delayed(const Duration(seconds: 2));
        final result = DemoData.communicationResult(childId);
        state = state.copyWith(isLoading: false, result: result);
        return result;
      }

      final response = await _api.post('/api/communication/analyze', data: {
        'childId': childId,
        'taskId': DemoData.communicationTasks[taskIndex]['id'],
        'audioPath': state.audioPath,
      });
      final result = response.data as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Analysis failed. Please try again.',
      );
      return null;
    }
  }

  void reset() => state = const CommunicationState();
}

final communicationNotifierProvider =
    StateNotifierProvider.family<CommunicationNotifier, CommunicationState, String>(
  (ref, childId) => CommunicationNotifier(ref.read(apiClientProvider), childId),
);

final communicationHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, childId) async {
    if (StorageService.isDemoMode()) {
      return DemoData.progressHistory(childId).map((h) => {
            'session': h['session'],
            'date': h['date'],
            'score': h['commScore'],
          }).toList();
    }
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/communication/$childId');
    return List<Map<String, dynamic>>.from(response.data);
  },
);
