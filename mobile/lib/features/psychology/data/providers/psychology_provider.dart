import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

class PsychologyState {
  final bool isLoading;
  final Map<String, int> answers; // question id -> score (0-4)
  final Map<String, dynamic>? result;
  final String? error;

  const PsychologyState({
    this.isLoading = false,
    this.answers = const {},
    this.result,
    this.error,
  });

  PsychologyState copyWith({
    bool? isLoading,
    Map<String, int>? answers,
    Map<String, dynamic>? result,
    String? error,
  }) {
    return PsychologyState(
      isLoading: isLoading ?? this.isLoading,
      answers: answers ?? this.answers,
      result: result ?? this.result,
      error: error,
    );
  }

  double get score {
    if (answers.isEmpty) return 0;
    final total = answers.values.reduce((a, b) => a + b);
    final maxScore = answers.length * 4;
    return (total / maxScore) * 100;
  }
}

class PsychologyNotifier extends StateNotifier<PsychologyState> {
  final ApiClient _api;
  final String childId;

  PsychologyNotifier(this._api, this.childId) : super(const PsychologyState());

  void setAnswer(String questionId, int score) {
    final updated = Map<String, int>.from(state.answers);
    updated[questionId] = score;
    state = state.copyWith(answers: updated);
  }

  Future<Map<String, dynamic>?> submitQuestionnaire() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (StorageService.isDemoMode()) {
        await Future.delayed(const Duration(seconds: 2));
        final result = DemoData.psychologyResult(childId);
        state = state.copyWith(isLoading: false, result: result);
        return result;
      }

      final response = await _api.post('/api/psychology/assessment', data: {
        'childId': childId,
        'answers': state.answers,
      });
      final result = response.data as Map<String, dynamic>;
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit questionnaire. Please try again.',
      );
      return null;
    }
  }

  void reset() => state = const PsychologyState();
}

final psychologyNotifierProvider =
    StateNotifierProvider.family<PsychologyNotifier, PsychologyState, String>(
  (ref, childId) => PsychologyNotifier(ref.read(apiClientProvider), childId),
);

final psychologyHistoryProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, childId) async {
    if (StorageService.isDemoMode()) {
      return DemoData.psychologyResult(childId);
    }
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/psychology/$childId');
    return response.data as Map<String, dynamic>;
  },
);
