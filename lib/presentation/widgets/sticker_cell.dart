import 'package:flutter/material.dart';
import '../../core/enums/album_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/sticker_entity.dart';

class StickerCell extends StatelessWidget {
  final StickerEntity sticker;
  final int quantity;
  final VoidCallback onTap;

  const StickerCell({
    super.key,
    required this.sticker,
    required this.quantity,
    required this.onTap,
  });

  StickerStatus get _status => quantity.stickerStatus;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _borderColor,
            width: sticker.type == StickerType.shiny ? 1.5 : 1,
          ),
          gradient: _gradient,
        ),
        child: Stack(
          children: [
            Center(child: _content),
            if (_status == StickerStatus.duplicate) _duplicateBadge,
            if (sticker.type == StickerType.shiny) _shinyIndicator,
          ],
        ),
      ),
    );
  }

  Widget get _content {
    if (sticker.type == StickerType.extra) {
      return _ExtraContent(sticker: sticker, status: _status);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (sticker.type == StickerType.shiny && _status == StickerStatus.missing)
          const Text('✦', style: TextStyle(fontSize: 12, color: AppColors.accentDark)),
        Text(
          sticker.teamPosition.split(' ').last, // just the number
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        Text(
          sticker.teamCode,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: _textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget get _duplicateBadge => Positioned(
        top: 2,
        right: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.warning,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '×$quantity',
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: AppColors.white),
          ),
        ),
      );

  Widget get _shinyIndicator => const Positioned(
        bottom: 2,
        right: 2,
        child: Text('✦', style: TextStyle(fontSize: 7, color: AppColors.accent)),
      );

  Color get _bgColor {
    if (sticker.type == StickerType.shiny) {
      return switch (_status) {
        StickerStatus.missing => const Color(0xFFF8F5E8),
        StickerStatus.owned || StickerStatus.duplicate => const Color(0xFFFFF8E1),
      };
    }
    return switch (_status) {
      StickerStatus.missing => AppColors.stickerMissing,
      StickerStatus.owned => AppColors.stickerOwned,
      StickerStatus.duplicate => AppColors.stickerDuplicate,
    };
  }

  Color get _borderColor {
    if (sticker.type == StickerType.shiny) return AppColors.accent;
    return switch (_status) {
      StickerStatus.missing => AppColors.divider,
      StickerStatus.owned => AppColors.success,
      StickerStatus.duplicate => AppColors.warning,
    };
  }

  Gradient? get _gradient {
    if (sticker.type == StickerType.shiny && _status != StickerStatus.missing) {
      return const LinearGradient(
        colors: [Color(0xFFFFF8DC), Color(0xFFFFD700), Color(0xFFFFF8DC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return null;
  }

  Color get _textColor {
    if (sticker.type == StickerType.shiny) return AppColors.accentDark;
    return switch (_status) {
      StickerStatus.missing => AppColors.textDisabled,
      StickerStatus.owned || StickerStatus.duplicate => AppColors.white,
    };
  }
}

class _ExtraContent extends StatelessWidget {
  final StickerEntity sticker;
  final StickerStatus status;

  const _ExtraContent({required this.sticker, required this.status});

  static const _rarityColors = {
    StickerRarity.base: Color(0xFF8B7355),
    StickerRarity.bronze: Color(0xFFCD7F32),
    StickerRarity.silver: Color(0xFF9E9E9E),
    StickerRarity.gold: Color(0xFFFFD700),
  };

  @override
  Widget build(BuildContext context) {
    final color = _rarityColors[sticker.rarity] ?? AppColors.textSecondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          sticker.rarity?.name.toUpperCase() ?? 'EXT',
          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
