import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/sticker_entity.dart';
import '../../providers/album_provider.dart';
import '../../widgets/sticker_cell.dart';
import 'sticker_detail_screen.dart';

class AlbumSearchScreen extends ConsumerStatefulWidget {
  const AlbumSearchScreen({super.key});

  @override
  ConsumerState<AlbumSearchScreen> createState() => _AlbumSearchScreenState();
}

class _AlbumSearchScreenState extends ConsumerState<AlbumSearchScreen> {
  final _controller = TextEditingController();
  List<StickerEntity> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearch);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearch);
    _controller.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final all = ref.read(albumProvider).allStickers;
    setState(() {
      _results = all.where((s) {
        // Match global number (e.g. "455")
        if (s.globalNumber.toString() == query) return true;
        // Match team position (e.g. "arg 10" or "ARG10")
        final pos = s.teamPosition.toLowerCase().replaceAll(' ', '');
        final qNorm = query.replaceAll(' ', '');
        if (pos.contains(qNorm)) return true;
        // Match player name
        if (s.playerName.toLowerCase().contains(query)) return true;
        return false;
      }).take(50).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quantities = ref.watch(albumProvider).quantities;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.white),
          cursorColor: AppColors.white,
          decoration: const InputDecoration(
            hintText: 'Número, ARG 10, jugador...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            filled: false,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _controller.clear(),
            ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    _controller.text.isEmpty
                        ? 'Buscá por número, código de posición\no nombre del jugador'
                        : 'Sin resultados para "${_controller.text}"',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final sticker = _results[i];
                return StickerCell(
                  sticker: sticker,
                  quantity: quantities[sticker.globalNumber] ?? 0,
                  onTap: () => showStickerDetail(ctx, sticker),
                );
              },
            ),
    );
  }
}
