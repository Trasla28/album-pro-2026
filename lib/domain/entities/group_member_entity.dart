class GroupMemberEntity {
  final String userId;
  final String groupId;
  final String userName;
  final String? userAvatar;
  final String role; // "owner" | "member"
  final DateTime? joinedAt;

  const GroupMemberEntity({
    required this.userId,
    required this.groupId,
    required this.userName,
    this.userAvatar,
    required this.role,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  factory GroupMemberEntity.fromMap(Map<String, dynamic> data) => GroupMemberEntity(
        userId: data['userId'] as String? ?? '',
        groupId: data['groupId'] as String? ?? '',
        userName: data['userName'] as String? ?? 'Usuario',
        userAvatar: data['userAvatar'] as String?,
        role: data['role'] as String? ?? 'member',
        joinedAt: (data['joinedAt'] as dynamic)?.toDate() as DateTime?,
      );
}
