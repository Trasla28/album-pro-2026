import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingXL),
            UserAvatar(
              name: user?.name ?? '',
              imageUrl: user?.avatarUrl,
              size: 88,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              user?.name ?? '',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingXL),
            _MenuTile(
              icon: Icons.emoji_events_outlined,
              label: 'Mis logros',
              onTap: () => context.push('/home/achievements'),
            ),
            _MenuTile(
              icon: Icons.notifications_outlined,
              label: 'Preferencias de notificación',
              onTap: () => context.push('/home/notification-prefs'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      await ref.read(authStateProvider.notifier).signOut();
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
