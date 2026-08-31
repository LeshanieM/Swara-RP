import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    _isDemoMode = StorageService.isDemoMode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _fillDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  Future<void> _toggleDemo() async {
    await StorageService.setDemoMode(!_isDemoMode);
    setState(() => _isDemoMode = !_isDemoMode);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: 240,
              width: double.infinity,
              color: AppColors.primaryDeep,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 36),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Center(
                      child: Text(
                        'ස',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.onPrimary,
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Swara',
                    style: AppTextStyles.heading2.copyWith(color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sinhala speech support',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Sign In', style: AppTextStyles.heading2),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your credentials to continue',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 24),

                    // Demo mode toggle
                    GestureDetector(
                      onTap: _toggleDemo,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isDemoMode
                              ? AppColors.warning.withOpacity(0.1)
                              : AppColors.primaryWash,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDemoMode
                                ? AppColors.warning.withOpacity(0.3)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isDemoMode ? Icons.science : Icons.science_outlined,
                              color: _isDemoMode ? AppColors.warning : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isDemoMode
                                    ? 'Demo Mode ON — tap to disable'
                                    : 'Enable Demo Mode (no backend needed)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _isDemoMode ? AppColors.warning : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isDemoMode,
                              onChanged: (_) => _toggleDemo(),
                              activeColor: AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isDemoMode) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _fillDemo('parent@demo.com', 'demo123'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Parent Demo', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _fillDemo('therapist@demo.com', 'demo123'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(color: AppColors.secondary),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text('Therapist Demo', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Please enter your email' : null,
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
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 28),
                    SwaraButton(
                      label: 'Sign In',
                      onPressed: _login,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: AppTextStyles.bodySmall),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppConstants.researchDisclaimer,
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
