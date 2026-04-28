import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/album_enums.dart';
import '../../data/repositories/album_repository.dart';
import '../../data/repositories/friendship_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/entities/album_stats_entity.dart';
import '../../domain/entities/sticker_entity.dart';
import '../../domain/entities/sticker_group_entity.dart';
import '../../domain/entities/team_entity.dart';
import 'group_provider.dart';

class AlbumState {
  final List<StickerGroupEntity> groups;
  final Map<int, int> quantities;
  final AlbumFilter filter;
  final AlbumStatsEntity stats;
  final bool isLoading;
  final String? error;

  const AlbumState({
    required this.groups,
    required this.quantities,
    required this.filter,
    required this.stats,
    this.isLoading = false,
    this.error,
  });

  AlbumState copyWith({
    List<StickerGroupEntity>? groups,
    Map<int, int>? quantities,
    AlbumFilter? filter,
    AlbumStatsEntity? stats,
    bool? isLoading,
    String? error,
  }) =>
      AlbumState(
        groups: groups ?? this.groups,
        quantities: quantities ?? this.quantities,
        filter: filter ?? this.filter,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  List<StickerGroupEntity> get filteredGroups {
    if (filter == AlbumFilter.extra) {
      return groups.where((g) => g.id == 'EXTRAS').toList();
    }
    return groups
        .where((g) => g.id != 'EXTRAS')
        .map((group) {
          final filteredTeams = group.teams
              .map((team) {
                final stickers = _filterStickers(team.stickers);
                return stickers.isEmpty
                    ? null
                    : TeamEntity(
                        code: team.code,
                        name: team.name,
                        flagUrl: team.flagUrl,
                        stickers: stickers);
              })
              .whereType<TeamEntity>()
              .toList();
          return filteredTeams.isEmpty
              ? null
              : StickerGroupEntity(
                  id: group.id, name: group.name, teams: filteredTeams);
        })
        .whereType<StickerGroupEntity>()
        .toList();
  }

  List<StickerEntity> _filterStickers(List<StickerEntity> stickers) {
    if (filter == AlbumFilter.all) {
      return stickers.where((s) => s.type != StickerType.extra).toList();
    }
    return stickers.where((s) {
      final qty = quantities[s.globalNumber] ?? 0;
      return switch (filter) {
        AlbumFilter.owned => qty >= 1,
        AlbumFilter.missing => qty == 0,
        AlbumFilter.duplicate => qty >= 2,
        AlbumFilter.shiny => s.type == StickerType.shiny,
        AlbumFilter.extra => s.type == StickerType.extra,
        AlbumFilter.all => true,
      };
    }).toList();
  }

  List<StickerEntity> get allStickers =>
      groups.expand((g) => g.teams.expand((t) => t.stickers)).toList();
}

class AlbumNotifier extends Notifier<AlbumState> {
  @override
  AlbumState build() {
    final repo = ref.read(albumRepositoryProvider);
    final groups = repo.getAlbumStructure();
    final quantities = repo.getQuantities();
    final stats = repo.computeStats(groups, quantities);

    // When the active group's shared quantities change, update state in real time.
    ref.listen<AsyncValue<Map<int, int>?>>(
      currentGroupQuantitiesProvider,
      (_, next) {
        next.whenOrNull(
          data: (qty) {
            final effective = qty ?? ref.read(albumRepositoryProvider).getQuantities();
            final newStats =
                ref.read(albumRepositoryProvider).computeStats(state.groups, effective);
            state = state.copyWith(quantities: effective, stats: newStats);
          },
        );
      },
    );

    return AlbumState(
      groups: groups,
      quantities: quantities,
      filter: AlbumFilter.all,
      stats: stats,
    );
  }

  void setFilter(AlbumFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> setQuantity(int globalNumber, int quantity) async {
    // Optimistic local update for instant UI feedback.
    final newQty = Map<int, int>.from(state.quantities);
    if (quantity <= 0) {
      newQty.remove(globalNumber);
    } else {
      newQty[globalNumber] = quantity;
    }
    final repo = ref.read(albumRepositoryProvider);
    state = state.copyWith(
      quantities: newQty,
      stats: repo.computeStats(state.groups, newQty),
    );

    // Persist: group Firestore or personal Hive.
    final groupId = ref.read(currentGroupIdProvider).valueOrNull;
    if (groupId != null) {
      await ref
          .read(groupRepositoryProvider)
          .setGroupQuantity(groupId, globalNumber, quantity);
    } else {
      await repo.setQuantity(globalNumber, quantity);
    }

    // Sync to user_quantities so friends see real-time updates.
    ref
        .read(friendshipRepositoryProvider)
        .syncQuantity(globalNumber, quantity)
        .ignore();
  }

  /// Full sync to Firestore — call after joining or leaving a group.
  Future<void> syncAll() async {
    await ref
        .read(friendshipRepositoryProvider)
        .syncAllQuantities(state.quantities);
  }

  Future<void> toggleOwned(int globalNumber) async {
    final current = state.quantities[globalNumber] ?? 0;
    await setQuantity(globalNumber, current == 0 ? 1 : 0);
  }

  Future<void> addDuplicate(int globalNumber) async {
    final current = state.quantities[globalNumber] ?? 0;
    if (current == 0) return;
    await setQuantity(globalNumber, current + 1);
  }

  Future<void> removeDuplicate(int globalNumber) async {
    final current = state.quantities[globalNumber] ?? 0;
    if (current <= 0) return;
    await setQuantity(globalNumber, current - 1);
  }
}

final albumProvider =
    NotifierProvider<AlbumNotifier, AlbumState>(AlbumNotifier.new);
