import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/constants/app_constants.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  String _severity = 'Mild';
  String _stutterType = 'Repetition';
  final List<String> _selectedInterests = [];
  bool _isLoading = false;

  static const _interests = ['Animals', 'Space', 'Ocean', 'Forest', 'Music', 'Art', 'Sports', 'Nature', 'Science', 'Cooking'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(childNotifierProvider.notifier).addChild({
      'firstName': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 7,
      'gender': _gender,
      'severity': _severity,
      'stutterType': _stutterType,
      'interests': _selectedInterests,
    });
    setState(() => _isLoading = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child profile created!'), backgroundColor: AppColors.success),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Child Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DisclaimerBanner(message: 'Child profiles use pseudonymous IDs for privacy.'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'First Name / Pseudonym', prefixIcon: Icon(Icons.child_care)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_outlined)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 3 || n > 18) return 'Enter age between 3 and 18';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text('Gender', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Row(
                children: ['Male', 'Female', 'Other']
                    .map((g) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: _gender == g,
                            onSelected: (_) => setState(() => _gender = g),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _gender == g ? Colors.white : AppColors.text,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Initial Severity (if known)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _severity,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.bar_chart)),
                items: AppConstants.severityLevels
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _severity = v!),
              ),
              const SizedBox(height: 14),
              Text('Stutter Type (if known)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _stutterType,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.mic_outlined)),
                items: AppConstants.stutterTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _stutterType = v!),
              ),
              const SizedBox(height: 16),
              Text('Interests (select all that apply)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _interests
                    .map((i) => FilterChip(
                          label: Text(i),
                          selected: _selectedInterests.contains(i),
                          onSelected: (v) => setState(() {
                            if (v) {
                              _selectedInterests.add(i);
                            } else {
                              _selectedInterests.remove(i);
                            }
                          }),
                          selectedColor: AppColors.primaryWash,
                          checkmarkColor: AppColors.primary,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              SwaraButton(label: 'Create Profile', onPressed: _submit, isLoading: _isLoading),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
