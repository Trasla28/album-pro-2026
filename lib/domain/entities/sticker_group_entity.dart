import 'team_entity.dart';

class StickerGroupEntity {
  final String id; // "INTRO", "A"–"L", "EXTRAS"
  final String name; // "Introducción", "Grupo A", "Extras"
  final List<TeamEntity> teams;

  const StickerGroupEntity({
    required this.id,
    required this.name,
    required this.teams,
  });
}
