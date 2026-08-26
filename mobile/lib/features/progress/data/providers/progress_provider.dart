import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

final progressProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, childId) async {
    if (StorageService.isDemoMode()) {
      await Future.delayed(const Duration(milliseconds: 600));
      return DemoData.progressHistory(childId);
    }
    final api = ref.read(apiClientProvider);
    final response = await api.get('/api/progress/$childId');
    return List<Map<String, dynamic>>.from(response.data);
  },
);
