import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/user_avatar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notificaciones'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationActionsProvider).markAllRead(),
              child: const Text('Leer todas',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
            ),
          GestureDetector(
            onTap: () => context.push('/home/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: UserAvatar(
                  name: user?.name ?? '', imageUrl: user?.avatarUrl, size: 34),
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 62),
            itemBuilder: (_, i) => _NotificationItem(
              notification: notifications[i],
              onDismiss: () => ref
                  .read(notificationActionsProvider)
                  .markRead(notifications[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onDismiss;

  const _NotificationItem(
      {required this.notification, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.primary),
      ),
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : AppColors.info.withValues(alpha: 0.05),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _color.withValues(alpha: 0.15),
            child: Icon(_icon, color: _color, size: 20),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: notification.isRead
                  ? FontWeight.w400
                  : FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                notification.timeAgo,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textDisabled),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }

  Color get _color => switch (notification.type) {
    NotificationType.stickerObtained => AppColors.success,
    NotificationType.duplicateAvailable => AppColors.warning,
    NotificationType.duplicateClaimed => AppColors.warning,
    NotificationType.claimReminder => AppColors.error,
    NotificationType.swapProposed => AppColors.info,
    NotificationType.swapAccepted => AppColors.success,
    NotificationType.groupMilestone => AppColors.accent,
    NotificationType.generic => AppColors.primary,
  };

  IconData get _icon => switch (notification.type) {
    NotificationType.stickerObtained => Icons.style,
    NotificationType.duplicateAvailable => Icons.style_outlined,
    NotificationType.duplicateClaimed => Icons.person,
    NotificationType.claimReminder => Icons.access_time,
    NotificationType.swapProposed => Icons.swap_horiz,
    NotificationType.swapAccepted => Icons.check_circle,
    NotificationType.groupMilestone => Icons.emoji_events,
    NotificationType.generic => Icons.notifications,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_outlined,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'Sin notificaciones',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí verás los avisos de tu grupo,\nrepetidas y propuestas de intercambio.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
