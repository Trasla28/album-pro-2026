class AlbumStatsEntity {
  final int total; // 980 (stickers 1-980, excluding extras)
  final int owned;
  final int duplicates;
  final int shinyTotal;
  final int shinyOwned;
  final int extrasTotal;
  final int extrasOwned;

  const AlbumStatsEntity({
    required this.total,
    required this.owned,
    required this.duplicates,
    required this.shinyTotal,
    required this.shinyOwned,
    required this.extrasTotal,
    required this.extrasOwned,
  });

  int get missing => total - owned;
  double get percentage => total > 0 ? owned / total : 0;

  static const AlbumStatsEntity empty = AlbumStatsEntity(
    total: 980,
    owned: 0,
    duplicates: 0,
    shinyTotal: 0,
    shinyOwned: 0,
    extrasTotal: 0,
    extrasOwned: 0,
  );
}
