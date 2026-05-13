import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/message_swap_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/sticker_entity.dart';
import '../../../domain/entities/sticker_group_entity.dart';
import '../../providers/album_provider.dart';

class MessageSwapScreen extends ConsumerStatefulWidget {
  const MessageSwapScreen({super.key});

  @override
  ConsumerState<MessageSwapScreen> createState() => _MessageSwapScreenState();
}

class _MessageSwapScreenState extends ConsumerState<MessageSwapScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _pasteController = TextEditingController();
  final _service = MessageSwapService();
  SwapMatches? _matches;
  bool _analyzed = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  void _analyze(List<StickerGroupEntity> albumGroups, Map<int, int> quantities) {
    if (_pasteController.text.trim().isEmpty) return;
    final parsed = _service.parseMessage(_pasteController.text);
    final matches = _service.findMatches(
      groups: albumGroups,
      myQuantities: quantities,
      theirMessage: parsed,
    );
    setState(() {
      _matches = matches;
      _analyzed = true;
    });
  }

  void _clear() => setState(() {
        _pasteController.clear();
        _matches = null;
        _analyzed = false;
      });

  @override
  Widget build(BuildContext context) {
    final albumState = ref.watch(albumProvider);
    final message = _service.generateMessage(
      albumState.groups,
      albumState.quantities,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intercambio por mensaje'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Mi lista'),
            Tab(text: 'Analizar lista'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyListTab(message: message),
          _AnalyzeTab(
            controller: _pasteController,
            matches: _analyzed ? _matches : null,
            analyzed: _analyzed,
            onAnalyze: () => _analyze(albumState.groups, albumState.quantities),
            onClear: _clear,
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Mi lista ────────────────────────────────────────────────────────

class _MyListTab extends StatelessWidget {
  final String message;
  const _MyListTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: SelectableText(
                message,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  height: 1.7,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingM,
            0,
            AppConstants.spacingM,
            AppConstants.spacingM,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lista copiada al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => SharePlus.instance.share(ShareParams(text: message)),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Compartir'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab 2: Analizar lista ──────────────────────────────────────────────────

class _AnalyzeTab extends StatelessWidget {
  final TextEditingController controller;
  final SwapMatches? matches;
  final bool analyzed;
  final VoidCallback onAnalyze;
  final VoidCallback onClear;

  const _AnalyzeTab({
    required this.controller,
    required this.matches,
    required this.analyzed,
    required this.onAnalyze,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Pegá aquí la lista de tu contacto...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              fillColor: AppColors.surfaceVariant,
              filled: true,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              if (analyzed) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                  label: const Text('Analizar'),
                ),
              ),
            ],
          ),
          if (analyzed) ...[
            const SizedBox(height: AppConstants.spacingL),
            _MatchResults(matches: matches),
          ],
        ],
      ),
    );
  }
}

// ── Resultados del análisis ────────────────────────────────────────────────

class _MatchResults extends StatelessWidget {
  final SwapMatches? matches;
  const _MatchResults({required this.matches});

  @override
  Widget build(BuildContext context) {
    final m = matches;
    if (m == null || (m.iCanGive.isEmpty && m.theyCanGive.isEmpty)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXL),
          child: Column(
            children: [
              Text('😕', style: TextStyle(fontSize: 48)),
              SizedBox(height: AppConstants.spacingM),
              Text(
                'No hay intercambios posibles con esta lista',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips de resumen
        Row(
          children: [
            _CountChip(
              label: 'Podés darle',
              count: m.iCanGive.length,
              color: AppColors.success,
            ),
            const SizedBox(width: AppConstants.spacingS),
            _CountChip(
              label: 'Podés pedirle',
              count: m.theyCanGive.length,
              color: AppColors.info,
            ),
          ],
        ),
        if (m.iCanGive.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingL),
          _TeamGroupSection(
            title: 'Láminas que podés darle',
            color: AppColors.success,
            icon: Icons.arrow_circle_up_outlined,
            stickers: m.iCanGive,
          ),
        ],
        if (m.theyCanGive.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingL),
          _TeamGroupSection(
            title: 'Láminas que podés pedirle',
            color: AppColors.info,
            icon: Icons.arrow_circle_down_outlined,
            stickers: m.theyCanGive,
          ),
        ],
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamGroupSection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<StickerEntity> stickers;

  const _TeamGroupSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.stickers,
  });

  @override
  Widget build(BuildContext context) {
    // Group by teamCode preserving encounter order
    final byTeam = <String, List<StickerEntity>>{};
    for (final s in stickers) {
      byTeam.putIfAbsent(s.teamCode, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              '$title (${stickers.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: byTeam.entries
                .map((e) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spacingS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value
                                  .map((s) => s.teamPosition.split(' ').last)
                                  .join(', '),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
