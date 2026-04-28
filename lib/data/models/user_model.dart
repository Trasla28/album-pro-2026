import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? avatarUrl;

  @HiveField(4)
  final String firebaseUid;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.firebaseUid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        firebaseUid: json['firebase_uid'] as String,
      );

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        name: name,
        avatarUrl: avatarUrl,
        firebaseUid: firebaseUid,
      );
}
