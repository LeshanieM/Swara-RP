import 'dart:io';

/// Best-effort removal of a temporary child-response recording after use.
Future<void> deleteLocalAudio(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException {
    // A cleanup failure must not change therapy progress or verification.
  }
}
