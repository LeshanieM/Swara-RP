import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

final therapyRecommendationsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, childId) async {
  if (StorageService.isDemoMode()) {
    await Future.delayed(const Duration(seconds: 1));
    return DemoData.therapyRecommendations(childId);
  }
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/therapy/recommendations/$childId');
  return response.data as Map<String, dynamic>;
});

class TherapySessionState {
  final bool isLoading;
  final String? sessionId;
  final int currentActivityIndex;
  final List<Map<String, dynamic>> activities;
  final Map<int, bool> completedActivities;
  final bool isComplete;

  const TherapySessionState({
    this.isLoading = false,
    this.sessionId,
    this.currentActivityIndex = 0,
    this.activities = const [],
    this.completedActivities = const {},
    this.isComplete = false,
  });

  TherapySessionState copyWith({
    bool? isLoading,
    String? sessionId,
    int? currentActivityIndex,
    List<Map<String, dynamic>>? activities,
    Map<int, bool>? completedActivities,
    bool? isComplete,
  }) {
    return TherapySessionState(
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
      currentActivityIndex: currentActivityIndex ?? this.currentActivityIndex,
      activities: activities ?? this.activities,
      completedActivities: completedActivities ?? this.completedActivities,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  double get engagementScore {
    if (activities.isEmpty) return 0;
    final completed = completedActivities.values.where((v) => v).length;
    return (completed / activities.length) * 100;
  }
}

class TherapyNotifier extends StateNotifier<TherapySessionState> {
  final ApiClient _api;
  final String childId;

  TherapyNotifier(this._api, this.childId) : super(const TherapySessionState());

  Future<void> startSession(List<Map<String, dynamic>> activities) async {
    state = state.copyWith(
      isLoading: true,
      activities: activities,
      currentActivityIndex: 0,
      completedActivities: {},
      isComplete: false,
    );
    try {
      if (!StorageService.isDemoMode()) {
        final response = await _api.post('/api/therapy/sessions', data: {
          'childId': childId,
          'activities': activities.map((a) => a['id']).toList(),
        });
        state = state.copyWith(
          isLoading: false,
          sessionId: response.data['sessionId'],
        );
      } else {
        state = state.copyWith(isLoading: false, sessionId: 'demo_session_${DateTime.now().millisecondsSinceEpoch}');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, sessionId: 'local_session');
    }
  }

  void completeActivity(int index) {
    final updated = Map<int, bool>.from(state.completedActivities);
    updated[index] = true;
    final allDone = updated.length == state.activities.length;
    state = state.copyWith(
      completedActivities: updated,
      isComplete: allDone,
      currentActivityIndex: allDone ? index : index + 1 < state.activities.length ? index + 1 : index,
    );
  }

  void reset() => state = const TherapySessionState();
}

final therapyNotifierProvider =
    StateNotifierProvider.family<TherapyNotifier, TherapySessionState, String>(
  (ref, childId) => TherapyNotifier(ref.read(apiClientProvider), childId),
);

final therapyKnowledgeBaseProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (StorageService.isDemoMode()) {
    return DemoData.therapyActivities;
  }
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/therapy/activities');
  return List<Map<String, dynamic>>.from(response.data);
});
