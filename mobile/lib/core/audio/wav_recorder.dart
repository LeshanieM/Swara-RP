import 'dart:io' show File;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records 16 kHz mono WAV, the format the C1, C3 and C4 analysis expects
/// (the API rejects AAC/.m4a). On the web the recording stays in memory
/// (a blob URL) instead of a temp file.
class WavRecorder {
  static const config = RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1);

  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startedAt;

  bool get isRecording => _startedAt != null;

  /// A temp file path on devices; the web recorder ignores the path.
  static Future<String> newPath(String prefix) async {
    if (kIsWeb) return '';
    final dir = await getTemporaryDirectory();
    return '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  /// Returns false when microphone permission is denied.
  Future<bool> start({String prefix = 'swara'}) async {
    if (!await _recorder.hasPermission()) return false;
    await _recorder.start(config, path: await newPath(prefix));
    _startedAt = DateTime.now();
    return true;
  }

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  /// Stops and returns the recording, or null if nothing was recorded.
  Future<RecordedAudio?> stop() async {
    final started = _startedAt;
    _startedAt = null;
    final result = await _recorder.stop();
    if (started == null) return null;
    return RecordedAudio.fromRecorder(result, DateTime.now().difference(started));
  }

  Future<void> cancel() async {
    _startedAt = null;
    await _recorder.cancel();
  }

  Future<void> dispose() => _recorder.dispose();
}

/// One finished recording: a file on devices, bytes (plus the blob URL for playback) on the web.
class RecordedAudio {
  /// The file path on devices, the blob URL on the web.
  final String path;
  final Uint8List? bytes;
  final Duration duration;

  /// The file name sent to the API (its extension tells the API the format).
  final String name;

  /// False for a recording the parent picked from the phone: that file is theirs, so it is never deleted.
  final bool ownsFile;

  const RecordedAudio(this.path, this.duration, {this.bytes, this.name = 'recording.wav', this.ownsFile = true});

  /// What `AudioRecorder.stop()` returned: a file path, or a blob URL on the web.
  static Future<RecordedAudio?> fromRecorder(String? result, Duration duration) async {
    if (result == null || result.isEmpty) return null;
    if (!kIsWeb) return File(result).existsSync() ? RecordedAudio(result, duration) : null;
    final res = await Dio().get<List<int>>(result, options: Options(responseType: ResponseType.bytes));
    final data = res.data;
    if (data == null || data.isEmpty) return null;
    return RecordedAudio(result, duration, bytes: Uint8List.fromList(data));
  }

  /// The recording as a multipart file for the API.
  Future<MultipartFile> toMultipart(String filename) async {
    if (bytes != null) return MultipartFile.fromBytes(bytes!, filename: filename);
    return MultipartFile.fromFile(path, filename: filename);
  }

  /// Deletes the local copy once the server has it (the server deletes its own copy too).
  Future<void> delete() async {
    if (kIsWeb || !ownsFile) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
