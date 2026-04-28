import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';

final notificationsProvider = StreamProvider<List<NotificationEntity>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchNotifications();
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final notificationPrefsProvider =
    StreamProvider<NotificationPrefsEntity>((ref) {
  return ref.watch(notificationRepositoryProvider).watchPrefs();
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref.read(notificationRepositoryProvider));
});

class NotificationActions {
  final NotificationRepository _repo;
  NotificationActions(this._repo);

  Future<void> markRead(String id) => _repo.markRead(id);
  Future<void> markAllRead() => _repo.markAllRead();
  Future<void> updatePrefs(NotificationPrefsEntity prefs) =>
      _repo.updatePrefs(prefs);
}
