class GroupEntity {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String inviteCode;
  final int memberCount;
  final DateTime? createdAt;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.inviteCode,
    required this.memberCount,
    this.createdAt,
  });

  factory GroupEntity.fromMap(String id, Map<String, dynamic> data) {
    return GroupEntity(
      id: id,
      name: data['name'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      memberCount: data['memberCount'] as int? ?? 1,
      createdAt: (data['createdAt'] as dynamic)?.toDate() as DateTime?,
    );
  }
}
