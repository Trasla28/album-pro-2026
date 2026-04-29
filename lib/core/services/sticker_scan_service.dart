import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../data/mock/mock_album_data.dart';
import '../../domain/entities/sticker_entity.dart';

class StickerScanResult {
  final StickerEntity sticker;
  final String rawCode;
  const StickerScanResult({required this.sticker, required this.rawCode});
}

class StickerScanService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  late final Map<String, StickerEntity> _catalog;

  StickerScanService() {
    _catalog = {};
    for (final group in MockAlbumData.generate()) {
      for (final team in group.teams) {
        for (final sticker in team.stickers) {
          _catalog[sticker.teamPosition.toUpperCase()] = sticker;
        }
      }
    }
  }

  // Returns one result per unique sticker found in the image.
  // Each text block is processed independently to avoid cross-block false positives.
  Future<List<StickerScanResult>> scan(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);

    final results = <StickerScanResult>[];
    final seen = <int>{};

    // Pattern: 2-3 uppercase letters, optional space, 1-2 digits not followed by another digit.
    final regex = RegExp(r'([A-Z]{2,3})\s*(\d{1,2})(?!\d)');

    for (final block in recognized.blocks) {
      final text = block.text.toUpperCase().replaceAll('\n', ' ');
      for (final match in regex.allMatches(text)) {
        final code = '${match.group(1)} ${match.group(2)}';
        final sticker = _catalog[code];
        if (sticker != null && seen.add(sticker.globalNumber)) {
          results.add(StickerScanResult(sticker: sticker, rawCode: code));
        }
      }
    }

    return results;
  }

  void dispose() => _recognizer.close();
}
