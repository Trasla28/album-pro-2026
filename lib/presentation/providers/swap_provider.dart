import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/swap_repository.dart';
import '../../domain/entities/external_swap_entity.dart';
import '../../domain/entities/swap_match_entity.dart';
import 'album_provider.dart';

final incomingSwapsProvider = StreamProvider<List<ExternalSwapEntity>>((ref) {
  return ref.watch(swapRepositoryProvider).watchIncomingSwaps();
});

final mySwapHistoryProvider = StreamProvider<List<ExternalSwapEntity>>((ref) {
  return ref.watch(swapRepositoryProvider).watchMySwapHistory();
});

final swapMatchesProvider = FutureProvider<List<SwapMatchEntity>>((ref) async {
  final album = ref.watch(albumProvider);
  final myDuplicates = album.quantities.entries
      .where((e) => e.value > 1)
      .map((e) => e.key)
      .toList();
  final myMissing = album.quantities.entries
      .where((e) => e.value == 0)
      .map((e) => e.key)
      .take(30)
      .toList();
  return ref.read(swapRepositoryProvider).computeMatches(
        myDuplicateNumbers: myDuplicates,
        myMissingNumbers: myMissing,
      );
});

final swapActionsProvider = Provider<SwapActions>((ref) {
  return SwapActions(ref.read(swapRepositoryProvider));
});

class SwapActions {
  final SwapRepository _repo;
  SwapActions(this._repo);

  Future<void> propose({
    required String receiverId,
    required String receiverName,
    required List<SwapStickerRef> offeredStickers,
    required List<SwapStickerRef> requestedStickers,
  }) =>
      _repo.proposeSwap(
        receiverId: receiverId,
        receiverName: receiverName,
        offeredStickers: offeredStickers,
        requestedStickers: requestedStickers,
      );

  Future<void> accept(String swapId) => _repo.acceptSwap(swapId);
  Future<void> reject(String swapId) => _repo.rejectSwap(swapId);
  Future<void> complete(String swapId) => _repo.completeSwap(swapId);
  Future<void> rate(String swapId, int score, {String? comment}) =>
      _repo.rateSwap(swapId, score, comment: comment);
}
