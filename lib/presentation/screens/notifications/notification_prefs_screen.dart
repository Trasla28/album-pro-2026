import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/notification_provider.dart';

class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);
    final prefs = prefsAsync.valueOrNull ?? const NotificationPrefsEntity();
    final actions = ref.read(notificationActionsProvider);

    void toggle(NotificationPrefsEntity updated) =>
        actions.updatePrefs(updated);

    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de notificaciones')),
      body: ListView(
        children: [
          _SectionHeader('Grupo'),
          _PrefTile(
            icon: Icons.style,
            iconColor: AppColors.success,
            title: 'Figurita conseguida',
            subtitle: 'Cuando un miembro del grupo registra una figurita',
            value: prefs.stickerObtained,
            onChanged: (v) => toggle(prefs.copyWith(stickerObtained: v)),
          ),
          _PrefTile(
            icon: Icons.style_outlined,
            iconColor: AppColors.warning,
            title: 'Nueva repetida disponible',
            subtitle: 'Cuando alguien publica una repetida en el grupo',
            value: prefs.duplicateAvailable,
            onChanged: (v) => toggle(prefs.copyWith(duplicateAvailable: v)),
          ),
          _PrefTile(
            icon: Icons.person,
            iconColor: AppColors.warning,
            title: 'Reclamaron tu repetida',
            subtitle: 'Cuando un miembro pide una de tus repetidas',
            value: prefs.duplicateClaimed,
            onChanged: (v) => toggle(prefs.copyWith(duplicateClaimed: v)),
          ),
          _PrefTile(
            icon: Icons.emoji_events,
            iconColor: AppColors.accent,
            title: 'Hito del grupo',
            subtitle: 'Cuando el grupo alcanza 25%, 50%, 75% o 100%',
            value: prefs.groupMilestone,
            onChanged: (v) => toggle(prefs.copyWith(groupMilestone: v)),
          ),
          const Divider(),
          _SectionHeader('Intercambios'),
          _PrefTile(
            icon: Icons.swap_horiz,
            iconColor: AppColors.info,
            title: 'Propuesta recibida',
            subtitle: 'Cuando alguien te propone un intercambio',
            value: prefs.swapProposed,
            onChanged: (v) => toggle(prefs.copyWith(swapProposed: v)),
          ),
          _PrefTile(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            title: 'Propuesta aceptada',
            subtitle: 'Cuando aceptan tu propuesta de intercambio',
            value: prefs.swapAccepted,
            onChanged: (v) => toggle(prefs.copyWith(swapAccepted: v)),
          ),
          const Divider(),
          _SectionHeader('Recordatorios'),
          _PrefTile(
            icon: Icons.access_time,
            iconColor: AppColors.error,
            title: 'Entrega pendiente',
            subtitle: 'Recordatorio a los 3 días de un reclamo sin entregar',
            value: prefs.claimReminder,
            onChanged: (v) => toggle(prefs.copyWith(claimReminder: v)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primaryLight,
    );
  }
}
