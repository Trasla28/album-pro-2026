import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/group_event_entity.dart';
import 'user_avatar.dart';

class ActivityFeedItem extends StatelessWidget {
  final GroupEventEntity event;

  const ActivityFeedItem({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(name: event.userName, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary),
                    children: [
                      TextSpan(
                        text: event.userName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' consiguió '),
                      TextSpan(
                        text: event.stickerTeamPosition,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.playerName,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.timeAgo,
            style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
