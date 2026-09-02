import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/theme/app_theme.dart';

class SpeechRecordScreen extends ConsumerStatefulWidget {
  final String childId;

  const SpeechRecordScreen({super.key, required this.childId});

  @override
  ConsumerState<SpeechRecordScreen> createState() => _SpeechRecordScreenState();
}

class _SpeechRecordScreenState extends ConsumerState<SpeechRecordScreen>
    with TickerProviderStateMixin {
  int _currentActivity = 0; // 0 = Reading Practice, 1 = Picture Description
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasRecorded = false;
  int _seconds = 0;
  Timer? _timer;

  // Idle pulse for the mic button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Tap "squish" feedback for the main CTA
  late AnimationController _tapController;
  late Animation<double> _tapAnim;

  // Celebration pop when a recording finishes
  late AnimationController _celebrateController;
  late Animation<double> _celebrateAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _tapAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );

    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebrateAnim = CurvedAnimation(
      parent: _celebrateController,
      curve: Curves.elasticOut,
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _hasRecorded = false;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _hasRecorded = true;
    });
    _celebrateController.forward(from: 0);
  }

  void _resetRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _hasRecorded = false;
      _seconds = 0;
    });
  }

  void _nextActivityOrFinish() {
    if (_currentActivity == 0) {
      setState(() {
        _currentActivity = 1;
        _hasRecorded = false;
        _seconds = 0;
      });
    } else {
      context.pushReplacement('/c1/result');
    }
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _tapController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      if (_currentActivity == 0) _buildReadingTask() else _buildPictureTask(),
                      const SizedBox(height: 28),

                      if (_isRecording) _buildRecordingIndicator(),
                      if (_hasRecorded) _buildCelebrationCard(),

                      const SizedBox(height: 24),
                      _buildEncouragementBanner(),
                      const SizedBox(height: 28),

                      _buildControls(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TOP BAR — big friendly back button, mascot bubble, dot-based progress
  // ---------------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              // Bigger, rounder back button — easier for small fingers to hit
              Material(
                color: Colors.white.withOpacity(0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.go('/'),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Mascot bubble — friendlier than a plain title
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                ),
                alignment: Alignment.center,
                child: const Text('🦉', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentActivity == 0 ? 'Reading Time!' : 'Picture Fun!',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _currentActivity == 0
                          ? 'Read the story out loud'
                          : 'Tell us what you see',
                      style: const TextStyle(
                        color: Color(0xFF0066CC),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepDots(),
        ],
      ),
    );
  }

  /// Two big star dots instead of "Step 1/2" text — readable at a glance,
  /// no literacy required to understand progress.
  Widget _buildStepDots() {
    Widget dot(bool filled, bool active) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: active ? 34 : 28,
        height: active ? 34 : 28,
        decoration: BoxDecoration(
          color: filled ? AppColors.ctaOrange : Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: active
              ? [BoxShadow(color: AppColors.ctaOrange.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          color: filled ? Colors.white : Colors.white,
          size: active ? 22 : 18,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(_currentActivity >= 0, _currentActivity == 0),
        Container(width: 24, height: 4, color: Colors.white.withOpacity(0.5)),
        dot(_currentActivity >= 1, _currentActivity == 1),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // READING TASK CARD
  // ---------------------------------------------------------------------
  Widget _buildReadingTask() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖 ', style: TextStyle(fontSize: 26)),
              const Text('Reading Practice', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.text)),
              const Spacer(),
              // Visual "listen to example" affordance — wire up to audio playback
              Material(
                color: AppColors.softYellow.withOpacity(0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {}, // TODO: hook up example audio playback
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.volume_up_rounded, color: AppColors.text, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'අද උදෑසන නදී සහ ඇගේ මිතුරන් පාසල් වත්තට ගියා. ඔවුන් එහි තිබූ ලස්සන මල් පැල නිරීක්ෂණය කළා. පසුව ඔවුන් ගුරුවරිය සමඟ එකතු වී වත්ත පිරිසිදු කළා.',
            style: TextStyle(fontSize: 22, height: 1.75, color: AppColors.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PICTURE DESCRIPTION TASK CARD
  // ---------------------------------------------------------------------
  Widget _buildPictureTask() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🖼️ ', style: TextStyle(fontSize: 26)),
              Text('Picture Description', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softYellow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.softYellow, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Image.asset(
                'assets/images/park_family.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Look at the picture and tell us what you see!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'පින්තූරය බලලා ඔයා දකින දේ ගැන අපිට කියන්න.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RECORDING INDICATOR — bigger mic, clearer timer pill
  // ---------------------------------------------------------------------
  Widget _buildRecordingIndicator() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: _isPaused ? 1.0 : _pulseAnim.value,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _isPaused ? AppColors.softYellow : AppColors.coralRed,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isPaused ? AppColors.softYellow : AppColors.coralRed).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(_isPaused ? Icons.pause_rounded : Icons.mic_rounded, color: Colors.white, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(24)),
          child: Text(
            _formatTime(_seconds),
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // CELEBRATION CARD — replaces the plain checkmark with a warmer moment
  // ---------------------------------------------------------------------
  Widget _buildCelebrationCard() {
    return ScaleTransition(
      scale: _celebrateAnim,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.mintGreen,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.mintGreen.withOpacity(0.5), blurRadius: 14)],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Text('✨', style: TextStyle(fontSize: 34)),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(Icons.check_rounded, color: Colors.white, size: 30),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('You did amazing! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  Text('Great job — ${_formatTime(_seconds)} of talking!', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ENCOURAGEMENT BANNER — fixed contrast (was blue text on translucent
  // white over a gradient, hard to read; now solid white text on a pill)
  // ---------------------------------------------------------------------
  Widget _buildEncouragementBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0066CC).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF0066CC).withOpacity(0.3), blurRadius: 10)],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🌟 ', style: TextStyle(fontSize: 20)),
          Flexible(
            child: Text(
              'Take your time! / ඔයාට පුළුවන්!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CONTROLS — bigger tap targets + a subtle "squish" on press
  // ---------------------------------------------------------------------
  Widget _buildControls() {
    if (!_isRecording && !_hasRecorded) {
      return _bouncyButton(
        onTap: _startRecording,
        color: AppColors.ctaOrange,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_rounded, color: Colors.white, size: 30),
            SizedBox(width: 10),
            Text('Start Recording', style: TextStyle(fontSize: 21, color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    } else if (_isRecording) {
      return Row(
        children: [
          Expanded(
            child: _bouncyButton(
              onTap: _pauseRecording,
              color: AppColors.softYellow,
              padded: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 6),
                  Text(_isPaused ? 'Resume' : 'Pause', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _bouncyButton(
              onTap: _stopRecording,
              color: AppColors.coralRed,
              padded: 18,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 6),
                  Text('Finish', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetRecording,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue, width: 2.5),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.blue, size: 22),
                  SizedBox(width: 6),
                  Text('Try Again', style: TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _bouncyButton(
              onTap: _nextActivityOrFinish,
              color: AppColors.ctaOrange,
              padded: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentActivity == 0 ? 'Next Activity' : 'See Results',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  /// A full-width (or flexible, inside a Row) button with a quick "squish"
  /// animation on press — gives kids a tactile sense their tap registered.
  Widget _bouncyButton({
    required VoidCallback onTap,
    required Color color,
    required Widget child,
    double padded = 20,
  }) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _tapAnim,
        builder: (_, __) => Transform.scale(
          scale: _tapAnim.value,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: padded),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}