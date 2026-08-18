import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<T> withTemporaryMlKitInputImage<T>(
  Uint8List bytes,
  Future<T> Function(InputImage image) operation,
) async {
  final directory = await Directory.systemTemp.createTemp(
    'screenshot_inbox_mlkit_',
  );
  final file = File('${directory.path}/input.jpg');
  try {
    await file.writeAsBytes(bytes, flush: true);
    return await operation(InputImage.fromFilePath(file.path));
  } finally {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
