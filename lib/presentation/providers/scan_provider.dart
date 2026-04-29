import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/sticker_scan_service.dart';

enum ScanStatus { idle, scanning, done, noResults, error }

class ScanState {
  final ScanStatus status;
  final String? imagePath;
  final List<StickerScanResult> results;
  final String? error;

  const ScanState({
    this.status = ScanStatus.idle,
    this.imagePath,
    this.results = const [],
    this.error,
  });

  ScanState copyWith({
    ScanStatus? status,
    String? imagePath,
    List<StickerScanResult>? results,
    String? error,
  }) =>
      ScanState(
        status: status ?? this.status,
        imagePath: imagePath ?? this.imagePath,
        results: results ?? this.results,
        error: error,
      );
}

class ScanNotifier extends AutoDisposeNotifier<ScanState> {
  late final StickerScanService _service;

  @override
  ScanState build() {
    _service = StickerScanService();
    ref.onDispose(_service.dispose);
    return const ScanState();
  }

  Future<void> pickAndScan(ImageSource source) async {
    state = state.copyWith(status: ScanStatus.scanning, error: null);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
      );
      if (file == null) {
        state = state.copyWith(status: ScanStatus.idle);
        return;
      }

      final results = await _service.scan(file.path);
      state = state.copyWith(
        status: results.isEmpty ? ScanStatus.noResults : ScanStatus.done,
        imagePath: file.path,
        results: results,
      );
    } catch (e) {
      state = state.copyWith(status: ScanStatus.error, error: e.toString());
    }
  }

  void removeResult(int globalNumber) {
    final updated = state.results
        .where((r) => r.sticker.globalNumber != globalNumber)
        .toList();
    state = state.copyWith(
      results: updated,
      status: updated.isEmpty ? ScanStatus.noResults : ScanStatus.done,
    );
  }

  void reset() => state = const ScanState();
}

final scanProvider =
    AutoDisposeNotifierProvider<ScanNotifier, ScanState>(ScanNotifier.new);
