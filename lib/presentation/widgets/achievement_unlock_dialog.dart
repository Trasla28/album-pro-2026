import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/achievement_entity.dart';

class AchievementUnlockDialog extends ConsumerStatefulWidget {
  final AchievementDef def;

  const AchievementUnlockDialog({super.key, required this.def});

  static Future<void> show(BuildContext context, AchievementDef def) =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AchievementUnlockDialog(def: def),
      );

  @override
  ConsumerState<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState
    extends ConsumerState<AchievementUnlockDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(def.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                '¡Logro desbloqueado!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                def.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                def.description,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(ShareParams(
                          text:
                              '${def.emoji} Desbloqueé el logro "${def.title}" en AlbumPro 2026!',
                        ));
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Compartir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          colors: const [
            AppColors.primary,
            AppColors.accent,
            AppColors.success,
            AppColors.warning,
          ],
        ),
      ],
    );
  }
}
