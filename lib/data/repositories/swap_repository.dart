import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/external_swap_entity.dart';
import '../../domain/entities/swap_match_entity.dart';
import '../../presentation/providers/auth_provider.dart';

final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return SwapRepository(
    userId: user?.id ?? 'anonymous',
    userName: user?.name ?? 'Usuario',
  );
});

class SwapRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;
  final String userName;

  SwapRepository({required this.userId, required this.userName});

  // Incoming proposals where I am the receiver
  Stream<List<ExternalSwapEntity>> watchIncomingSwaps() =>
      _db
          .collection('external_swaps')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs
              .map((d) => ExternalSwapEntity.fromMap(d.id, d.data()))
              .toList());

  // All swaps I requested (sent)
  Stream<List<ExternalSwapEntity>> watchMySwapHistory() =>
      _db
          .collection('external_swaps')
          .where('requesterId', isEqualTo: userId)
          .snapshots()
          .map((s) {
        final list = s.docs
            .map((d) => ExternalSwapEntity.fromMap(d.id, d.data()))
            .toList();
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });

  Future<void> proposeSwap({
    required String receiverId,
    required String receiverName,
    required List<SwapStickerRef> offeredStickers,
    required List<SwapStickerRef> requestedStickers,
  }) async {
    await _db.collection('external_swaps').add({
      'requesterId': userId,
      'requesterName': userName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'offeredStickers': offeredStickers.map((s) => s.toMap()).toList(),
      'requestedStickers': requestedStickers.map((s) => s.toMap()).toList(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptSwap(String swapId) async =>
      _db.collection('external_swaps').doc(swapId).update({'status': 'accepted'});

  Future<void> rejectSwap(String swapId) async =>
      _db.collection('external_swaps').doc(swapId).update({'status': 'rejected'});

  Future<void> completeSwap(String swapId) async =>
      _db.collection('external_swaps').doc(swapId).update({'status': 'completed'});

  Future<void> rateSwap(String swapId, int score, {String? comment}) async =>
      _db.collection('external_swaps').doc(swapId).update({
        'ratingScore': score,
        if (comment != null && comment.isNotEmpty) 'ratingComment': comment,
      });

  // Client-side matching: queries external duplicates published by other users
  // Falls back to demo matches if no real data exists.
  Future<List<SwapMatchEntity>> computeMatches({
    required List<int> myDuplicateNumbers,
    required List<int> myMissingNumbers,
  }) async {
    if (myMissingNumbers.isEmpty) {
      return _demoMatches(myDuplicateNumbers, myMissingNumbers);
    }

    // Query up to 30 of my missing numbers in batches of 10
    final searchBatch = myMissingNumbers.take(30).toList();
    final batches = <List<int>>[];
    for (int i = 0; i < searchBatch.length; i += 10) {
      batches.add(searchBatch.sublist(
          i, i + 10 < searchBatch.length ? i + 10 : searchBatch.length));
    }

    final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final batch in batches) {
      try {
        final snap = await _db
            .collection('external_duplicates')
            .where('userId', isNotEqualTo: userId)
            .where('stickerGlobalNumber', whereIn: batch)
            .get();
        allDocs.addAll(snap.docs);
      } catch (_) {
        // Index not yet created or no data — fallback handled below
      }
    }

    if (allDocs.isEmpty) {
      return _demoMatches(myDuplicateNumbers, myMissingNumbers);
    }

    final byUser = <String, List<int>>{};
    final userNames = <String, String>{};
    for (final doc in allDocs) {
      final data = doc.data();
      final uid = data['userId'] as String? ?? '';
      final name = data['userName'] as String? ?? 'Usuario';
      final number = data['stickerGlobalNumber'] as int? ?? 0;
      if (uid.isEmpty) continue;
      byUser.putIfAbsent(uid, () => []).add(number);
      userNames[uid] = name;
    }

    final myDupSet = myDuplicateNumbers.toSet();
    final myMissingSet = myMissingNumbers.toSet();

    final matches = byUser.entries.map((entry) {
      final theyHaveIWant =
          entry.value.toSet().intersection(myMissingSet).toList();
      final iHaveTheyWant = myDupSet.toList();
      final type = (theyHaveIWant.isNotEmpty && iHaveTheyWant.isNotEmpty)
          ? MatchType.perfect
          : MatchType.partial;
      return SwapMatchEntity(
        userId: entry.key,
        userName: userNames[entry.key] ?? 'Usuario',
        matchType: type,
        rating: 0,
        theyHaveIWant: theyHaveIWant,
        iHaveTheyWant: iHaveTheyWant,
      );
    }).toList();

    matches.sort((a, b) {
      if (a.isPerfect && !b.isPerfect) return -1;
      if (!a.isPerfect && b.isPerfect) return 1;
      return b.theyHaveIWant.length.compareTo(a.theyHaveIWant.length);
    });

    return matches;
  }

  List<SwapMatchEntity> _demoMatches(
      List<int> myDups, List<int> myMissing) {
    final sampleWant = myMissing.isNotEmpty
        ? myMissing.take(3).toList()
        : [42, 155, 280];
    final sampleOffer =
        myDups.isNotEmpty ? myDups.take(2).toList() : [88, 213];

    return [
      SwapMatchEntity(
        userId: 'demo_1', userName: 'Carlos M.',
        matchType: MatchType.perfect, rating: 4.8,
        theyHaveIWant: sampleWant.take(2).toList(),
        iHaveTheyWant: sampleOffer.take(1).toList(),
      ),
      SwapMatchEntity(
        userId: 'demo_2', userName: 'Laura P.',
        matchType: MatchType.perfect, rating: 4.5,
        theyHaveIWant: sampleWant.take(1).toList(),
        iHaveTheyWant: sampleOffer,
      ),
      SwapMatchEntity(
        userId: 'demo_3', userName: 'Diego R.',
        matchType: MatchType.partial, rating: 4.2,
        theyHaveIWant: sampleWant,
        iHaveTheyWant: [],
      ),
      SwapMatchEntity(
        userId: 'demo_4', userName: 'Ana S.',
        matchType: MatchType.partial, rating: 3.9,
        theyHaveIWant: sampleWant.take(2).toList(),
        iHaveTheyWant: [],
      ),
      SwapMatchEntity(
        userId: 'demo_5', userName: 'Martín F.',
        matchType: MatchType.partial, rating: 4.7,
        theyHaveIWant: sampleWant.take(1).toList(),
        iHaveTheyWant: sampleOffer.take(1).toList(),
      ),
    ];
  }
}
