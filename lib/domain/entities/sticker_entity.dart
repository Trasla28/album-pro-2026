import '../../core/enums/album_enums.dart';

class StickerEntity {
  final int globalNumber;
  final String teamCode;
  final String teamPosition; // e.g. "ARG 10"
  final String playerName;
  final StickerType type;
  final StickerRarity? rarity;
  final String? imageUrl;

  const StickerEntity({
    required this.globalNumber,
    required this.teamCode,
    required this.teamPosition,
    required this.playerName,
    required this.type,
    this.rarity,
    this.imageUrl,
  });
}
