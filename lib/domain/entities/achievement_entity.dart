import 'album_stats_entity.dart';

enum AchievementCategory { collection, group, swap, special }

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final bool Function(AchievementContext ctx) check;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.check,
  });
}

class AchievementContext {
  final AlbumStatsEntity stats;
  final int groupCount;
  final int completedSwaps;
  final int duplicatesShared;

  const AchievementContext({
    required this.stats,
    required this.groupCount,
    required this.completedSwaps,
    required this.duplicatesShared,
  });
}

class AchievementEntity {
  final String id;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementEntity({
    required this.id,
    required this.unlocked,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementEntity.fromMap(Map<String, dynamic> map) =>
      AchievementEntity(
        id: map['id'] as String,
        unlocked: map['unlocked'] as bool? ?? false,
        unlockedAt: map['unlockedAt'] != null
            ? DateTime.tryParse(map['unlockedAt'] as String)
            : null,
      );
}

// All achievement definitions — static catalog
class AchievementDefs {
  static final all = <AchievementDef>[
    // Collection
    AchievementDef(
      id: 'first_sticker',
      title: 'Primera figurita',
      description: 'Registrá tu primera figurita en el álbum.',
      emoji: '⭐',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.owned >= 1,
    ),
    AchievementDef(
      id: 'quarter_album',
      title: '25% completado',
      description: 'Conseguí el 25% de las figuritas del álbum.',
      emoji: '🥉',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.percentage >= 0.25,
    ),
    AchievementDef(
      id: 'half_album',
      title: 'Mitad del camino',
      description: 'Conseguí el 50% de las figuritas del álbum.',
      emoji: '🥈',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.percentage >= 0.50,
    ),
    AchievementDef(
      id: 'three_quarters',
      title: 'Casi completo',
      description: 'Conseguí el 75% de las figuritas del álbum.',
      emoji: '🥇',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.percentage >= 0.75,
    ),
    AchievementDef(
      id: 'full_album',
      title: 'Álbum completo',
      description: '¡Completaste el álbum del Mundial 2026!',
      emoji: '🏆',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.percentage >= 1.0,
    ),
    AchievementDef(
      id: 'shiny_hunter',
      title: 'Cazador de shiny',
      description: 'Conseguí 10 figuritas shiny.',
      emoji: '✨',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.shinyOwned >= 10,
    ),
    AchievementDef(
      id: 'all_shiny',
      title: 'Coleccionista shiny',
      description: 'Completá todas las figuritas shiny.',
      emoji: '💎',
      category: AchievementCategory.collection,
      check: (ctx) =>
          ctx.stats.shinyTotal > 0 && ctx.stats.shinyOwned >= ctx.stats.shinyTotal,
    ),
    AchievementDef(
      id: 'duplicate_holder',
      title: 'Guardador de repetidas',
      description: 'Acumulá 20 figuritas repetidas.',
      emoji: '📦',
      category: AchievementCategory.collection,
      check: (ctx) => ctx.stats.duplicates >= 20,
    ),
    // Group
    AchievementDef(
      id: 'first_group',
      title: 'El primero del grupo',
      description: 'Unite o creá tu primer grupo familiar.',
      emoji: '👨‍👩‍👧',
      category: AchievementCategory.group,
      check: (ctx) => ctx.groupCount >= 1,
    ),
    AchievementDef(
      id: 'share_duplicates',
      title: 'Generoso',
      description: 'Compartí 5 figuritas repetidas con tu grupo.',
      emoji: '🤝',
      category: AchievementCategory.group,
      check: (ctx) => ctx.duplicatesShared >= 5,
    ),
    AchievementDef(
      id: 'share_many',
      title: 'El que reparte',
      description: 'Compartí 20 figuritas repetidas en total.',
      emoji: '🎁',
      category: AchievementCategory.group,
      check: (ctx) => ctx.duplicatesShared >= 20,
    ),
    // Swap
    AchievementDef(
      id: 'first_swap',
      title: 'Primer intercambio',
      description: 'Completá tu primer intercambio externo.',
      emoji: '🔄',
      category: AchievementCategory.swap,
      check: (ctx) => ctx.completedSwaps >= 1,
    ),
    AchievementDef(
      id: 'five_swaps',
      title: 'Intercambiador activo',
      description: 'Completá 5 intercambios externos.',
      emoji: '🏅',
      category: AchievementCategory.swap,
      check: (ctx) => ctx.completedSwaps >= 5,
    ),
    // Special
    AchievementDef(
      id: 'early_bird',
      title: 'Primero en llegar',
      description: 'Registrate durante el primer mes del lanzamiento.',
      emoji: '🐣',
      category: AchievementCategory.special,
      check: (_) => false, // granted server-side
    ),
  ];

  static AchievementDef? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
