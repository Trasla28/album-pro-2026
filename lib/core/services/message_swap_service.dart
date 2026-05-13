import '../../domain/entities/sticker_entity.dart';
import '../../domain/entities/sticker_group_entity.dart';

class ParsedSwapMessage {
  final Map<String, List<int>> needs; // teamCode → positions they need
  final Map<String, List<int>> swaps; // teamCode → positions they have extra

  const ParsedSwapMessage({required this.needs, required this.swaps});
}

class SwapMatches {
  final List<StickerEntity> iCanGive;   // my repeated + they need
  final List<StickerEntity> theyCanGive; // their repeated + I need

  const SwapMatches({required this.iCanGive, required this.theyCanGive});
}

class MessageSwapService {
  static const _flagEmojis = {
    'MEX': '🇲🇽', 'RSA': '🇿🇦', 'KOR': '🇰🇷', 'CZE': '🇨🇿',
    'CAN': '🇨🇦', 'SUI': '🇨🇭', 'QAT': '🇶🇦', 'BIH': '🇧🇦',
    'BRA': '🇧🇷', 'MAR': '🇲🇦', 'HAI': '🇭🇹', 'ESC': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    'USA': '🇺🇸', 'PAR': '🇵🇾', 'AUS': '🇦🇺', 'TUR': '🇹🇷',
    'GER': '🇩🇪', 'ECU': '🇪🇨', 'CIV': '🇨🇮', 'CUR': '🇨🇼',
    'NED': '🇳🇱', 'JPN': '🇯🇵', 'SWE': '🇸🇪', 'TUN': '🇹🇳',
    'BEL': '🇧🇪', 'EGY': '🇪🇬', 'IRN': '🇮🇷', 'NZL': '🇳🇿',
    'ESP': '🇪🇸', 'URU': '🇺🇾', 'KSA': '🇸🇦', 'CPV': '🇨🇻',
    'FRA': '🇫🇷', 'SEN': '🇸🇳', 'NOR': '🇳🇴', 'IRQ': '🇮🇶',
    'ARG': '🇦🇷', 'AUT': '🇦🇹', 'ALG': '🇩🇿', 'JOR': '🇯🇴',
    'POR': '🇵🇹', 'COL': '🇨🇴', 'UZB': '🇺🇿', 'COD': '🇨🇩',
    'ENG': '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'CRO': '🇭🇷', 'GHA': '🇬🇭', 'PAN': '🇵🇦',
    'FWC': '🏆',
  };

  // Our code → code shown in message (for cross-app compatibility with Figuritas App)
  static const _toDisplay = {'ESC': 'SCO', 'CUR': 'CUW'};

  // Code received in a message → our internal code
  static const _toInternal = {'SCO': 'ESC', 'CUW': 'CUR'};

  static const _skipCodes = {'EXT', 'COC'};

  // ── Generate ──────────────────────────────────────────────────────────────

  String generateMessage(
    List<StickerGroupEntity> groups,
    Map<int, int> quantities,
  ) {
    final needsByTeam = <String, List<int>>{};
    final swapsByTeam = <String, List<int>>{};

    for (final group in groups) {
      for (final team in group.teams) {
        if (_skipCodes.contains(team.code)) continue;
        final needs = <int>[];
        final swaps = <int>[];
        for (final sticker in team.stickers) {
          final qty = quantities[sticker.globalNumber] ?? 0;
          final pos = _positionOf(sticker.teamPosition);
          if (pos == null) continue;
          if (qty == 0) needs.add(pos);
          if (qty >= 2) swaps.add(pos);
        }
        if (needs.isNotEmpty) needsByTeam[team.code] = needs;
        if (swaps.isNotEmpty) swapsByTeam[team.code] = swaps;
      }
    }

    final buf = StringBuffer();
    buf.writeln('Album Mundial 2026 - Lista');
    buf.writeln();

    if (needsByTeam.isNotEmpty) {
      buf.writeln('Necesito:');
      _writeTeamLines(buf, needsByTeam);
    }

    buf.writeln();

    if (swapsByTeam.isNotEmpty) {
      buf.writeln('Tengo de más:');
      _writeTeamLines(buf, swapsByTeam);
    }

    buf.writeln();
    buf.write('Generado con App Album Mundial 2026');
    return buf.toString();
  }

