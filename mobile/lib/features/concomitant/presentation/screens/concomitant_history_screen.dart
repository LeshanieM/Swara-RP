import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:intl/intl.dart';
import '../../data/providers/concomitant_provider.dart';

class ConcomitantHistoryScreen extends ConsumerWidget {
  final String childId;
  const ConcomitantHistoryScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistory = ref.watch(concomitantHistoryProvider(childId));

    return Scaffold(
      appBar: AppBar(title: const Text('Component 2 History')),
      body: asyncHistory.when(
        loading: () => const SwaraLoadingWidget(message: 'Loading history...'),
        error: (e, _) => SwaraErrorWidget(message: 'Failed to load history: $e'),
        data: (history) {
          if (history.isEmpty) {
            return const SwaraEmptyState(
              title: 'No Assessment History',
              subtitle: 'Start a new assessment to see history here.',
              icon: Icons.history,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text('${item.taskType} Assessment', style: AppTextStyles.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM dd, yyyy - HH:mm').format(item.createdAt), style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      Text('Events: ${item.eventTimeline.length} | Status: ${item.clinicianVerification['status'] ?? 'Pending'}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/concomitant/result/${item.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
