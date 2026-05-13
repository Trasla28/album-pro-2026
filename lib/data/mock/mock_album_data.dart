import '../../core/enums/album_enums.dart';
import '../../domain/entities/sticker_entity.dart';
import '../../domain/entities/sticker_group_entity.dart';
import '../../domain/entities/team_entity.dart';

class MockAlbumData {
  MockAlbumData._();

  // (groupId, teamCode, teamName) — Mundial 2026 official groups
  static const _teams = [
    // Grupo A
    ('A', 'MEX', 'México'),
    ('A', 'RSA', 'Sudáfrica'),
    ('A', 'KOR', 'Corea del Sur'),
    ('A', 'CZE', 'República Checa'),

    // Grupo B
    ('B', 'CAN', 'Canadá'),
    ('B', 'BIH', 'Bosnia y Herzegovina'),
    ('B', 'QAT', 'Catar'),
    ('B', 'SUI', 'Suiza'),

    // Grupo C
    ('C', 'BRA', 'Brasil'),
    ('C', 'MAR', 'Marruecos'),
    ('C', 'HAI', 'Haití'),
    ('C', 'SCO', 'Escocia'),

    // Grupo D
    ('D', 'USA', 'Estados Unidos'),
    ('D', 'PAR', 'Paraguay'),
    ('D', 'AUS', 'Australia'),
    ('D', 'TUR', 'Turquía'),

    // Grupo E
    ('E', 'GER', 'Alemania'),
    ('E', 'CUW', 'Curazao'),
    ('E', 'CIV', 'Costa de Marfil'),
    ('E', 'ECU', 'Ecuador'),

    // Grupo F
    ('F', 'NED', 'Países Bajos'),
    ('F', 'JPN', 'Japón'),
    ('F', 'SWE', 'Suecia'),
    ('F', 'TUN', 'Túnez'),

    // Grupo G
    ('G', 'BEL', 'Bélgica'),
    ('G', 'EGY', 'Egipto'),
    ('G', 'IRN', 'Irán'),
    ('G', 'NZL', 'Nueva Zelanda'),

    // Grupo H
    ('H', 'ESP', 'España'),
    ('H', 'CPV', 'Cabo Verde'),
    ('H', 'KSA', 'Arabia Saudita'),
    ('H', 'URU', 'Uruguay'),

    // Grupo I
    ('I', 'FRA', 'Francia'),
    ('I', 'SEN', 'Senegal'),
    ('I', 'IRQ', 'Irak'),
    ('I', 'NOR', 'Noruega'),

    // Grupo J
    ('J', 'ARG', 'Argentina'),
    ('J', 'ALG', 'Argelia'),
    ('J', 'AUT', 'Austria'),
    ('J', 'JOR', 'Jordania'),

    // Grupo K
    ('K', 'POR', 'Portugal'),
    ('K', 'COD', 'RD del Congo'),
    ('K', 'UZB', 'Uzbekistán'),
    ('K', 'COL', 'Colombia'),

    // Grupo L
    ('L', 'ENG', 'Inglaterra'),
    ('L', 'CRO', 'Croacia'),
    ('L', 'GHA', 'Ghana'),
    ('L', 'PAN', 'Panamá'),
  ];

  static List<StickerGroupEntity> generate() {
    final groups = <StickerGroupEntity>[];
    groups.add(_buildIntroGroup());
    groups.addAll(_buildMainGroups());
    groups.add(_buildCocaColaGroup());
    groups.add(_buildExtrasGroup());
    return groups;
  }

