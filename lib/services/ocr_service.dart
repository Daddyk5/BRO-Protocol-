import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());

/// Picks a screenshot and extracts its text on-device with ML Kit.
/// Nothing leaves the phone during this step.
class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// Returns the recognized text, an empty string if none was found, or
  /// `null` if the user cancelled the picker.
  Future<String?> pickAndRecognize() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(image.path));
      return result.blocks.map((b) => b.text.trim()).where((t) => t.isNotEmpty).join('\n');
    } finally {
      await recognizer.close();
    }
  }
}
