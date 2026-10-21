import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swara/core/audio/wav_recorder.dart';
import 'package:swara/core/camera/task_camera.dart';
import 'package:swara/core/constants/app_constants.dart';
import 'package:swara/core/widgets/parent_pin_dialog.dart';
import 'package:swara/features/auth/data/models/user_model.dart';
import 'package:swara/features/concomitant/data/providers/video_analysis_provider.dart';
import 'package:swara/core/network/api_exception.dart';
import 'package:swara/core/storage/storage_service.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/features/child/data/providers/child_provider.dart';
import '../../data/models/speech_assessment.dart';
import '../../data/providers/speech_provider.dart';

class SpeechTaskScreen extends ConsumerStatefulWidget {
  const SpeechTaskScreen({super.key});

  @override
  ConsumerState<SpeechTaskScreen> createState() => _SpeechTaskScreenState();
}

class _SpeechTaskScreenState extends ConsumerState<SpeechTaskScreen> with SingleTickerProviderStateMixin {
  int? _selectedAgeGroup; // 0 = 5-10 (picture description), 1 = 11-14 (reading)
  bool _isRecording = false;
  bool _isUploading = false;
  int _seconds = 0;
  Timer? _timer;
  final WavRecorder _recorder = WavRecorder();
  final TaskCamera _camera = TaskCamera();

  /// Parent setting: film the face during the task for C2 (path A). Off by default.
  bool _filmFace = false;
  bool _filming = false;

