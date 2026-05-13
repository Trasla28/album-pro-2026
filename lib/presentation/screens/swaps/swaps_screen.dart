import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/friend_entity.dart';
import '../../../domain/entities/friend_request_entity.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/user_avatar.dart';
import 'add_friend_screen.dart';
import 'friend_detail_screen.dart';
import 'message_swap_screen.dart';

class SwapsScreen extends ConsumerWidget {
  const SwapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendCodeAsync = ref.watch(friendCodeProvider);
    final requestsAsync = ref.watch(incomingFriendRequestsProvider);
    final friendsAsync = ref.watch(friendsProvider);

    final requests = requestsAsync.valueOrNull ?? [];
    final friends = friendsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Amigos'),
            friendCodeAsync.when(
              data: (code) => _FriendCodeChip(code: code),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessageSwapScreen()),
            ),
            icon: const Icon(Icons.swap_horiz_outlined),
            tooltip: 'Intercambio por mensaje',
          ),
          const SizedBox(width: AppConstants.spacingS),
        ],
      ),
      body: (requests.isEmpty && friends.isEmpty)
          ? _EmptyState(onAddTap: () => _openAdd(context))
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              children: [
                if (requests.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Solicitudes pendientes',
                    count: requests.length,
                  ),
                  ...requests.map((r) => _RequestCard(request: r)),
                  const SizedBox(height: AppConstants.spacingL),
                ],
                if (friends.isNotEmpty) ...[
                  _SectionTitle(title: 'Mis amigos', count: friends.length),
                  ...friends.map(
                    (f) => _FriendCard(
                      friend: f,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FriendDetailScreen(friend: f),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Agregar amigo'),
      ),
    );
  }

  void _openAdd(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddFriendScreen()),
      );
}

// ── Friend code chip ───────────────────────────────────────────────────────

class _FriendCodeChip extends StatelessWidget {
  final String code;
  const _FriendCodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary;
    final fgColor = isDark ? AppColors.primary : AppColors.white;
    final borderColor = isDark
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.primaryDark;

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código copiado al portapapeles'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 12, color: fgColor),
            const SizedBox(width: 3),
            Text(
              code,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fgColor,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending request card ───────────────────────────────────────────────────

class _RequestCard extends ConsumerStatefulWidget {
  final FriendRequestEntity request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _loading = false;

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.read(friendActionsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            UserAvatar(name: widget.request.senderName, size: 40),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.request.senderName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const Text('quiere ser tu amigo',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (_loading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              IconButton(
                onPressed: () => _act(() => actions.rejectRequest(widget.request.id)),
                icon: const Icon(Icons.close, color: AppColors.error),
                tooltip: 'Rechazar',
              ),
              IconButton(
                onPressed: () => _act(() async {
                  await actions.acceptRequest(
                    widget.request.id,
                    widget.request.senderId,
                  );
                  AdService.showInterstitial(onComplete: () {});
                }),
                icon: const Icon(Icons.check, color: AppColors.success),
                tooltip: 'Aceptar',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Friend card ────────────────────────────────────────────────────────────

class _FriendCard extends ConsumerStatefulWidget {
  final FriendEntity friend;
  final VoidCallback onTap;
  const _FriendCard({required this.friend, required this.onTap});

  @override
  ConsumerState<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends ConsumerState<_FriendCard> {
  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar amigo'),
        content:
            Text('¿Querés eliminar a ${widget.friend.name} de tus amigos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(friendActionsProvider)
          .removeFriend(widget.friend.userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              UserAvatar(name: widget.friend.name, size: 44),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.friend.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                      widget.friend.friendCode,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmRemove(context),
                icon: const Icon(Icons.person_remove_outlined,
                    color: AppColors.textDisabled, size: 20),
                tooltip: 'Eliminar amigo',
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤝', style: TextStyle(fontSize: 72)),
          const SizedBox(height: AppConstants.spacingL),
          Text('Agregá amigos',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'Compartí tu código con amigos y mirá en tiempo real qué figuritas les faltan y cuáles tienen repetidas.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingXXL),
          AppButton(
            label: 'Agregar amigo',
            onPressed: onAddTap,
          ),
        ],
      ),
    );
  }
}
