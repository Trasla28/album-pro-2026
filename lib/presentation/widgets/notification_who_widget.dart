import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/group_provider.dart';

class NotificationWhoWidget extends ConsumerWidget {
  final String groupId;
  const NotificationWhoWidget({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final members = membersAsync.valueOrNull ?? [];
    if (members.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined,
              size: 14, color: AppColors.info),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Se avisará a: ${members.map((m) => m.userName).join(', ')}',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
