import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/sticker_scan_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/album_provider.dart';
import '../../providers/scan_provider.dart';

class ScanConfirmScreen extends ConsumerStatefulWidget {
  const ScanConfirmScreen({super.key});

  @override
  ConsumerState<ScanConfirmScreen> createState() => _ScanConfirmScreenState();
}

class _ScanConfirmScreenState extends ConsumerState<ScanConfirmScreen> {
  bool _saving = false;

  Future<void> _confirm() async {
    final results = ref.read(scanProvider).results;
    if (results.isEmpty) return;

    setState(() => _saving = true);
    final albumNotifier = ref.read(albumProvider.notifier);
    final quantities = ref.read(albumProvider).quantities;

    int newCount = 0;
    int dupCount = 0;

    for (final result in results) {
      final currentQty = quantities[result.sticker.globalNumber] ?? 0;
      await albumNotifier.setQuantity(result.sticker.globalNumber, currentQty + 1);
      if (currentQty == 0) {
        newCount++;
      } else {
        dupCount++;
      }
    }

    ref.read(scanProvider.notifier).reset();

    if (!mounted) return;
    setState(() => _saving = false);

    final parts = <String>[];
    if (newCount > 0) parts.add('$newCount nueva${newCount != 1 ? 's' : ''}');
    if (dupCount > 0) parts.add('$dupCount repetida${dupCount != 1 ? 's' : ''}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guardadas: ${parts.join(' · ')}'),
        backgroundColor: AppColors.success,
      ),
    );

    // Pop back to album (scan confirm → scan → album, so pop twice)
    context.pop();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);
    final quantities = ref.watch(albumProvider).quantities;
    final results = state.results;

    return Scaffold(
      appBar: AppBar(
        title: Text('${results.length} lámina${results.length != 1 ? 's' : ''} detectada${results.length != 1 ? 's' : ''}'),
      ),
      body: results.isEmpty
          ? const _EmptyResults()
          : Column(
              children: [
                if (state.imagePath != null) _ImagePreview(path: state.imagePath!),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) => _StickerRow(
                      result: results[i],
                      isNew: (quantities[results[i].sticker.globalNumber] ?? 0) == 0,
                      onRemove: () => ref
                          .read(scanProvider.notifier)
                          .removeResult(results[i].sticker.globalNumber),
                    ),
                  ),
                ),
                _ConfirmBar(
                  count: results.length,
                  saving: _saving,
                  onConfirm: _confirm,
                ),
              ],
            ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String path;
  const _ImagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.darkBackground),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        color: Colors.black.withValues(alpha: 0.15),
        colorBlendMode: BlendMode.darken,
      ),
    );
  }
}

class _StickerRow extends StatelessWidget {
  final StickerScanResult result;
  final bool isNew;
  final VoidCallback onRemove;

  const _StickerRow({
    required this.result,
    required this.isNew,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final sticker = result.sticker;
    return ListTile(
      leading: _TeamBadge(code: sticker.teamCode),
      title: Text(
        sticker.playerName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        sticker.teamPosition,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusBadge(isNew: isNew),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textDisabled),
            onPressed: onRemove,
            tooltip: 'Quitar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  final String code;
  const _TeamBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isNew;
  const _StatusBadge({required this.isNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNew
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isNew ? 'Nueva' : 'Repetida',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isNew ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  final int count;
  final bool saving;
  final VoidCallback onConfirm;

  const _ConfirmBar({
    required this.count,
    required this.saving,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton(
          onPressed: (saving || count == 0) ? null : onConfirm,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2),
                )
              : Text(
                  'Guardar $count lámina${count != 1 ? 's' : ''} en el álbum',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textDisabled),
          SizedBox(height: 12),
          Text(
            'No quedaron láminas por confirmar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