  static StickerGroupEntity _buildIntroGroup() {
    const introData = [
      (0, 'FWC', 'FWC 0', 'Portada'),
      (1, 'FWC', 'FIFA WC 1', 'Escudo FIFA'),
      (2, 'FWC', 'FIFA WC 2', 'Trofeo Copa del Mundo'),
      (3, 'FWC', 'FIFA WC 3', 'Logo United 2026 USA'),
      (4, 'FWC', 'FIFA WC 4', 'Logo United 2026 México'),
      (5, 'FWC', 'FIFA WC 5', 'Logo United 2026 Canadá'),
      (6, 'FWC', 'FIFA WC 6', 'Mascota Oficial'),
      (7, 'FWC', 'FIFA WC 7', 'MetLife Stadium'),
      (8, 'FWC', 'FIFA WC 8', 'SoFi Stadium'),
      (9, 'FWC', 'FIFA WC 9', 'AT&T Stadium'),
      (10, 'FWC', 'FIFA WC 10', 'NRG Stadium'),
      (11, 'FWC', 'FIFA WC 11', 'Arrowhead Stadium'),
      (12, 'FWC', 'FIFA WC 12', 'Levi\'s Stadium'),
      (13, 'FWC', 'FIFA WC 13', 'Rose Bowl'),
      (14, 'FWC', 'FIFA WC 14', 'Lincoln Financial Field'),
      (15, 'FWC', 'FIFA WC 15', 'Gillette Stadium'),
      (16, 'FWC', 'FIFA WC 16', 'BC Place Vancouver'),
      (17, 'FWC', 'FIFA WC 17', 'BMO Field Toronto'),
      (18, 'FWC', 'FIFA WC 18', 'Estadio Azteca'),
      (19, 'FWC', 'FIFA WC 19', 'Estadio BBVA'),
    ];
    final stickers = introData
        .map(
          (d) => StickerEntity(
            globalNumber: d.$1,
            teamCode: d.$2,
            teamPosition: d.$3,
            playerName: d.$4,
            type: StickerType.shiny,
          ),
        )
        .toList();
    return StickerGroupEntity(
      id: 'INTRO',
      name: 'FIFA World Cup',
      teams: [
        TeamEntity(code: 'FWC', name: 'FIFA World Cup', stickers: stickers),
      ],
    );
  }

  static List<StickerGroupEntity> _buildMainGroups() {
    int globalCounter = 21;
    final groupMap = <String, List<TeamEntity>>{};

    for (final (groupId, code, name) in _teams) {
      final stickers = <StickerEntity>[];

      // [CODE] 1 — Escudo de la Federación (shiny)
      stickers.add(
        StickerEntity(
          globalNumber: globalCounter++,
          teamCode: code,
          teamPosition: '$code 1',
          playerName: 'Escudo $name',
          type: StickerType.shiny,
        ),
      );

      // [CODE] 2-12 — Jugadores (portero, defensas, mediocampistas)
      for (int pos = 2; pos <= 12; pos++) {
        stickers.add(
          StickerEntity(
            globalNumber: globalCounter++,
            teamCode: code,
            teamPosition: '$code $pos',
            playerName: 'Jugador $code $pos',
            type: StickerType.standard,
          ),
        );
      }

      // [CODE] 13 — Foto del equipo completo (shiny)
      stickers.add(
        StickerEntity(
          globalNumber: globalCounter++,
          teamCode: code,
          teamPosition: '$code 13',
          playerName: 'Foto Equipo $name',
          type: StickerType.shiny,
        ),
      );

      // [CODE] 14-20 — Jugadores (delanteros y suplentes)
      for (int pos = 14; pos <= 20; pos++) {
        stickers.add(
          StickerEntity(
            globalNumber: globalCounter++,
            teamCode: code,
            teamPosition: '$code $pos',
            playerName: 'Jugador $code $pos',
            type: StickerType.standard,
          ),
        );
      }

      groupMap.putIfAbsent(groupId, () => []);
      groupMap[groupId]!.add(
        TeamEntity(code: code, name: name, stickers: stickers),
      );
    }

    return ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L']
        .map(
          (id) => StickerGroupEntity(
            id: id,
            name: 'Grupo $id',
            teams: groupMap[id]!,
          ),
        )
        .toList();
  }

  static StickerGroupEntity _buildCocaColaGroup() {
    final stickers = <StickerEntity>[];
    for (int i = 1; i <= 14; i++) {
      stickers.add(
        StickerEntity(
          globalNumber: 980 + i,
          teamCode: 'COC',
          teamPosition: 'COC $i',
          playerName: 'COC $i',
          type: StickerType.shiny,
        ),
      );
    }
    return StickerGroupEntity(
      id: 'COC',
      name: 'Coca-Cola',
      teams: [TeamEntity(code: 'COC', name: 'Coca-Cola', stickers: stickers)],
    );
  }

  static StickerGroupEntity _buildExtrasGroup() {
    int extraCounter = 995;
    final stickers = <StickerEntity>[];
    for (final rarity in StickerRarity.values) {
      for (int i = 1; i <= 3; i++) {
        stickers.add(
          StickerEntity(
            globalNumber: extraCounter++,
            teamCode: 'EXT',
            teamPosition: 'EXT ${extraCounter - 995}',
            playerName:
                'Extra ${rarity.name[0].toUpperCase()}${rarity.name.substring(1)} $i',
            type: StickerType.extra,
            rarity: rarity,
          ),
        );
      }
    }
    return StickerGroupEntity(
      id: 'EXTRAS',
      name: 'Extras',
      teams: [
        TeamEntity(code: 'EXT', name: 'Extra Stickers', stickers: stickers),
      ],
    );
  }
}
