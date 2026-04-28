import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/album_enums.dart';
import '../../domain/entities/album_stats_entity.dart';
import '../../domain/entities/sticker_group_entity.dart';
import '../mock/mock_album_data.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) => AlbumRepository());

class AlbumRepository {
  Box<int> get _box => Hive.box<int>(AppConstants.stickerQuantitiesBox);

  List<StickerGroupEntity> getAlbumStructure() => MockAlbumData.generate();

  Map<int, int> getQuantities() => {
        for (final key in _box.keys) int.parse(key as String): _box.get(key) ?? 0,
      };

  Future<void> setQuantity(int globalNumber, int quantity) async {
    if (quantity <= 0) {
      await _box.delete(globalNumber.toString());
    } else {
      await _box.put(globalNumber.toString(), quantity);
    }
  }

  AlbumStatsEntity computeStats(
    List<StickerGroupEntity> groups,
    Map<int, int> quantities,
  ) {
    int total = 0;
    int owned = 0;
    int duplicates = 0;
    int shinyTotal = 0;
    int shinyOwned = 0;
    int extrasTotal = 0;
    int extrasOwned = 0;

    for (final group in groups) {
      for (final team in group.teams) {
        for (final sticker in team.stickers) {
          final qty = quantities[sticker.globalNumber] ?? 0;

          if (sticker.type == StickerType.extra) {
            extrasTotal++;
            if (qty > 0) extrasOwned++;
            continue;
          }

          total++;
          if (sticker.type == StickerType.shiny) {
            shinyTotal++;
            if (qty > 0) shinyOwned++;
          }
          if (qty > 0) owned++;
          if (qty >= 2) duplicates++;
        }
      }
    }

    return AlbumStatsEntity(
      total: total,
      owned: owned,
      duplicates: duplicates,
      shinyTotal: shinyTotal,
      shinyOwned: shinyOwned,
      extrasTotal: extrasTotal,
      extrasOwned: extrasOwned,
    );
  }
}
