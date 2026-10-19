import 'dart:io';

Future<String> recordingTempPath() async => Directory.systemTemp.path;
