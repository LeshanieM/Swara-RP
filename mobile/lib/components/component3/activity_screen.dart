import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'models/activity_model.dart';
import 'dart:async';

class ActivityScreen extends StatefulWidget {
  final int activityIndex;
  final List<ActivityModel> activities;
  final String themeId;
  final Map<String, int> results;

  const ActivityScreen({
    super.key,
    required this.activityIndex,
    required this.activities,
    required this.themeId,
    required this.results,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _step = 0; // 0: Start, 1: Listen, 2: Countdown, 3: Record, 4: Review, 5: Caregiver
  int _countdown = 3;
  Timer? _timer;
  int _recordSeconds = 3;

  late ActivityModel _activity;

  @override
  void initState() {
    super.initState();
    _activity = widget.activities[widget.activityIndex];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startListen() {
    setState(() => _step = 1);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startCountdown();
    });
  }

  void _startCountdown() {
    setState(() {
      _step = 2;
      _countdown = 3;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _startRecord();
      }
    });
  }

  void _startRecord() {
    setState(() {
      _step = 3;
      _recordSeconds = 5;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordSeconds > 0) {
        setState(() => _recordSeconds--);
      } else {
        timer.cancel();
        setState(() => _step = 4);
      }
    });
  }

  void _stopRecord() {
    _timer?.cancel();
    setState(() => _step = 4);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'නියමයි! 🌟\nGreat Job!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Activity Complete ✓',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _step = 5); // Go to caregiver step
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue →', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _nextActivity() {
    final newResults = Map<String, int>.from(widget.results);
    newResults[_activity.id] = 80 + (widget.activityIndex * 2); // Mock score

    if (widget.activityIndex < widget.activities.length - 1) {
      context.pushReplacement('/c3/activity/${widget.activityIndex + 1}', extra: {
        'activities': widget.activities,
        'themeId': widget.themeId,
        'results': newResults,
      });
    } else {
      context.pushReplacement('/c3/final', extra: {
        'results': newResults,
        'activities': widget.activities,
        'themeId': widget.themeId,
      });
    }
  }

  Color _getThemeColor() {
    switch (widget.themeId) {
      case 'jungle': return const Color(0xFFE8F5E9);
      case 'ocean': return const Color(0xFFE3F2FD);
      case 'space': return const Color(0xFFEDE7F6);
      case 'magic': return const Color(0xFFFCE4EC);
      default: return AppColors.background;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 5) {
      return _buildCaregiverStep();
    }

    return Scaffold(
      backgroundColor: _getThemeColor(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Activity ${widget.activityIndex + 1} of 4'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (widget.activityIndex + 1) / 4,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 24),
              
              Text(
                _activity.nameSi,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _activity.nameEn,
                style: const TextStyle(fontSize: 18, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.divider)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        _activity.instructionSi,
                        style: const TextStyle(fontSize: 18, color: AppColors.text, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _activity.instructionEn,
                        style: const TextStyle(fontSize: 16, color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              _buildStepContent(),
              
              const Spacer(),
              
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverStep() {
    return Scaffold(
      backgroundColor: _getThemeColor(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.forum_rounded, size: 80, color: AppColors.primaryDeep),
              const SizedBox(height: 24),
              const Text(
                'අද පුරුදු කළ දෙයක් කියන්න 💬',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Share With Your Grown-Up',
                style: TextStyle(fontSize: 18, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'අද ඔයා පුරුදු කළ එක් දෙයක් ලොකු කෙනෙකුට කියන්න!\n\nTell a grown-up one thing you practiced today!',
                    style: TextStyle(fontSize: 18, color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _nextActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    // Custom activities injection
    if (_activity.id == 'breathing' && _step == 0) {
      return _BreathingCustomWidget(onComplete: () => setState(() => _step = 4));
    }
    if (_activity.id == 'relaxation' && _step == 0) {
      return _RelaxationCustomWidget();
    }
    if (_activity.id == 'picture_speaking' && _step == 0) {
      return Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('🎨 🏫 ⚽', style: TextStyle(fontSize: 54))),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.mic_rounded, size: 60, color: AppColors.primaryDeep),
        ],
      );
    }

    // Generic states
    switch (_step) {
      case 0:
        return const Icon(Icons.mic_rounded, size: 80, color: AppColors.primaryDeep);
      case 1:
        return Column(
          children: const [
            Icon(Icons.volume_up_rounded, size: 80, color: AppColors.primaryDeep),
            SizedBox(height: 16),
            Text('Listening...', style: TextStyle(fontSize: 20, color: AppColors.primaryDeep, fontWeight: FontWeight.bold)),
          ],
        );
      case 2:
        return Column(
          children: [
            const Text('Ready?', style: TextStyle(fontSize: 24, color: AppColors.textLight, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('$_countdown', style: const TextStyle(fontSize: 80, color: AppColors.primaryDeep, fontWeight: FontWeight.bold)),
          ],
        );
      case 3:
        return Column(
          children: [
            const Icon(Icons.fiber_manual_record, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Recording...', style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('00:0$_recordSeconds', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        );
      case 4:
        return Column(
          children: const [
            Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('Recorded!', style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildActionButtons() {
    if (_step == 0) {
      if (_activity.id == 'breathing') {
        return const SizedBox(height: 60); // Breathing widget handles itself
      }
      if (_activity.id == 'relaxation') {
        return ElevatedButton.icon(
          onPressed: () => setState(() => _step = 4),
          icon: const Icon(Icons.check),
          label: const Text('I am Relaxed / මම සූදානම්', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDeep,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
      return ElevatedButton.icon(
        onPressed: _startListen,
        icon: const Icon(Icons.mic),
        label: const Text('Start / ආරම්භ කරන්න', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeep,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else if (_step == 3) {
      return ElevatedButton(
        onPressed: _stopRecord,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Stop Recording', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    } else if (_step == 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_activity.id == 'easy_speaking' || _activity.id == 'picture_speaking')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () {}, // mock play
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play My Recording', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryWash,
                  foregroundColor: AppColors.primaryDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again\nනැවත'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primaryDeep),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCompletionDialog,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue\nඉදිරියට'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return const SizedBox(height: 60); // placeholder
  }
}

// ---------------------------------------------------------
// Custom Widgets for specific activities
// ---------------------------------------------------------

class _BreathingCustomWidget extends StatefulWidget {
  final VoidCallback onComplete;
  const _BreathingCustomWidget({required this.onComplete});

  @override
  State<_BreathingCustomWidget> createState() => _BreathingCustomWidgetState();
}

class _BreathingCustomWidgetState extends State<_BreathingCustomWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _repCount = 0;
  String _phase = "Breathe in slowly...";
  String _phaseSi = "සෙමින් හුස්ම ගන්න...";
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward) {
          if (mounted) {
            setState(() {
              _phase = "Breathe in slowly...";
              _phaseSi = "සෙමින් හුස්ම ගන්න...";
            });
          }
        } else if (status == AnimationStatus.reverse) {
          if (mounted) {
            setState(() {
              _phase = "Breathe out slowly...";
              _phaseSi = "සෙමින් හුස්ම පිට කරන්න...";
              _repCount++;
            });
          }
          if (_repCount >= 1) {
            _controller.stop();
            widget.onComplete();
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() => _started = true);
    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Column(
        children: [
          const Icon(Icons.air, size: 80, color: AppColors.primaryDeep),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startBreathing,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Breathing', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Container(
              width: 140 + (_controller.value * 60),
              height: 140 + (_controller.value * 60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6EE7B7).withValues(alpha: 0.4 + (_controller.value * 0.4)),
                border: Border.all(color: const Color(0xFF10B981), width: 4),
              ),
              child: const Center(child: Text('🫁', style: TextStyle(fontSize: 60))),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(_phase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDeep)),
        Text(_phaseSi, style: const TextStyle(fontSize: 16, color: AppColors.textLight)),
        const SizedBox(height: 16),
        Text('Repetition: $_repCount / 1', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
      ],
    );
  }
}

class _RelaxationCustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _stepCard('1', 'Relax your shoulders.', 'උරහිස් ලිහිල් කරන්න.'),
        _stepCard('2', 'Take a slow breath.', 'සෙමින් හුස්මක් ගන්න.'),
        _stepCard('3', 'Relax your face.', 'මුහුණේ මාංශ පේශී ලිහිල් කරන්න.'),
        _stepCard('4', 'Get ready to speak.', 'පහසුවෙන් කතා කිරීමට සූදානම් වෙන්න.'),
      ],
    );
  }

  Widget _stepCard(String num, String en, String si) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.primary, radius: 14, child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(en, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                Text(si, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
