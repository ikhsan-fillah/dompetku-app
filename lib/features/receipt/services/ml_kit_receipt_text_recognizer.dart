import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'receipt_ocr_service.dart';

/// OCR di perangkat memakai ML Kit (aksara Latin). Foto tidak dikirim ke server.
class MlKitReceiptTextRecognizer implements ReceiptTextRecognizer {
  MlKitReceiptTextRecognizer()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<String> recognize(String imagePath) async {
    final result = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return result.text;
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