  /// The child's age decides the task (the API rejects the other one), so only that card can be chosen.
  int? get _childAgeGroup {
    final age = ref.read(activeChildProvider)?.age;
    if (age == null) return null;
    return age <= 10 ? 0 : 1;
  }
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

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
    StorageService.getBool(AppConstants.c2InTaskCameraKey).then((on) {
      if (mounted) setState(() => _filmFace = (on ?? false) && TaskCamera.isSupported);
    });
  }

  /// Turning filming on or off is the parent's decision (video consent), so it needs parent mode.
  Future<void> _setFilmFace(bool on) async {
    if (!await ensureParentMode(context, ref)) return;
    await StorageService.setBool(AppConstants.c2InTaskCameraKey, on);
    if (mounted) setState(() => _filmFace = on);
  }

  Future<void> _startRecording() async {
    // The camera starts first, so the video covers the whole recording; C2 pads each stutter moment, which
    // absorbs the fraction of a second between the two starts.
    final filming = _filmFace && !StorageService.isDemoMode() && await _camera.start();
    if (!StorageService.isDemoMode() && !await _recorder.start(prefix: 'c1')) {
      if (filming) await _camera.stop();
      _showError('Microphone permission is needed to record.');
      return;
    }
    if (!mounted) return;
    _filming = filming;
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
    if (StorageService.isDemoMode()) {
      context.pushReplacement('/c1/complete', extra: SpeechSubmission(durationSeconds: _seconds));
      return;
    }
    final audio = await _recorder.stop();
    final video = _filming ? await _camera.stop() : null;
    _filming = false;
    if (audio == null) {
      if (video != null) await File(video).delete().catchError((_) => File(video));
      _showError('Nothing was recorded. Please try again.');
      return;
    }
    await _upload(audio, video);
  }

  /// Path A: the face video goes to C2 with this C1 assessment's id; C2 waits for C1's stutter moments.
  /// A failed video upload never blocks C1's result.
  Future<void> _uploadVideo(String videoPath, String assessmentId, ChildRef child) async {
    try {
      await ref.read(videoAnalysisServiceProvider).startInTask(
            childId: child.childId,
            age: child.age,
            c1AssessmentId: assessmentId,
            videoPath: videoPath,
          );
    } catch (e) {
      debugPrint('In-task video upload failed: $e');
    } finally {
      await File(videoPath).delete().catchError((_) => File(videoPath));
    }
  }

  Future<void> _upload(RecordedAudio audio, [String? videoPath]) async {
    final child = ref.read(activeChildProvider);
    final task = ref.read(speechTaskProvider(child!.age)).valueOrNull;
    if (task == null) {
      _showError('The task is still loading. Please try again.');
      return;
    }
    setState(() => _isUploading = true);
    try {
      final id = await ref.read(speechServiceProvider).submit(
            audio: audio,
            childId: child.childId,
            age: child.age,
            task: task,
            passage: _passage(task),
            picture: _picture(task),
          );
      await audio.delete();
      if (videoPath != null) unawaited(_uploadVideo(videoPath, id, child));
      if (!mounted) return;
      context.pushReplacement(
        '/c1/complete',
        extra: SpeechSubmission(durationSeconds: audio.duration.inSeconds, assessmentId: id),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showError(ApiException.from(e).message);
    }
  }

  /// Formats the API accepts; m4a/aac is what most phone voice recorders save.
  static const _audioExtensions = ['wav', 'flac', 'ogg', 'mp3', 'm4a', 'aac'];
  static const _maxAudioMb = 50; // the API's MAX_UPLOAD_MB

  /// Analyse a recording made earlier (for example with the phone's voice recorder) instead of recording now.
  /// It is scored as this age band's task, so it should be the child doing that task.
  Future<void> _pickRecording() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _audioExtensions,
      withData: kIsWeb, // the web has no file path
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final ext = (f.extension ?? f.name.split('.').last).toLowerCase();
    if (!_audioExtensions.contains(ext)) {
      _showError('Unsupported format (.$ext). Use: ${_audioExtensions.join(', ')}.');
      return;
    }
    if (f.size > _maxAudioMb * 1024 * 1024) {
      _showError('The recording is larger than $_maxAudioMb MB.');
      return;
    }
    final path = kIsWeb ? null : f.path;
    if (path == null && f.bytes == null) {
      _showError('Could not read that file.');
      return;
    }
    await _upload(RecordedAudio(path ?? f.name, Duration.zero, bytes: kIsWeb ? f.bytes : null, name: f.name, ownsFile: false));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // The Sinhala passage when there is one, otherwise the first passage of the band.
  SpeechPassage? _passage(SpeechTask task) => task.passages.isEmpty
      ? null
      : task.passages.firstWhere((p) => p.language == 'si', orElse: () => task.passages.first);

  SpeechPicture? _picture(SpeechTask task) => task.pictures.isEmpty ? null : task.pictures.first;

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_filming) _camera.stop();
    _recorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    if (child == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Choose a child on the therapist home first.', textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.c1Gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 26),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAgeGroup == null ? 'Select Age' : (_selectedAgeGroup == 0 ? 'Picture Description' : 'Reading Practice'),
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text("Component 1 — Speech Assessment", style: TextStyle(color: Color(0xFF0066CC), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _selectedAgeGroup == null ? _buildAgeSelection() : _buildTask(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('How old are you?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('ඔයාගෙ වයස කීයද?', style: TextStyle(fontSize: 16, color: AppColors.textLight)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _ageCard(0, GestureDetector(
                  onTap: () => setState(() => _selectedAgeGroup = 0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardCream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Column(
                      children: [
                        Text('👧👦', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Age 5–10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      ],
                    ),
                  ),
                )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ageCard(1, GestureDetector(
                  onTap: () => setState(() => _selectedAgeGroup = 1),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardCream,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Column(
                      children: [
                        Text('🧑👩', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Age 11–14', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
                      ],
                    ),
                  ),
                )),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Dims and disables the card that doesn't match the child's age.
  Widget _ageCard(int group, Widget card) {
    final enabled = _childAgeGroup == null || _childAgeGroup == group;
    return IgnorePointer(ignoring: !enabled, child: Opacity(opacity: enabled ? 1 : 0.35, child: card));
  }

  Widget _buildTask() {
    final task = ref.watch(speechTaskProvider(ref.read(activeChildProvider)!.age));
    if (task.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(ApiException.from(task.error!).message, textAlign: TextAlign.center),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_selectedAgeGroup == 0) _buildPictureTask(task.valueOrNull) else _buildReadingTask(task.valueOrNull),
          const SizedBox(height: 32),

          // Timer & Animation
          if (_isRecording && _filming && _camera.controller != null) ...[
            // A small preview, so the child's face stays in frame.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(width: 120, height: 160, child: CameraPreview(_camera.controller!)),
            ),
            const SizedBox(height: 12),
          ],
          if (_isRecording) ...[
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: AppColors.coralRed, shape: BoxShape.circle),
                  child: const Icon(Icons.mic, color: Colors.white, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _formatTime(_seconds),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coralRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Stop Recording', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading || task.isLoading ? null : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaOrange,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isUploading
                    ? const SizedBox(height: 28, width: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(_selectedAgeGroup == 0 ? 'Start Speaking' : 'Start Reading', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (!StorageService.isDemoMode())
              TextButton.icon(
                onPressed: _isUploading || task.isLoading ? null : _pickRecording,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Or choose a recording from this device', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            if (TaskCamera.isSupported && !StorageService.isDemoMode())
              SwitchListTile(
                value: _filmFace,
                onChanged: _isUploading ? null : _setFilmFace,
                secondary: const Icon(Icons.videocam_rounded),
                title: const Text('Film the face during this task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('Parent setting, for the face-movement analysis (C2). The video is deleted after the analysis.',
                    style: TextStyle(fontSize: 11)),
              ),
            const SizedBox(height: 12),
            Text(
              _selectedAgeGroup == 0 ? 'කතා කිරීම ආරම්භ කරන්න' : 'කියවීම ආරම්භ කරන්න',
              style: const TextStyle(fontSize: 16, color: AppColors.text, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPictureTask(SpeechTask? task) {
    final picture = task == null ? null : _picture(task);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let's Talk About This Picture!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text("මේ පින්තූරය ගැන අපි කතා කරමු!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          const SizedBox(height: 20),
          // Picture Box
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softYellow.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.softYellow, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icons/pic.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            picture?.promptEn ?? 'Look at the picture and tell us what you see.',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            picture?.promptSi ?? 'පින්තූරය බලලා ඔබ දකින දේ ගැන කතා කරන්න.',
            style: const TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTask(SpeechTask? task) {
    final passage = task == null ? null : _passage(task);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Read the Paragraph", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text)),
          const SizedBox(height: 4),
          const Text("ඡේදය කියවන්න", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          const SizedBox(height: 20),
          const Text(
            'Please read the following paragraph aloud.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'පහත ඡේදය ශබ්ද නඟා කියවන්න.',
            style: TextStyle(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          // The child reads the catalog passage that is sent with the recording: its text gives C1 the exact syllable count.
          Text(
            passage?.text ?? 'අද උදෑසන නදී සහ ඇගේ මිතුරන් පාසල් වත්තට ගියා. ඔවුන් එහි තිබූ ලස්සන මල් පැල නිරීක්ෂණය කළා. පසුව ඔවුන් ගුරුවරිය සමඟ එකතු වී වත්ත පිරිසිදු කළා. මෙම කාර්යය ඔවුන්ට ඉතා සතුටක් ගෙන දුන්නා.',
            style: const TextStyle(fontSize: 22, height: 1.8, color: AppColors.text, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
