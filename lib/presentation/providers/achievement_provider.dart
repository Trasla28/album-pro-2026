import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../domain/entities/achievement_entity.dart';
import 'album_provider.dart';
import 'auth_provider.dart';

// Stream of already-saved achievements from Firestore
final savedAchievementsProvider =
    StreamProvider.autoDispose<List<AchievementEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return ref.read(achievementRepositoryProvider).watchAchievements(user.id);
});

// Derived: map of id -> AchievementEntity for fast lookup
final achievementMapProvider =
    Provider.autoDispose<Map<String, AchievementEntity>>((ref) {
  final list = ref.watch(savedAchievementsProvider).valueOrNull ?? [];
  return {for (final a in list) a.id: a};
});

// Context built from current album + group state (groupCount/swaps use mock values
// until a full backend integration is wired up in a later sprint).
final achievementContextProvider = Provider.autoDispose<AchievementContext>((ref) {
  final stats = ref.watch(albumProvider).stats;
  return AchievementContext(
    stats: stats,
    groupCount: 0,
    completedSwaps: 0,
    duplicatesShared: 0,
  );
});

// IDs of achievements newly unlocked this session (not yet shown as dialog)
final newlyUnlockedProvider =
    StateProvider.autoDispose<List<String>>((ref) => []);

// Checks all achievements against current context and unlocks new ones in Firestore
class AchievementActions {
  final Ref _ref;
  AchievementActions(this._ref);

  Future<List<String>> checkAndUnlock() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return [];

    final repo = _ref.read(achievementRepositoryProvider);
    final savedMap = _ref.read(achievementMapProvider);
    final ctx = _ref.read(achievementContextProvider);
    final newIds = <String>[];

    for (final def in AchievementDefs.all) {
      final alreadyUnlocked = savedMap[def.id]?.unlocked ?? false;
      if (!alreadyUnlocked && def.check(ctx)) {
        await repo.unlock(user.id, def.id);
        newIds.add(def.id);
      }
    }

    if (newIds.isNotEmpty) {
      _ref.read(newlyUnlockedProvider.notifier).state = newIds;
    }
    return newIds;
  }

  void clearNewlyUnlocked() {
    _ref.read(newlyUnlockedProvider.notifier).state = [];
  }
}

final achievementActionsProvider =
    Provider.autoDispose<AchievementActions>((ref) => AchievementActions(ref));
