class UserEntity {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String firebaseUid;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.firebaseUid,
  });
}
