import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/achievement_entity.dart';

class AchievementRepository {
  final FirebaseFirestore _db;

  AchievementRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _db.collection('user_achievements').doc(userId).collection('items');

  Stream<List<AchievementEntity>> watchAchievements(String userId) =>
      _col(userId)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => AchievementEntity.fromMap({...d.data(), 'id': d.id}))
              .toList());

  Future<void> unlock(String userId, String achievementId) async {
    final ref = _col(userId).doc(achievementId);
    final doc = await ref.get();
    if (doc.exists && (doc.data()?['unlocked'] as bool? ?? false)) return;
    await ref.set({
      'id': achievementId,
      'unlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AchievementEntity>> fetchAll(String userId) async {
    final snap = await _col(userId).get();
    return snap.docs
        .map((d) => AchievementEntity.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }
}

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => AchievementRepository(FirebaseFirestore.instance),
);
