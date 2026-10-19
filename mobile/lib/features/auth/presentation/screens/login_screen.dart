import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import 'package:swara/core/widgets/shared_widgets.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/core/constants/app_constants.dart';

// Calm Cub tokens, primary swapped to dark blue
const _groundAdult = Color(0xFFF2F6F5);
const _groundSky = Color(0xFFDCEEFA);
const _groundGarden = Color(0xFFE4F3DC);
const _primary = Color(0xFF1D4A87); // dark blue
const _primaryTint = Color(0xFFD9E6F7);
const _sun = Color(0xFFFFC94A);
const _sunTint = Color(0xFFFFF3CF);
const _lilacTint = Color(0xFFDCD3F8);
const _ink = Color(0xFF1E3A44);
const _inkMuted = Color(0xFF3F5F6A);

const _fredoka = 'Fredoka';
const _nunito = 'Nunito';

/// Flat, gradient-free scene: soft circles, a small sun, three rolling hills.
class _CalmScenePainter extends CustomPainter {
  const _CalmScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Paint p(Color c) => Paint()..color = c;

    canvas.drawRect(Offset.zero & size, p(_groundAdult));

    // Sky circles
    canvas.drawCircle(Offset(w * 0.92, h * 0.07), w * 0.55, p(_groundSky));
    canvas.drawCircle(Offset(w * 0.92, h * 0.07), w * 0.36, p(_primaryTint.withOpacity(0.85)));
    canvas.drawCircle(Offset(w * 0.92, h * 0.07), w * 0.18, p(Colors.white.withOpacity(0.55)));
    canvas.drawCircle(Offset(w * 0.04, h * 0.26), w * 0.22, p(_sunTint));
    canvas.drawCircle(Offset(w * 0.98, h * 0.50), w * 0.15, p(_lilacTint.withOpacity(0.7)));

    // Small sun + tiny accents
    canvas.drawCircle(Offset(w * 0.15, h * 0.12), w * 0.045, p(_sun));
    canvas.drawCircle(Offset(w * 0.26, h * 0.17), w * 0.012, p(Colors.white));
    canvas.drawCircle(Offset(w * 0.74, h * 0.20), w * 0.016, p(Colors.white));
    canvas.drawCircle(Offset(w * 0.06, h * 0.60), w * 0.02, p(_primaryTint));

    // Far hill (lilac)
    final far = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.22, h * 0.70, w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.80, h * 0.86, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, p(_lilacTint.withOpacity(0.55)));

    // Middle hill (blue tint)
    final mid = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.28, h * 0.76, w * 0.58, h * 0.84)
      ..quadraticBezierTo(w * 0.82, h * 0.90, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mid, p(_primaryTint));

    // Front hill (meadow)
    final front = Path()
      ..moveTo(0, h * 0.93)
      ..quadraticBezierTo(w * 0.30, h * 0.87, w * 0.62, h * 0.93)
      ..quadraticBezierTo(w * 0.85, h * 0.97, w, h * 0.92)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, p(_groundGarden));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slow fade + rise. Later items take slightly longer, so they settle in order.