  void _writeTeamLines(StringBuffer buf, Map<String, List<int>> byTeam) {
    for (final e in byTeam.entries) {
      final emoji = _flagEmojis[e.key] ?? '';
      final code = _toDisplay[e.key] ?? e.key;
      buf.writeln('$code $emoji: ${e.value.join(', ')}');
    }
  }

  // ── Parse ─────────────────────────────────────────────────────────────────

  ParsedSwapMessage parseMessage(String text) {
    final needs = <String, List<int>>{};
    final swaps = <String, List<int>>{};
    var section = _Section.unknown;

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();

      if (_isNeedsHeader(lower)) {
        section = _Section.needs;
        continue;
      }
      if (_isSwapsHeader(lower)) {
        section = _Section.swaps;
        continue;
      }
      if (section == _Section.unknown) continue;

      final colonIdx = line.indexOf(':');
      if (colonIdx < 0) continue;

      final codePart = line.substring(0, colonIdx).trim();
      final numPart = line.substring(colonIdx + 1).trim();
      if (numPart.isEmpty) continue;

      // First word before any emoji or whitespace is the team code
      final rawCode = codePart.split(RegExp(r'[\s\u{1F3F4}\u{1F1E0}-\u{1F1FF}]', unicode: true)).first.toUpperCase();
      if (rawCode.isEmpty) continue;

      final teamCode = _toInternal[rawCode] ?? rawCode;

      final positions = numPart
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      if (positions.isEmpty) continue;

      final target = section == _Section.needs ? needs : swaps;
      target.update(teamCode, (l) => l..addAll(positions), ifAbsent: () => positions);
    }

    return ParsedSwapMessage(needs: needs, swaps: swaps);
  }

  bool _isNeedsHeader(String lower) =>
      lower.contains('i need') ||
      lower.contains('necesito') ||
      lower.contains('me faltan') ||
      lower.contains('faltan');

  bool _isSwapsHeader(String lower) =>
      lower.contains('swap') ||
      lower.contains('tengo de más') ||
      lower.contains('tengo de mas') ||
      lower.contains('repetidas') ||
      lower.contains('sobran');

  // ── Match ─────────────────────────────────────────────────────────────────

  SwapMatches findMatches({
    required List<StickerGroupEntity> groups,
    required Map<int, int> myQuantities,
    required ParsedSwapMessage theirMessage,
  }) {
    final lookup = _buildLookup(groups);

    final iCanGive = <StickerEntity>[];
    final theyCanGive = <StickerEntity>[];

    // Stickers I can give: I have repeated AND they need
    for (final e in theirMessage.needs.entries) {
      for (final pos in e.value) {
        final sticker = lookup['${e.key}:$pos'];
        if (sticker == null) continue;
        if ((myQuantities[sticker.globalNumber] ?? 0) >= 2) {
          iCanGive.add(sticker);
        }
      }
    }

    // Stickers they can give: I'm missing AND they have extra
    for (final e in theirMessage.swaps.entries) {
      for (final pos in e.value) {
        final sticker = lookup['${e.key}:$pos'];
        if (sticker == null) continue;
        if ((myQuantities[sticker.globalNumber] ?? 0) == 0) {
          theyCanGive.add(sticker);
        }
      }
    }

    return SwapMatches(iCanGive: iCanGive, theyCanGive: theyCanGive);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, StickerEntity> _buildLookup(List<StickerGroupEntity> groups) {
    final map = <String, StickerEntity>{};
    for (final group in groups) {
      for (final team in group.teams) {
        for (final sticker in team.stickers) {
          final pos = _positionOf(sticker.teamPosition);
          if (pos != null) map['${team.code}:$pos'] = sticker;
        }
      }
    }
    return map;
  }

  int? _positionOf(String teamPosition) {
    final parts = teamPosition.split(' ');
    if (parts.isEmpty) return null;
    return int.tryParse(parts.last);
  }
}

enum _Section { unknown, needs, swaps }
