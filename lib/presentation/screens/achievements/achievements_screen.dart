import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/achievement_entity.dart';
import '../../providers/achievement_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedMap = ref.watch(achievementMapProvider);
    final defs = AchievementDefs.all;

    final unlocked = defs.where((d) => savedMap[d.id]?.unlocked == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '$unlocked/${defs.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressHeader(unlocked: unlocked, total: defs.length),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: defs.length,
              itemBuilder: (_, i) {
                final def = defs[i];
                final entity = savedMap[def.id];
                final isUnlocked = entity?.unlocked ?? false;
                return _AchievementTile(
                  def: def,
                  isUnlocked: isUnlocked,
                  unlockedAt: entity?.unlockedAt,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _ProgressHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unlocked de $total logros desbloqueados',
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.def,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.divider,
            width: isUnlocked ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  def.emoji,
                  style: TextStyle(
                    fontSize: 36,
                    color: isUnlocked ? null : Colors.transparent,
                  ),
                ),
                if (!isUnlocked)
                  const Icon(Icons.lock_outline,
                      size: 36, color: AppColors.textDisabled),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              def.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    isUnlocked ? AppColors.textPrimary : AppColors.textDisabled,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(unlockedAt!),
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AchievementDetailSheet(
        def: def,
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAt,
      ),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementDetailSheet({
    required this.def,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isUnlocked ? def.emoji : '🔒',
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 12),
          Text(def.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            def.description,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isUnlocked
                  ? (unlockedAt != null
                      ? 'Desbloqueado el ${unlockedAt!.day}/${unlockedAt!.month}/${unlockedAt!.year}'
                      : 'Desbloqueado')
                  : 'Bloqueado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppColors.success : AppColors.textDisabled,
              ),
            ),
          ),
          if (isUnlocked) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  SharePlus.instance.share(ShareParams(
                    text:
                        '${def.emoji} Desbloqueé el logro "${def.title}" en AlbumPro 2026!',
                  ));
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Compartir logro'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
