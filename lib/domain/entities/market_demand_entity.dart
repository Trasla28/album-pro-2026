import 'sticker_entity.dart';

enum DemandLevel { low, medium, high, veryHigh }

class MarketDemandEntity {
  final StickerEntity sticker;
  final DemandLevel demandLevel;
  final int demandScore; // 0–100
  final String reason;

  const MarketDemandEntity({
    required this.sticker,
    required this.demandLevel,
    required this.demandScore,
    required this.reason,
  });
}

extension DemandLevelExt on DemandLevel {
  String get label {
    return switch (this) {
      DemandLevel.low => 'Baja',
      DemandLevel.medium => 'Media',
      DemandLevel.high => 'Alta',
      DemandLevel.veryHigh => 'Muy alta',
    };
  }

  String get emoji {
    return switch (this) {
      DemandLevel.low => '🟢',
      DemandLevel.medium => '🟡',
      DemandLevel.high => '🟠',
      DemandLevel.veryHigh => '🔴',
    };
  }
}
