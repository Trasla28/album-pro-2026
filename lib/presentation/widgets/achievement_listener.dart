import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/achievement_entity.dart';
import '../providers/achievement_provider.dart';
import 'achievement_unlock_dialog.dart';

/// Wraps a child widget and shows an AchievementUnlockDialog whenever
/// new achievements are detected in [newlyUnlockedProvider].
class AchievementListener extends ConsumerStatefulWidget {
  final Widget child;

  const AchievementListener({super.key, required this.child});

  @override
  ConsumerState<AchievementListener> createState() =>
      _AchievementListenerState();
}

class _AchievementListenerState extends ConsumerState<AchievementListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runCheck();
    });
  }

  Future<void> _runCheck() async {
    final ids = await ref.read(achievementActionsProvider).checkAndUnlock();
    if (!mounted || ids.isEmpty) return;
    for (final id in ids) {
      final def = AchievementDefs.byId(id);
      if (def == null) continue;
      await AchievementUnlockDialog.show(context, def);
    }
    ref.read(achievementActionsProvider).clearNewlyUnlocked();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
