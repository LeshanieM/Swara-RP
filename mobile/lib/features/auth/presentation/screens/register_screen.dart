import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/constants/app_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  const RegisterScreen({super.key, this.redirectTo});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _childNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _codeController = TextEditingController();
  // A parent sets up the child's account (one login per child) and the parent-mode PIN.
  String _role = AppConstants.roleChild;
  int? _childAge;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _childNameController.dispose();
    _pinController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
          childFirstName: _childNameController.text.trim(),
          childAge: _childAge,
          parentPin: _pinController.text,
          signupCode: _codeController.text.trim(),
        );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (success && mounted) {
      context.go(widget.redirectTo ?? '/');
    }
  }

  /// The child this account is for, and the PIN that guards parent-only actions.
  List<Widget> _childFields() => [
        Text('Your child', style: AppTextStyles.label),
        const SizedBox(height: 10),
        TextFormField(
          controller: _childNameController,
          decoration: const InputDecoration(
            labelText: "Child's first name",
            prefixIcon: Icon(Icons.child_care_outlined),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? "Please enter your child's name" : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _childAge,
          decoration: const InputDecoration(
            labelText: "Child's age",
            prefixIcon: Icon(Icons.cake_outlined),
          ),
          items: [for (var a = 5; a <= 14; a++) DropdownMenuItem(value: a, child: Text('$a years'))],
          onChanged: (v) => setState(() => _childAge = v),
          validator: (v) => v == null ? 'Swara is for ages 5–14' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Parent PIN',
            helperText: 'Asked before video uploads and parent questions',
            prefixIcon: Icon(Icons.lock_outlined),
          ),
          validator: (v) => (v ?? '').length < 4 ? 'Use 4–6 digits' : null,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join Swara', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text('Create a parent or therapist account', style: AppTextStyles.bodySmall),
              const SizedBox(height: 28),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  final email = v?.trim() ?? '';
                  if (email.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter a password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('I am a:', style: AppTextStyles.label),
              const SizedBox(height: 10),
              Row(
                children: [
                  _RoleCard(
                    title: 'Parent/Caregiver',
                    icon: Icons.family_restroom,
                    value: AppConstants.roleChild,
                    selected: _role == AppConstants.roleChild,
                    onTap: () => setState(() => _role = AppConstants.roleChild),
                  ),
                  const SizedBox(width: 12),
                  _RoleCard(
                    title: 'Speech Therapist',
                    icon: Icons.record_voice_over,
                    value: AppConstants.roleTherapist,
                    selected: _role == AppConstants.roleTherapist,
                    onTap: () => setState(() => _role = AppConstants.roleTherapist),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_role == AppConstants.roleChild) ..._childFields(),
              if (_role == AppConstants.roleTherapist)
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Therapist code',
                    helperText: 'Given to the research team\'s therapists',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter the therapist code' : null,
                ),
              const SizedBox(height: 28),
              SwaraButton(
                label: 'Create Account',
                onPressed: _register,
                isLoading: authState.isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTextStyles.bodySmall),
                  GestureDetector(
                    onTap: () => context.go(widget.redirectTo == null
                        ? '/login'
                        : '/login?redirectTo=${Uri.encodeComponent(widget.redirectTo!)}'),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryWash : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textLight,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
