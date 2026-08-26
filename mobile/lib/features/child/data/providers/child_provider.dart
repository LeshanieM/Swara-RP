import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_model.dart';
import '../models/demo_data.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';

final childrenProvider = FutureProvider<List<ChildModel>>((ref) async {
  if (StorageService.isDemoMode()) {
    await Future.delayed(const Duration(milliseconds: 800));
    return DemoData.children;
  }
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/children');
  return (response.data as List).map((j) => ChildModel.fromJson(j)).toList();
});

final childProvider = FutureProvider.family<ChildModel, String>((ref, childId) async {
  if (StorageService.isDemoMode()) {
    await Future.delayed(const Duration(milliseconds: 400));
    return DemoData.children.firstWhere(
      (c) => c.id == childId || c.childId == childId,
      orElse: () => DemoData.children.first,
    );
  }
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/children/$childId');
  return ChildModel.fromJson(response.data);
});

final selectedChildProvider = StateProvider<ChildModel?>((ref) => null);

class ChildNotifier extends StateNotifier<AsyncValue<List<ChildModel>>> {
  final ApiClient _api;

  ChildNotifier(this._api) : super(const AsyncValue.loading()) {
    loadChildren();
  }

  Future<void> loadChildren() async {
    state = const AsyncValue.loading();
    try {
      if (StorageService.isDemoMode()) {
        await Future.delayed(const Duration(milliseconds: 600));
        state = AsyncValue.data(DemoData.children);
        return;
      }
      final response = await _api.get('/api/children');
      final children = (response.data as List).map((j) => ChildModel.fromJson(j)).toList();
      state = AsyncValue.data(children);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addChild(Map<String, dynamic> childData) async {
    try {
      if (StorageService.isDemoMode()) {
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }
      await _api.post('/api/children', data: childData);
      await loadChildren();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final childNotifierProvider = StateNotifierProvider<ChildNotifier, AsyncValue<List<ChildModel>>>((ref) {
  return ChildNotifier(ref.read(apiClientProvider));
});
