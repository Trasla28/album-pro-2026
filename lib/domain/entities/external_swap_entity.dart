enum SwapStatus { pending, accepted, rejected, completed }

class SwapStickerRef {
  final int globalNumber;
  final String teamPosition;
  final String playerName;

  const SwapStickerRef({
    required this.globalNumber,
    required this.teamPosition,
    required this.playerName,
  });

  factory SwapStickerRef.fromMap(Map<String, dynamic> data) => SwapStickerRef(
    globalNumber: data['globalNumber'] as int? ?? 0,
    teamPosition: data['teamPosition'] as String? ?? '',
    playerName: data['playerName'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'globalNumber': globalNumber,
    'teamPosition': teamPosition,
    'playerName': playerName,
  };
}

class ExternalSwapEntity {
  final String id;
  final String requesterId;
  final String requesterName;
  final String receiverId;
  final String receiverName;
  final List<SwapStickerRef> offeredStickers;
  final List<SwapStickerRef> requestedStickers;
  final SwapStatus status;
  final int? ratingScore;
  final String? ratingComment;
  final DateTime? createdAt;

  const ExternalSwapEntity({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.receiverId,
    required this.receiverName,
    required this.offeredStickers,
    required this.requestedStickers,
    required this.status,
    this.ratingScore,
    this.ratingComment,
    this.createdAt,
  });

  factory ExternalSwapEntity.fromMap(String id, Map<String, dynamic> data) {
    final offered = (data['offeredStickers'] as List<dynamic>? ?? [])
        .map((e) => SwapStickerRef.fromMap(e as Map<String, dynamic>))
        .toList();
    final requested = (data['requestedStickers'] as List<dynamic>? ?? [])
        .map((e) => SwapStickerRef.fromMap(e as Map<String, dynamic>))
        .toList();
    return ExternalSwapEntity(
      id: id,
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? '',
      offeredStickers: offered,
      requestedStickers: requested,
      status: _parseStatus(data['status'] as String? ?? 'pending'),
      ratingScore: data['ratingScore'] as int?,
      ratingComment: data['ratingComment'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  static SwapStatus _parseStatus(String s) => switch (s) {
    'accepted' => SwapStatus.accepted,
    'rejected' => SwapStatus.rejected,
    'completed' => SwapStatus.completed,
    _ => SwapStatus.pending,
  };
}
