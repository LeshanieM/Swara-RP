import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:swara/core/theme/app_theme.dart';
import 'package:swara/features/speech/data/recording_temp_path.dart';
import 'package:swara/features/speech/data/providers/speech_provider.dart';

const String _kSinhalaReadingPassage =
    'අද උදෑසන නදී සහ ඇගේ මිතුරන් පාසල් වත්තට ගියා. ඔවුන් එහි තිබූ ලස්සන මල් පැල නිරීක්ෂණය කළා. පසුව ඔවුන් ගුරුවරිය සමඟ එකතු වී වත්ත පිරිසිදු කළා. මෙම කාර්යය ඔවුන්ට ඉතා සතුටක් ගෙන දුන්නා.';

class SpeechTaskScreen extends ConsumerStatefulWidget {
  final String childId;

  const SpeechTaskScreen({
    super.key,
    this.childId = 'child_1',
  });

  @override
  ConsumerState<SpeechTaskScreen> createState() => _SpeechTaskScreenState();
}

class _SpeechTaskScreenState extends ConsumerState<SpeechTaskScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedAgeGroup; // 0 = 5–10 (Picture Description), 1 = 11–14 (Reading Passage)
  bool _isRecording = false;
  bool _isAnalyzing = false;
  int _seconds = 0;
  Timer? _timer;
  late final AudioRecorder _recorder;
  String? _recordedAudioPath;
  BytesBuilder? _webAudioBuilder;
  StreamSubscription<Uint8List>? _webAudioSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission is required. Please enable it in system settings.'),
                backgroundColor: AppColors.coralRed,
              ),
            );
          }
          return;
        }
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone access is required to assess speech disfluency.'),
              backgroundColor: AppColors.coralRed,
            ),
          );
        }
        return;
      }

      final taskPrefix = _selectedAgeGroup == 0 ? 'picture' : 'reading';
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      );

      if (kIsWeb) {
        _webAudioBuilder = BytesBuilder(copy: false);
        _webAudioSubscription = (await _recorder.startStream(config)).listen(
          (chunk) => _webAudioBuilder?.add(chunk),
          onError: (Object error) {
            debugPrint('Browser audio stream error: $error');
          },
        );
        _recordedAudioPath = null;
      } else {
        final tempDir = await recordingTempPath();
        final filePath =
            '$tempDir/c1_${taskPrefix}_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(config, path: filePath);
        _recordedAudioPath = filePath;
      }

      setState(() {
        _isRecording = true;
        _seconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        final message = kIsWeb && e.toString().contains('Stream not supported')
            ? 'Browser recording is unavailable. Please upload an audio recording instead.'
            : 'Failed to start recording: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.coralRed,
          ),
        );
      }
    }
  }

  Future<void> _pickAudioAndAnalyze() async {
    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['wav', 'mp3', 'm4a', 'aac', 'flac', 'ogg', 'webm'],
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (selection == null || selection.files.isEmpty || !mounted) return;

      final file = selection.files.single;
      if (file.size <= 0) {
        _showAudioMessage('That audio file is empty. Please choose another one.');
        return;
      }
      if (file.size > 25 * 1024 * 1024) {
        _showAudioMessage('Please choose an audio file smaller than 25 MB.');
        return;
      }
      final bytes = file.bytes;
      final path = kIsWeb ? null : file.path;
      if ((bytes == null || bytes.isEmpty) && (path == null || path.isEmpty)) {
        _showAudioMessage('Could not read that audio file. Please choose another one.');
        return;
      }

      setState(() => _seconds = 0);
      await _analyzeAudio(
        audioPath: path,
        audioBytes: bytes,
        fileName: file.name,
        contentType: _audioContentType(file.extension ?? file.name.split('.').last),
      );
    } catch (error) {
      if (mounted) {
        _showAudioMessage('Could not open the audio picker: $error');
      }
    }
  }

  String _audioContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      case 'webm':
        return 'audio/webm';
      case 'wav':
      default:
        return 'audio/wav';
    }
  }

  void _showAudioMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.coralRed),
    );
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    String? audioPath = _recordedAudioPath;
    Uint8List? audioBytes;
    try {
      if (_isRecording) {
        final stoppedPath = await _recorder.stop();
        if (kIsWeb) {
          audioBytes = _webAudioBuilder?.takeBytes();
          await _webAudioSubscription?.cancel();
          _webAudioSubscription = null;
          _webAudioBuilder = null;
        } else if (stoppedPath != null && stoppedPath.isNotEmpty) {
          audioPath = stoppedPath;
        }
      }
    } catch (e) {
      debugPrint('Error stopping audio recorder: $e');
    }

    if (audioPath == null && (audioBytes == null || audioBytes.isEmpty)) {
      if (mounted) {
        setState(() => _isRecording = false);
        _showAudioMessage('No audio was captured. Please try recording or upload a file.');
      }
      return;
    }

    setState(() => _isRecording = false);
    await _analyzeAudio(audioPath: audioPath, audioBytes: audioBytes);
  }

  Future<void> _analyzeAudio({
    String? audioPath,
    Uint8List? audioBytes,
    String? fileName,
    String? contentType,
  }) async {
    if (!mounted) return;
    setState(() => _isAnalyzing = true);

    final taskType =
        _selectedAgeGroup == 0 ? 'picture-description' : 'passage-reading';
    final childAge = _selectedAgeGroup == 0 ? 8.0 : 12.0;
    final referenceText =
        _selectedAgeGroup == 1 ? _kSinhalaReadingPassage : null;

    Map<String, dynamic>? analysisResult;
    try {
      final notifier = ref.read(speechNotifierProvider(widget.childId).notifier);
      if (audioPath != null && audioPath.isNotEmpty) {
        notifier.setAudioPath(
          audioPath,
          fileName: fileName ?? 'recording.wav',
          contentType: contentType ?? 'audio/wav',
        );
      } else if (audioBytes != null && audioBytes.isNotEmpty) {
        notifier.setAudioBytes(
          audioBytes,
          fileName: fileName ?? 'recording.wav',
          contentType: contentType ?? 'audio/wav',
        );
      }
      analysisResult = await notifier.analyze(
        taskType: taskType,
        age: childAge,
        referenceText: referenceText,
      );
    } catch (e) {
      debugPrint('Analysis error: $e');
    }

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
    });

    if (analysisResult != null) {
      context.pushReplacement('/c1/complete', extra: analysisResult);
    } else {
      context.pushReplacement('/c1/complete', extra: _seconds);
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
    _webAudioSubscription?.cancel();
    _recorder.dispose();
    _pulseController.dispose();
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
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFF0F172A), size: 26),
                      onPressed: () {
                        if (_isRecording) {
                          _stopRecording();
                        } else if (_selectedAgeGroup != null) {
                          setState(() => _selectedAgeGroup = null);
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAgeGroup == null
                                ? 'Select Age'
                                : (_selectedAgeGroup == 0
                                    ? 'Picture Description (Age 5–10)'
                                    : 'Reading Practice (Age 11–14)'),
                            style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Component 1 — Sinhala Stuttering Assessment",
                            style: TextStyle(
                                color: Color(0xFF0066CC),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _selectedAgeGroup == null
                    ? _buildAgeSelection()
                    : _buildTask(),
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
          const Text('How old are you?',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('ඔයාගෙ වයස කීයද?',
              style: TextStyle(fontSize: 16, color: AppColors.textLight)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
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
                        Text('Age 5–10',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                        SizedBox(height: 4),
                        Text('Picture Talk',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
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
                        Text('Age 11–14',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                        SizedBox(height: 4),
                        Text('Reading Task',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0066CC),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTask() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (_selectedAgeGroup == 0) _buildPictureTask() else _buildReadingTask(),
          const SizedBox(height: 28),

          // Analysis In Progress
          if (_isAnalyzing) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(color: AppColors.ctaOrange),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing Speech with SSI-4 Model...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'කථන දත්ත විශ්ලේෂණය කෙරේ. කරුණාකර රැඳී සිටින්න...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (_isRecording) ...[
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: AppColors.coralRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 42),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Recording in 16kHz WAV mono...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coralRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Stop & Analyze Recording',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaOrange,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      _selectedAgeGroup == 0
                          ? 'Start Speaking'
                          : 'Start Reading',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedAgeGroup == 0
                  ? 'කතා කිරීම ආරම්භ කරන්න'
                  : 'කියවීම ආරම්භ කරන්න',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickAudioAndAnalyze,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload an audio recording'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1D4A87),
                  side: const BorderSide(color: Color(0xFF1D4A87), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'WAV, MP3, M4A, AAC, FLAC, OGG or WEBM · up to 25 MB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPictureTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let's Talk About This Picture!",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          const Text("මේ පින්තූරය ගැන අපි කතා කරමු!",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight)),
          const SizedBox(height: 20),
          // Picture Box
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softYellow.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.softYellow, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/park_family.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('🌳 🧒 🐕 👨‍👩‍👦', style: TextStyle(fontSize: 48)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Look at the picture and tell us what you see.',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'පින්තූරය බලලා ඔබ දකින දේ ගැන කතා කරන්න.',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Read the Paragraph",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          const Text("ඡේදය කියවන්න",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight)),
          const SizedBox(height: 20),
          const Text(
            'Please read the following paragraph aloud.',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'පහත ඡේදය ශබ්ද නඟා කියවන්න.',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              _kSinhalaReadingPassage,
              style: TextStyle(
                  fontSize: 21,
                  height: 1.85,
                  color: AppColors.text,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
