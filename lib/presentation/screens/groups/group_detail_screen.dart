import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/group_entity.dart';
import '../../../domain/entities/group_member_entity.dart';
import '../../providers/group_provider.dart';
import '../../widgets/user_avatar.dart';

class GroupDetailScreen extends ConsumerWidget {
  final GroupEntity group;
  const GroupDetailScreen({super.key, required this.group});

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir del grupo'),
        content: const Text(
          'Al salir, tu colección personal (guardada antes de unirte) será restaurada. '
          '¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(groupActionsProvider).leaveGroup(group.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') _confirmLeave(context, ref);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Salir del grupo',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        children: [
          // ── Código del grupo ──────────────────────────────────────
          _InviteCodeCard(inviteCode: group.inviteCode),
          const SizedBox(height: AppConstants.spacingXL),

          // ── Miembros ──────────────────────────────────────────────
          Text(
            'Miembros',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.spacingM),
          membersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (members) => Column(
              children: members
                  .map((m) => _MemberTile(member: m))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta con el código de invitación ───────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  final String inviteCode;
  const _InviteCodeCard({required this.inviteCode});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Código copiado al portapapeles'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Código del grupo',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            inviteCode,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            child: OutlinedButton.icon(
              onPressed: () => _copyCode(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: BorderSide(
                    color: AppColors.white.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copiar código'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de miembro ───────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final GroupMemberEntity member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Row(
        children: [
          UserAvatar(name: member.userName, size: 44),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              member.userName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (member.isOwner)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
