import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/album_enums.dart';
import '../../domain/entities/market_demand_entity.dart';
import '../../domain/entities/sticker_entity.dart';
import 'album_provider.dart';

// Heuristic demand scoring — no backend needed.
// Score factors: sticker type (shiny/extra = higher), team code (popular teams),
// and whether the user is missing it.
int _scoreFn(StickerEntity s, Map<int, int> quantities) {
  int score = 30; // baseline

  // Type bonus
  if (s.type == StickerType.shiny) score += 40;
  if (s.type == StickerType.extra) score += 20;

  // Popular teams (rough heuristic for big football nations)
  const hotTeams = {
    'ARG', 'BRA', 'FRA', 'ENG', 'ESP', 'GER', 'POR', 'NED', 'ITA', 'BEL'
  };
  if (hotTeams.contains(s.teamCode)) score += 20;

  // High number = harder to find (album structure)
  if (s.globalNumber > 700) score += 10;

  return score.clamp(0, 100);
}

String _reason(StickerEntity s, int score) {
  if (s.type == StickerType.shiny) return 'Figurita shiny — muy buscada';
  if (s.type == StickerType.extra) return 'Figurita extra del álbum';
  if (score >= 70) return 'Equipo popular y difícil de conseguir';
  if (score >= 50) return 'Demanda moderada-alta';
  return 'Demanda normal';
}

DemandLevel _level(int score) {
  if (score >= 75) return DemandLevel.veryHigh;
  if (score >= 55) return DemandLevel.high;
  if (score >= 35) return DemandLevel.medium;
  return DemandLevel.low;
}

// Returns top-N most demanded stickers that the user owns as duplicates (qty >= 2)
final marketDemandProvider =
    Provider.autoDispose<List<MarketDemandEntity>>((ref) {
  final albumState = ref.watch(albumProvider);
  final quantities = albumState.quantities;
  final allStickers = albumState.allStickers;

  final duplicates = allStickers
      .where((s) => (quantities[s.globalNumber] ?? 0) >= 2)
      .toList();

  if (duplicates.isEmpty) return [];

  final demand = duplicates.map((s) {
    final score = _scoreFn(s, quantities);
    return MarketDemandEntity(
      sticker: s,
      demandScore: score,
      demandLevel: _level(score),
      reason: _reason(s, score),
    );
  }).toList()
    ..sort((a, b) => b.demandScore.compareTo(a.demandScore));

  return demand;
});

// All stickers sorted by demand (for the full market view — not limited to duplicates)
final allMarketDemandProvider =
    Provider.autoDispose<List<MarketDemandEntity>>((ref) {
  final albumState = ref.watch(albumProvider);
  final quantities = albumState.quantities;
  final allStickers = albumState.allStickers;

  final demand = allStickers.map((s) {
    final score = _scoreFn(s, quantities);
    return MarketDemandEntity(
      sticker: s,
      demandScore: score,
      demandLevel: _level(score),
      reason: _reason(s, score),
    );
  }).toList()
    ..sort((a, b) => b.demandScore.compareTo(a.demandScore));

  return demand.take(100).toList();
});
