import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
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

class SplashScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  const SplashScreen({super.key, this.redirectTo});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _didNavigate = false;

  void _navigate(AuthState authState) {
    if (_didNavigate || !authState.isInitialized) return;
    _didNavigate = true;
    final redirectTo = widget.redirectTo;
    if (redirectTo != null &&
        (!redirectTo.startsWith('/') || redirectTo.startsWith('//'))) {
      context.go('/');
      return;
    }
    if (authState.isAuthenticated) {
      if (redirectTo != null) {
        context.go(redirectTo);
      } else {
        _goHome(authState.role);
      }
    } else if (redirectTo != null) {
      context.go('/register?redirectTo=${Uri.encodeComponent(redirectTo)}');
    } else {
      context.go('/register');
    }
  }

  void _goHome(String role) {
    switch (role) {
      case AppConstants.roleParent:
        context.go('/parent/home');
        break;
      case AppConstants.roleTherapist:
        context.go('/therapist/home');
        break;
      case AppConstants.roleChild:
        context.go('/child/home');
        break;
      default:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.isInitialized && !_didNavigate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigate(authState);
      });
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // --- Responsive signals ---------------------------------------------------
    final media = MediaQuery.of(context);
    final size = media.size;
    final isLandscape = size.width > size.height;
    final isNarrow = size.width < 360;
    final isShort = size.height < 640;
    final textScale = media.textScaler.scale(1).clamp(1.0, 1.3);

    final double widthScale = (size.width / 390).clamp(0.85, 1.15);
    final double scale = (widthScale * textScale).clamp(0.85, 1.25);

    final double hPad = isNarrow ? 16 : 24;
    final double cardPad = isNarrow ? 20 : 24;
    final double maxCardWidth = isLandscape ? 520 : 460;
    final double cardWidth = (size.width - hPad * 2).clamp(0.0, maxCardWidth);

    final headingSize = (32 * scale).clamp(24.0, 34.0);
    final badgeSize = (88 * scale).clamp(72.0, 96.0);

    return Scaffold(
      backgroundColor: _groundAdult,
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

                return Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - topPad - bottomPad,
                        maxWidth: cardWidth,
                      ),
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
                                padding: EdgeInsets.fromLTRB(
                                    cardPad, cardPad + 40, cardPad, cardPad),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(color: _primaryTint, width: 2),
                                ),
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
                                            'Swara',
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
                                          const SizedBox(height: 12),
                                          Text(
                                            'Sinhala speech support',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontFamily: _nunito,
                                                fontSize: 16 * scale,
                                                height: 1.4,
                                                fontWeight: FontWeight.w700,
                                                color: _inkMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: cardPad),
                                    _Reveal(
                                      order: 1,
                                      reduceMotion: reduceMotion,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(_primary),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Getting things ready…',
                                            style: TextStyle(
                                                fontFamily: _nunito,
                                                fontSize: 15 * scale,
                                                fontWeight: FontWeight.w700,
                                                color: _inkMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Badge overlapping the card's top edge
                            ExcludeSemantics(
                              child: Container(
                                width: badgeSize,
                                height: badgeSize,
                                decoration: BoxDecoration(
                                  color: _primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _groundAdult, width: 6),
                                ),
                                child: Center(
                                  child: Text(
                                    'ස',
                                    style: TextStyle(
                                      fontFamily: _fredoka,
                                      fontSize: badgeSize * 0.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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