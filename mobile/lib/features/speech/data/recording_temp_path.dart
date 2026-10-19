import 'recording_temp_path_stub.dart'
    if (dart.library.io) 'recording_temp_path_io.dart' as implementation;

Future<String> recordingTempPath() => implementation.recordingTempPath();
