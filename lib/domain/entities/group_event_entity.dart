class GroupEventEntity {
  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final int stickerGlobalNumber;
  final String stickerTeamPosition;
  final String playerName;
  final String eventType; // "obtained" | "duplicate"
  final DateTime? createdAt;

  const GroupEventEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.stickerGlobalNumber,
    required this.stickerTeamPosition,
    required this.playerName,
    required this.eventType,
    this.createdAt,
  });

  factory GroupEventEntity.fromMap(String id, Map<String, dynamic> data) =>
      GroupEventEntity(
        id: id,
        groupId: data['groupId'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        userName: data['userName'] as String? ?? 'Usuario',
        stickerGlobalNumber: data['stickerGlobalNumber'] as int? ?? 0,
        stickerTeamPosition: data['stickerTeamPosition'] as String? ?? '',
        playerName: data['playerName'] as String? ?? '',
        eventType: data['eventType'] as String? ?? 'obtained',
        createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
      );

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}
