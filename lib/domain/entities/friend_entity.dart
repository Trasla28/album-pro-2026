class FriendEntity {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String friendCode;

  const FriendEntity({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.friendCode,
  });

  factory FriendEntity.fromMap(String userId, Map<String, dynamic> data) {
    return FriendEntity(
      userId: userId,
      name: data['displayName'] as String? ?? 'Usuario',
      avatarUrl: data['avatarUrl'] as String?,
      friendCode: data['friendCode'] as String? ?? '',
    );
  }
}
