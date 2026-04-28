import 'sticker_entity.dart';

class TeamEntity {
  final String code; // e.g. "ARG"
  final String name; // e.g. "Argentina"
  final String? flagUrl;
  final List<StickerEntity> stickers;

  const TeamEntity({
    required this.code,
    required this.name,
    this.flagUrl,
    required this.stickers,
  });
}
