import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/components/component4/services/c4_flow.dart';
import 'package:swara/components/component4/services/c4_service.dart';
import 'package:swara/components/component4/widgets/c4_header.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/widgets/parent_pin_dialog.dart';

/// The parent checklist at onboarding: a few yes / no questions about what the child already does
/// (stories, "because", telling events in order). The yes count sets the starting topic level, so the
/// child never rates themselves. Answered once per age band, in parent mode.
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  List<Map<String, dynamic>> _items = const [];
  final Map<String, bool> _answers = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await C4Service.checklist(C4Flow.child!.age);
      if (!mounted) return;
      setState(() {
        _items = [for (final i in (res['items'] as List? ?? const [])) Map<String, dynamic>.from(i as Map)];
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e).message;
          _loading = false;
        });
      }
    }
  }

  void _continue() => context.pushReplacement('/c4/topic');

  Future<void> _submit() async {
    if (!await ensureParentMode(context, ref)) return;
    setState(() => _saving = true);
    try {
      await C4Service.submitChecklist(C4Flow.child!.childId, _answers);
      C4Flow.checklistDone = true;
      if (mounted) _continue();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e).message;
          _saving = false;
        });
      }
    }
  }

  Widget _item(Map<String, dynamic> item) {
    final id = item['id'] as String;
    final answer = _answers[id];
    Widget choice(bool value, String label) => Expanded(
          child: ChoiceChip(
            label: SizedBox(width: double.infinity, child: Text(label, textAlign: TextAlign.center)),
            selected: answer == value,
            onSelected: (_) => setState(() => _answers[id] = value),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: AppRadii.mdAll, boxShadow: AppElevation.card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item['text']?['si'] ?? '', style: AppTextStyles.titleMedium.copyWith(color: AppColors.text)),
        const SizedBox(height: 4),
        Text(item['text']?['en'] ?? '', style: AppTextStyles.caption),
        const SizedBox(height: 12),
        Row(children: [choice(true, 'ඔව් · Yes'), const SizedBox(width: 12), choice(false, 'නැහැ · Not yet')]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complete = _items.isNotEmpty && _items.every((i) => _answers.containsKey(i['id']));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          const C4Header(currentStep: 4, totalSteps: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(24), children: [
                    Text('දෙමාපිය ප්‍රශ්න', style: AppTextStyles.heading2.copyWith(color: AppColors.primaryDeep), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('For the parent: what does your child already do?',
                        style: AppTextStyles.body.copyWith(color: AppColors.textLight), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.error), textAlign: TextAlign.center),
                      ),
                    ..._items.map(_item),
                  ]),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                onPressed: complete && !_saving ? _submit : null,
                child: Text(_saving ? 'Saving...' : 'Save answers'),
              ),
              // The child can start today's topic while the parent answers later.
              TextButton(onPressed: _saving ? null : _continue, child: const Text('Answer later')),
            ]),
          ),
        ]),
      ),
    );
  }
}
