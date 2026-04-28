enum StickerType { standard, shiny, extra }

enum StickerRarity { base, bronze, silver, gold }

enum StickerStatus { missing, owned, duplicate }

enum AlbumFilter { all, owned, missing, duplicate, shiny, extra }

extension StickerStatusExtension on int {
  StickerStatus get stickerStatus {
    if (this == 0) return StickerStatus.missing;
    if (this == 1) return StickerStatus.owned;
    return StickerStatus.duplicate;
  }
}

extension AlbumFilterLabel on AlbumFilter {
  String get label => switch (this) {
        AlbumFilter.all => 'Todos',
        AlbumFilter.owned => 'Conseguidas',
        AlbumFilter.missing => 'Faltantes',
        AlbumFilter.duplicate => 'Repetidas',
        AlbumFilter.shiny => 'Shiny',
        AlbumFilter.extra => 'Extras',
      };
}
