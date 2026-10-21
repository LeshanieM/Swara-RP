import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../network/parent_mode.dart';
import '../storage/storage_service.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';
import 'package:swara/features/auth/data/providers/auth_provider.dart';

/// Makes sure parent mode is on before a parent-only action (video upload, questionnaire).
/// Returns true straight away in demo mode, for therapists, or while parent mode is still active.
Future<bool> ensureParentMode(BuildContext context, WidgetRef ref) async {
  if (StorageService.isDemoMode() || ParentMode.isActive) return true;
  if (ref.read(currentUserProvider)?.role == AppConstants.roleTherapist) return true;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ParentPinDialog(),
  );
  return ok ?? false;
}

class _ParentPinDialog extends ConsumerStatefulWidget {
  const _ParentPinDialog();

  @override
  ConsumerState<_ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends ConsumerState<_ParentPinDialog> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pin.text.length < 4) {
      setState(() => _error = 'Enter the 4–6 digit parent PIN.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(authProvider.notifier).enterParentMode(_pin.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.family_restroom, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('Parent mode', style: AppTextStyles.heading3),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A parent needs to enter the PIN to continue.', style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Parent PIN',
              prefixIcon: const Icon(Icons.lock_outlined),
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 120,
          child: SwaraButton(label: 'Continue', onPressed: _submit, isLoading: _busy),
        ),
      ],
    );
  }
}
