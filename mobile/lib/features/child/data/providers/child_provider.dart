import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_model.dart';
import '../models/demo_data.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/auth/data/models/user_model.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';

final childrenProvider = FutureProvider<List<ChildModel>>((ref) async {
  if (StorageService.isDemoMode()) {
    await Future.delayed(const Duration(milliseconds: 800));
    return DemoData.children;
  }
  final api = ref.read(apiClientProvider);
  final response = await api.get('/api/children');
  return (response.data as List).map((j) => ChildModel.fromJson(j)).toList();
});

final childProvider =
    FutureProvider.family<ChildModel, String>((ref, childId) async {
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

/// The child a therapist opened on the therapist home; child accounts don't use it.
final selectedChildProvider = StateProvider<ChildModel?>((ref) => null);

/// The child every component acts for: the signed-in child account's own child, or
/// the child a therapist selected. Null for a therapist who hasn't picked one yet.
final activeChildProvider = Provider<ChildRef?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  if (user.child != null) return user.child;
  final selected = ref.watch(selectedChildProvider);
  if (selected != null) {
    return ChildRef(childId: selected.childId, firstName: selected.firstName, age: selected.age);
  }
  if (StorageService.isDemoMode()) {
    final demo = DemoData.children.first;
    return ChildRef(childId: demo.childId, firstName: demo.firstName, age: demo.age);
  }
  return null;
});

class ChildNotifier extends StateNotifier<AsyncValue<List<ChildModel>>> {
  final ApiClient _api;

  ChildNotifier(this._api) : super(const AsyncValue.loading()) {
    loadChildren();
  }

  Future<void> loadChildren() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      if (StorageService.isDemoMode()) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        state = AsyncValue.data(DemoData.children);
        return;
      }
      final response = await _api.get('/api/children');
      if (!mounted) return;
      final children =
          (response.data as List).map((j) => ChildModel.fromJson(j)).toList();
      state = AsyncValue.data(children);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final childNotifierProvider =
    StateNotifierProvider<ChildNotifier, AsyncValue<List<ChildModel>>>((ref) {
  return ChildNotifier(ref.read(apiClientProvider));
});
