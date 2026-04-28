import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../../presentation/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return NotificationRepository(userId: user?.id ?? 'anonymous');
});

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  NotificationRepository({required this.userId});

  Stream<List<NotificationEntity>> watchNotifications() => _db
      .collection('notifications')
      .doc(userId)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => NotificationEntity.fromMap(d.id, d.data()))
          .toList());

  Future<void> markRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllRead() async {
    final snap = await _db
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<NotificationPrefsEntity> watchPrefs() => _db
      .collection('notification_preferences')
      .doc(userId)
      .snapshots()
      .map((s) => s.exists
          ? NotificationPrefsEntity.fromMap(s.data()!)
          : const NotificationPrefsEntity());

  Future<void> updatePrefs(NotificationPrefsEntity prefs) async {
    await _db
        .collection('notification_preferences')
        .doc(userId)
        .set(prefs.toMap(), SetOptions(merge: true));
  }
}
