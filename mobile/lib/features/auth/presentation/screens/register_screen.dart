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
          content: Text('${ref.read(authProvider).error ?? 'Registration failed'} · ලියාපදිංචි වීමට නොහැකි විය'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (success && mounted) {
      context.go(widget.redirectTo ?? '/');
    }
  }

  /// The child this account is for, and the PIN that guards parent-only actions.
  List<Widget> _childFields() => [
        Text('Your child · ඔබේ දරුවා', style: AppTextStyles.label),
        const SizedBox(height: 10),
        TextFormField(
          controller: _childNameController,
          decoration: InputDecoration(
            labelText: "Child's first name · දරුවාගේ මුල් නම",
            prefixIcon: _prefixIcon(Icons.child_care_outlined),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? "Please enter your child's name · දරුවාගේ නම ඇතුළත් කරන්න" : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _childAge,
          decoration: InputDecoration(
            labelText: "Child's age · දරුවාගේ වයස",
            prefixIcon: _prefixIcon(Icons.cake_outlined),
          ),
          items: [for (var a = 5; a <= 14; a++) DropdownMenuItem(value: a, child: Text('$a years · අවුරුදු $a'))],
          onChanged: (v) => setState(() => _childAge = v),
          validator: (v) => v == null ? 'Swara is for ages 5–14 · Swara වයස 5–14 දරුවන් සඳහායි' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Parent PIN · දෙමාපිය PIN අංකය',
            helperText: 'වීඩියෝ සහ දෙමාපිය කොටස් සඳහා අවශ්‍යයි',
            prefixIcon: _prefixIcon(Icons.lock_outlined),
          ),
          validator: (v) => (v ?? '').length < 4 ? 'Use 4–6 digits · ඉලක්කම් 4–6ක් භාවිත කරන්න' : null,
        ),
      ];

  Widget _prefixIcon(IconData icon) => Padding(
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(color: AppColors.primaryWash, shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 360;
    final short = size.height < 640;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3).toDouble();

    return Scaffold(
      backgroundColor: AppColors.groundAdult,
      body: CalmSceneBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width > size.height ? 520 : 460),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 38),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(narrow ? 20 : 24, 64, narrow ? 20 : 24, 24),
                        decoration: BoxDecoration(color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.primaryWash, width: 2)),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CalmReveal(order: 0, child: Column(children: [
                                Text('Create account · ගිණුමක් සාදන්න', textAlign: TextAlign.center,
                                    style: AppTextStyles.heading2.copyWith(fontSize: (30 * scale).clamp(24, 34).toDouble())),
                                const SizedBox(height: 10),
                                Container(width: 48, height: 6, decoration: BoxDecoration(
                                    color: AppColors.sun, borderRadius: BorderRadius.circular(3))),
                                const SizedBox(height: 10),
                                  Text('දෙමාපියන් සහ කථන චිකිත්සකයන් සඳහා', textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall),
                              ])),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _nameController,
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 18 * scale,
                                    fontWeight: FontWeight.w700, color: AppColors.text),
                                decoration: InputDecoration(labelText: 'Full name · සම්පූර්ණ නම',
                                    prefixIcon: _prefixIcon(Icons.person_outline_rounded)),
                                validator: (v) => v == null || v.isEmpty ? 'Please enter your name · ඔබේ නම ඇතුළත් කරන්න' : null,
                              ),
                              SizedBox(height: short ? 12 : 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 18 * scale,
                                    fontWeight: FontWeight.w700, color: AppColors.text),
                                decoration: InputDecoration(labelText: 'Email · විද්‍යුත් තැපෑල',
                                    prefixIcon: _prefixIcon(Icons.email_outlined)),
                                validator: (v) {
                                  final email = v?.trim() ?? '';
                                  if (email.isEmpty) return 'Please enter your email · විද්‍යුත් තැපෑල ඇතුළත් කරන්න';
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) return 'Enter a valid email address · නිවැරදි විද්‍යුත් තැපෑලක් ඇතුළත් කරන්න';
                                  return null;
                                },
                              ),
                              SizedBox(height: short ? 12 : 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 18 * scale,
                                    fontWeight: FontWeight.w700, color: AppColors.text),
                                decoration: InputDecoration(labelText: 'Password · මුරපදය',
                                    prefixIcon: _prefixIcon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    )),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please enter a password · මුරපදයක් ඇතුළත් කරන්න';
                                  if (v.length < 6) return 'Password must be at least 6 characters · මුරපදය අවම වශයෙන් අක්ෂර 6ක් විය යුතුයි';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Text('I am a · මම', style: AppTextStyles.label),
                              const SizedBox(height: 10),
                              Row(children: [
                                _RoleCard(title: 'Parent/Caregiver · දෙමාපිය/භාරකරු', icon: Icons.family_restroom,
                                    value: AppConstants.roleChild, selected: _role == AppConstants.roleChild,
                                    onTap: () => setState(() => _role = AppConstants.roleChild)),
                                const SizedBox(width: 12),
                                _RoleCard(title: 'Speech Therapist · කථන චිකිත්සක', icon: Icons.record_voice_over,
                                    value: AppConstants.roleTherapist, selected: _role == AppConstants.roleTherapist,
                                    onTap: () => setState(() => _role = AppConstants.roleTherapist)),
                              ]),
                              const SizedBox(height: 20),
                              if (_role == AppConstants.roleChild) ..._childFields(),
                              if (_role == AppConstants.roleTherapist)
                                TextFormField(
                                  controller: _codeController,
                                  decoration: InputDecoration(labelText: 'Therapist code · චිකිත්සක කේතය',
                                      helperText: 'පර්යේෂණ කණ්ඩායමෙන් ලබාගන්න',
                                      prefixIcon: _prefixIcon(Icons.badge_outlined)),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter the therapist code · චිකිත්සක කේතය ඇතුළත් කරන්න' : null,
                                ),
                              const SizedBox(height: 24),
                              SizedBox(height: short ? 56 : 64, child: SwaraButton(
                                  label: 'Create account · ගිණුමක් සාදන්න', onPressed: _register,
                                  isLoading: authState.isLoading)),
                              const SizedBox(height: 12),
                              Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Already have an account? · ගිණුමක් තිබේද?', style: AppTextStyles.bodySmall),
                                  TextButton(
                                    style: TextButton.styleFrom(minimumSize: const Size(48, 52)),
                                    onPressed: () => context.go(widget.redirectTo == null ? '/login'
                                        : '/login?redirectTo=${Uri.encodeComponent(widget.redirectTo!)}'),
                                    child: const Text('Sign in · පුරනය වන්න'),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ExcludeSemantics(child: Container(width: 76, height: 76,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.groundAdult, width: 6)),
                      child: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 34))),
                  ],
                ),
              ),
            ),
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
                  borderRadius: BorderRadius.circular(22),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
