import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/album_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/sticker_entity.dart';
import '../../providers/album_provider.dart';
import '../../widgets/app_button.dart';

void showStickerDetail(BuildContext context, StickerEntity sticker) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StickerDetailSheet(sticker: sticker),
  );
}

class _StickerDetailSheet extends ConsumerWidget {
  final StickerEntity sticker;

  const _StickerDetailSheet({required this.sticker});

  static const _rarityColors = {
    StickerRarity.base: Color(0xFF8B7355),
    StickerRarity.bronze: Color(0xFFCD7F32),
    StickerRarity.silver: Color(0xFF9E9E9E),
    StickerRarity.gold: Color(0xFFFFD700),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(albumProvider).quantities[sticker.globalNumber] ?? 0;
    final status = quantity.stickerStatus;
    final notifier = ref.read(albumProvider.notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingL,
        AppConstants.spacingM,
        AppConstants.spacingL,
        AppConstants.spacingL + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle,
          const SizedBox(height: AppConstants.spacingM),
          _typeChip,
          const SizedBox(height: AppConstants.spacingM),
          _stickerPreview(status),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            sticker.playerName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingS),
          _infoRow(context),
          const SizedBox(height: AppConstants.spacingL),
          _quantityControls(context, quantity, notifier),
          const SizedBox(height: AppConstants.spacingM),
          AppButton(
            label: status == StickerStatus.missing ? 'Marcar como conseguida' : 'Desmarcar',
            variant: status == StickerStatus.missing
                ? AppButtonVariant.primary
                : AppButtonVariant.outlined,
            onPressed: () {
              notifier.toggleOwned(sticker.globalNumber);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget get _handle => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget get _typeChip {
    final (label, color) = switch (sticker.type) {
      StickerType.standard => ('Estándar', AppColors.info),
      StickerType.shiny => ('✦ Shiny', AppColors.accent),
      StickerType.extra => ('Extra ${sticker.rarity?.name ?? ''}', _rarityColors[sticker.rarity] ?? AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _stickerPreview(StickerStatus status) {
    final bgColor = switch (status) {
      StickerStatus.missing => AppColors.stickerMissing,
      StickerStatus.owned => AppColors.stickerOwned,
      StickerStatus.duplicate => AppColors.stickerDuplicate,
    };
    return Container(
      width: 100,
      height: 130,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sticker.type == StickerType.shiny ? AppColors.accent : AppColors.divider,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (sticker.type == StickerType.shiny)
            const Text('✦', style: TextStyle(fontSize: 24, color: AppColors.accent)),
          Text(
            sticker.teamPosition.split(' ').last,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white),
          ),
          Text(
            sticker.teamCode,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _InfoChip(label: '# Global', value: '${sticker.globalNumber}'),
          const SizedBox(width: 8),
          _InfoChip(label: 'Posición', value: sticker.teamPosition),
        ],
      );

  Widget _quantityControls(BuildContext context, int quantity, AlbumNotifier notifier) {
    if (quantity == 0) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Cantidad: ', style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => notifier.removeDuplicate(sticker.globalNumber),
          color: AppColors.error,
        ),
        Text(
          '$quantity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => notifier.addDuplicate(sticker.globalNumber),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