class _Reveal extends StatelessWidget {
  final int order;
  final bool reduceMotion;
  final Widget child;
  const _Reveal({required this.order, required this.reduceMotion, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion ? Duration.zero : Duration(milliseconds: 500 + order * 140),
      curve: Curves.easeInOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await StorageService.setDemoMode(false);
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      context.go(widget.redirectTo ?? '/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).error ??
                "We couldn't sign you in. Please check your details and try again.",
            style: const TextStyle(fontFamily: _nunito, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      );
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffix,
    required double scale,
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          fontFamily: _nunito, fontWeight: FontWeight.w700, fontSize: 16 * scale, color: _inkMuted),
      floatingLabelStyle: TextStyle(
          fontFamily: _nunito, fontWeight: FontWeight.w700, fontSize: 16 * scale, color: _primary),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 4),
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(color: _primaryTint, shape: BoxShape.circle),
          child: Icon(icon, color: _primary, size: 20 * scale),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 48),
      suffixIcon: suffix,
      filled: true,
      fillColor: _groundAdult,
      contentPadding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 16 * scale),
      border: border(Colors.transparent, 0),
      enabledBorder: border(_primaryTint, 1.5),
      focusedBorder: border(_primary, 3),
      errorBorder: border(_ink, 2),
      focusedErrorBorder: border(_primary, 3),
      errorMaxLines: 3,
      errorStyle: const TextStyle(
          fontFamily: _nunito, fontWeight: FontWeight.w700, fontSize: 16, height: 1.3, color: _ink),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // --- Responsive signals ---------------------------------------------------
    final media = MediaQuery.of(context);
    final size = media.size;
    final keyboard = media.viewInsets.bottom;
    final isLandscape = size.width > size.height;
    final isNarrow = size.width < 360;
    final isShort = size.height < 640;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.3);

    final double widthScale = (size.width / 390).clamp(0.85, 1.15);
    final double scale = (widthScale * textScale).clamp(0.85, 1.25);

    final double hPad = isNarrow ? 16 : 24;
    final double vGap = isShort ? 12 : 16;
    final double cardPad = isNarrow ? 20 : 24;
    final double maxCardWidth = isLandscape ? 520 : 460;
    final double cardWidth = (size.width - hPad * 2).clamp(0.0, maxCardWidth);

    const bodyStyle =
        TextStyle(fontFamily: _nunito, fontWeight: FontWeight.w700, fontSize: 16, color: _inkMuted);
    final inputStyle =
        TextStyle(fontFamily: _nunito, fontWeight: FontWeight.w700, fontSize: 18 * scale, color: _ink);
    final headingSize = (32 * scale).clamp(24.0, 34.0);

    return Scaffold(
      backgroundColor: _groundAdult,
      // The scene stays fixed behind the keyboard; the scroll view is padded instead.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(child: CustomPaint(painter: _CalmScenePainter())),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topPad = isShort ? 12.0 : 24.0;
                final bottomPad = isShort ? 16.0 : 28.0;
                final minHeight =
                    (constraints.maxHeight - topPad - bottomPad - keyboard).clamp(0.0, double.infinity);

                return Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad + keyboard),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight, maxWidth: cardWidth),
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            // Card
                            Padding(
                              padding: const EdgeInsets.only(top: 38),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(cardPad, cardPad + 40, cardPad, cardPad),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: _primaryTint, width: 2),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: AutofillGroup(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _Reveal(
                                          order: 0,
                                          reduceMotion: reduceMotion,
                                          child: Column(
                                            children: [
                                              Text(
                                                'Welcome to Swara',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontFamily: _fredoka,
                                                    fontSize: headingSize,
                                                    height: 1.2,
                                                    fontWeight: FontWeight.w600,
                                                    color: _ink),
                                              ),
                                              const SizedBox(height: 10),
                                              // Sun accent under the heading
                                              ExcludeSemantics(
                                                child: Container(
                                                  width: 48,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: _sun,
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: cardPad),
                                        _Reveal(
                                          order: 1,
                                          reduceMotion: reduceMotion,
                                          child: TextFormField(
                                            controller: _emailController,
                                            style: inputStyle,
                                            keyboardType: TextInputType.emailAddress,
                                            textInputAction: TextInputAction.next,
                                            autofillHints: const [AutofillHints.email],
                                            decoration: _decoration(
                                                label: 'Email · විද්‍යුත් තැපෑල',
                                                icon: Icons.email_outlined,
                                                scale: scale),
                                            validator: (value) {
                                              final email = value?.trim() ?? '';
                                              if (email.isEmpty) {
                                                return 'Please enter your email · විද්‍යුත් තැපෑල ඇතුළත් කරන්න';
                                              }
                                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                                                return 'Enter a valid email · නිවැරදි විද්‍යුත් තැපෑලක් ඇතුළත් කරන්න';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(height: vGap),
                                        _Reveal(
                                          order: 2,
                                          reduceMotion: reduceMotion,
                                          child: TextFormField(
                                            controller: _passwordController,
                                            style: inputStyle,
                                            obscureText: _obscurePassword,
                                            textInputAction: TextInputAction.done,
                                            autofillHints: const [AutofillHints.password],
                                            onFieldSubmitted: (_) =>
                                                authState.isLoading ? null : _login(),
                                            decoration: _decoration(
                                              label: 'Password · මුරපදය',
                                              icon: Icons.lock_outline_rounded,
                                              scale: scale,
                                              suffix: IconButton(
                                                tooltip:
                                                    _obscurePassword ? 'Show password' : 'Hide password',
                                                constraints:
                                                    const BoxConstraints(minWidth: 48, minHeight: 48),
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons.visibility_outlined
                                                      : Icons.visibility_off_outlined,
                                                  color: _ink,
                                                ),
                                                onPressed: () =>
                                                    setState(() => _obscurePassword = !_obscurePassword),
                                              ),
                                            ),
                                            validator: (value) => value == null || value.isEmpty
                                                ? 'Please enter your password · මුරපදය ඇතුළත් කරන්න'
                                                : null,
                                          ),
                                        ),
                                        SizedBox(height: cardPad),
                                        _Reveal(
                                          order: 3,
                                          reduceMotion: reduceMotion,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              SizedBox(
                                                height: isShort ? 56 : 64,
                                                child: SwaraButton(
                                                  label: 'Sign in · පුරනය වන්න',
                                                  color: _primary,
                                                  onPressed: authState.isLoading ? null : _login,
                                                  isLoading: authState.isLoading,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  const Text('New to Swara? · අලුතින්ද?',
                                                      style: bodyStyle),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                        minimumSize: const Size(48, 52)),
                                                    onPressed: () => context.go(widget.redirectTo == null
                                                        ? '/register'
                                                        : '/register?redirectTo=${Uri.encodeComponent(widget.redirectTo!)}'),
                                                    child: const Text('Create account · ගිණුමක් සාදන්න',
                                                        style: TextStyle(
                                                            fontFamily: _nunito,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w800,
                                                            color: _primary)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Badge overlapping the card's top edge
                            ExcludeSemantics(
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: _primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _groundAdult, width: 6),
                                ),
                                child: const Icon(Icons.waving_hand_outlined,
                                    color: Colors.white, size: 34),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}