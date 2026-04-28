import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/notification_entity.dart';

class InAppNotificationBanner extends StatefulWidget {
  final Widget child;
  const InAppNotificationBanner({super.key, required this.child});

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  StreamSubscription<RemoteMessage>? _sub;
  String _title = '';
  String _body = '';
  NotificationType _type = NotificationType.generic;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    _sub = NotificationService.foregroundMessages.listen(_onMessage);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _sub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _onMessage(RemoteMessage message) {
    if (!mounted) return;
    setState(() {
      _title = message.notification?.title ?? '';
      _body = message.notification?.body ?? '';
      _type = NotificationEntity.parseType(
          message.data['type'] as String? ?? '');
    });
    _anim.forward(from: 0);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    if (mounted) _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slide,
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: _dismiss,
                child: _BannerCard(
                    title: _title, body: _body, type: _type),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String title;
  final String body;
  final NotificationType type;
  const _BannerCard(
      {required this.title, required this.body, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _typeColor(type).withValues(alpha: 0.15),
          child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(body,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.close, size: 16, color: AppColors.textDisabled),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  static Color _typeColor(NotificationType t) => switch (t) {
    NotificationType.stickerObtained => AppColors.success,
    NotificationType.duplicateAvailable => AppColors.warning,
    NotificationType.duplicateClaimed => AppColors.warning,
    NotificationType.claimReminder => AppColors.error,
    NotificationType.swapProposed => AppColors.info,
    NotificationType.swapAccepted => AppColors.success,
    NotificationType.groupMilestone => AppColors.accent,
    NotificationType.generic => AppColors.primary,
  };

  static IconData _typeIcon(NotificationType t) => switch (t) {
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
