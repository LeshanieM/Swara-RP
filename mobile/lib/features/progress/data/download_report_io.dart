import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> downloadProgressReport({
  required String fileName,
  required String contents,
}) async {
  final savedPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save progress report',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['txt'],
    bytes: Uint8List.fromList(utf8.encode(contents)),
  );
  return savedPath != null;
}
