import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

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
          content: Text('${ref.read(authProvider).error ?? 'Sign in did not work'} · පුරනය වීමට නොහැකි විය'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (success && mounted) {
      context.go(widget.redirectTo ?? '/');
    }
  }

  void _fillDemo(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  Future<void> _toggleDemo() async {
    await StorageService.setDemoMode(!_isDemoMode);
    if (mounted) setState(() => _isDemoMode = !_isDemoMode);
  }

  Widget _prefixIcon(IconData icon) => Padding(
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.primaryWash,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final media = MediaQuery.of(context);
    final narrow = media.size.width < 360;
    final short = media.size.height < 640;
    final landscape = media.size.width > media.size.height;
    final scale = media.textScaler.scale(1).clamp(1.0, 1.3).toDouble();

    return Scaffold(
      backgroundColor: AppColors.groundAdult,
      body: CalmSceneBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: narrow ? 16 : 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: landscape ? 520 : 460),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 38),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(narrow ? 20 : 24, 64, narrow ? 20 : 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.primaryWash, width: 2),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CalmReveal(
                                order: 0,
                                child: Column(children: [
                                  Text('Welcome to Swara', textAlign: TextAlign.center,
                                      style: AppTextStyles.heading2.copyWith(
                                        fontSize: (32 * scale).clamp(24, 34).toDouble(),
                                        height: 1.2,
                                      )),
                                  const SizedBox(height: 10),
                                  Container(width: 48, height: 6,
                                      decoration: BoxDecoration(color: AppColors.sun,
                                          borderRadius: BorderRadius.circular(3))),
                                  const SizedBox(height: 10),
                                  Text('Sinhala speech support · සිංහල කථන සහාය', textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySmall),
                                ]),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: _toggleDemo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryWash,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Row(children: [
                                    Icon(_isDemoMode ? Icons.science : Icons.science_outlined,
                                        color: AppColors.primary, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(
                                      _isDemoMode ? 'Demo mode is on · ආදර්ශ මාදිලිය ක්‍රියාත්මකයි' : 'Use demo mode · ආදර්ශ මාදිලිය භාවිත කරන්න',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.text),
                                    )),
                                    Switch(value: _isDemoMode, onChanged: (_) => _toggleDemo()),
                                  ]),
                                ),
                              ),
                              if (_isDemoMode) ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: OutlinedButton(
                                    onPressed: () => _fillDemo('parent@demo.com', 'demo123'),
                                    child: const Text('Parent demo · දෙමාපිය'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: OutlinedButton(
                                    onPressed: () => _fillDemo('therapist@demo.com', 'demo123'),
                                    child: const Text('Therapist demo · චිකිත්සක'))),
                                ]),
                              ],
                              const SizedBox(height: 20),
                              CalmReveal(order: 1, child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 18 * scale,
                                    fontWeight: FontWeight.w700, color: AppColors.text),
                                decoration: InputDecoration(
                                  labelText: 'Email · විද්‍යුත් තැපෑල',
                                  prefixIcon: _prefixIcon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  final email = v?.trim() ?? '';
                                  if (email.isEmpty) return 'Please enter your email · විද්‍යුත් තැපෑල ඇතුළත් කරන්න';
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                                    return 'Enter a valid email address · නිවැරදි විද්‍යුත් තැපෑලක් ඇතුළත් කරන්න';
                                  }
                                  return null;
                                },
                              )),
                              SizedBox(height: short ? 12 : 16),
                              CalmReveal(order: 2, child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(fontFamily: 'Nunito', fontSize: 18 * scale,
                                    fontWeight: FontWeight.w700, color: AppColors.text),
                                decoration: InputDecoration(
                                  labelText: 'Password · මුරපදය',
                                  prefixIcon: _prefixIcon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'Please enter your password · මුරපදය ඇතුළත් කරන්න' : null,
                              )),
                              SizedBox(height: short ? 20 : 24),
                              CalmReveal(order: 3, child: Column(children: [
                                SizedBox(height: short ? 56 : 64, width: double.infinity,
                                  child: SwaraButton(label: 'Sign in · පුරනය වන්න', onPressed: _login,
                                      isLoading: authState.isLoading)),
                                const SizedBox(height: 12),
                                Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('New to Swara? · Swara වෙත අලුතින්ද?', style: AppTextStyles.bodySmall),
                                    TextButton(
                                      style: TextButton.styleFrom(minimumSize: const Size(48, 52)),
                                      onPressed: () => context.go(widget.redirectTo == null
                                          ? '/register'
                                          : '/register?redirectTo=${Uri.encodeComponent(widget.redirectTo!)}'),
                                      child: const Text('Create account · ගිණුමක් සාදන්න'),
                                    ),
                                  ],
                                ),
                              ])),
                              const SizedBox(height: 12),
                              Text(
                                  'පර්යේෂණ සඳහා පමණි. මෙය කථන-භාෂා චිකිත්සක සේවාව වෙනුවට නොවේ.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ExcludeSemantics(child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.groundAdult, width: 6)),
                      child: const Icon(Icons.waving_hand_outlined, color: Colors.white, size: 34),
                    )),
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
