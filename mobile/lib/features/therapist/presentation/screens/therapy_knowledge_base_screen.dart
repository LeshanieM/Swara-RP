import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/network/api_client.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/features/child/data/models/demo_data.dart';

/// The C3 activity pool (type × difficulty, both age bands) from /api/c3/activities,
/// in the card shape this screen shows. Demo mode shows the sample activities.
final therapyKnowledgeBaseProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (StorageService.isDemoMode()) return DemoData.therapyActivities;
  final api = ref.read(apiClientProvider);
  final cards = <Map<String, dynamic>>[];
  try {
    for (final age in const [8, 12]) {
      final res = await api.get('/api/c3/activities', queryParameters: {'age': age});
      for (final arm in (res.data['arms'] as List? ?? const [])) {
        final band = (arm['ageBand'] as String? ?? '5-10').split('-').map(int.parse).toList();
        cards.add({
          'name': '${arm['title']?['en'] ?? arm['type']} · ${arm['title']?['si'] ?? ''}',
          'description': 'Target skill: ${(arm['targetSkill'] as String? ?? '').replaceAll('_', ' ')} · '
              '${arm['items']} content item${arm['items'] == 1 ? '' : 's'}',
          'severity': const <String>[],
          'stutterTypes': const <String>[],
          'difficulty': arm['difficulty'] ?? '',
          'duration': arm['durationMin'] ?? 0,
          'ageRange': band,
          'therapistNotes': arm['placeholder'] == true
              ? 'Placeholder content: an SLP must review the wording before use.'
              : '',
        });
      }
    }
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
  return cards;
});

class TherapyKnowledgeBaseScreen extends ConsumerWidget {
  const TherapyKnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(therapyKnowledgeBaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapy Knowledge Base'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: activitiesAsync.when(
        loading: () => const SwaraLoadingWidget(message: 'Loading knowledge base...'),
        error: (e, _) => SwaraErrorWidget(message: ApiException.from(e).message),
        data: (activities) => Column(
          children: [
            const DisclaimerBanner(
              message: 'The activity pool the C3 recommender chooses from (SLP-approved type × difficulty).',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activities.length,
                itemBuilder: (ctx, i) => _ActivityCard(activity: activities[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Activity', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddActivityDialog(),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final name = activity['name'] as String? ?? '';
    final desc = activity['description'] as String? ?? '';
    final severity = List<String>.from(activity['severity'] ?? []);
    final stutterTypes = List<String>.from(activity['stutterTypes'] ?? []);
    final difficulty = activity['difficulty'] as String? ?? '';
    final duration = activity['duration'] as int? ?? 0;
    final ageRange = List<int>.from(activity['ageRange'] ?? [5, 12]);
    final notes = activity['therapistNotes'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: AppTextStyles.heading3)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryWash,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(difficulty, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _tag('Age: ${ageRange.first}-${ageRange.last}', AppColors.textLight),
              _tag('${duration}m', AppColors.textLight),
              ...severity.map((s) => _tag(s, AppColors.warning)),
              ...stutterTypes.map((t) => _tag(t, AppColors.primary)),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Expanded(child: Text(notes, style: AppTextStyles.caption)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outlined, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      );
}

class _AddActivityDialog extends StatefulWidget {
  const _AddActivityDialog();

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Activity Name')),
            const SizedBox(height: 10),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 10),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Therapist Notes'), maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Activity added to knowledge base!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
