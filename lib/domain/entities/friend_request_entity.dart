enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequestEntity {
  final String id;
  final String senderId;
  final String senderName;
  final FriendRequestStatus status;
  final DateTime? createdAt;

  const FriendRequestEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.status,
    this.createdAt,
  });

  factory FriendRequestEntity.fromMap(String id, Map<String, dynamic> data) {
    return FriendRequestEntity(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Usuario',
      status: switch (data['status'] as String? ?? 'pending') {
        'accepted' => FriendRequestStatus.accepted,
        'rejected' => FriendRequestStatus.rejected,
        _ => FriendRequestStatus.pending,
      },
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
    );
  }
}
