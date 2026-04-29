import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);

    ref.listen<ScanState>(scanProvider, (_, next) {
      if (next.status == ScanStatus.done) {
        context.push('/home/scan/confirm');
      } else if (next.status == ScanStatus.noResults) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se detectaron láminas. Intentá con mejor iluminación.'),
            backgroundColor: AppColors.warning,
          ),
        );
        ref.read(scanProvider.notifier).reset();
      } else if (next.status == ScanStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(scanProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear láminas')),
      body: state.status == ScanStatus.scanning
          ? const _ScanningView()
          : const _PickerView(),
    );
  }
}

class _PickerView extends ConsumerWidget {
  const _PickerView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.document_scanner_outlined,
              size: 72, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Tomá una foto del dorso\nde tus láminas',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Podés capturar varias láminas a la vez.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textDisabled),
          ),
          const SizedBox(height: 48),
          _SourceButton(
            icon: Icons.camera_alt_outlined,
            label: 'Tomar foto',
            source: ImageSource.camera,
          ),
          const SizedBox(height: 16),
          _SourceButton(
            icon: Icons.photo_library_outlined,
            label: 'Elegir de galería',
            source: ImageSource.gallery,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final ImageSource source;
  final bool outlined;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.source,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: () => ref.read(scanProvider.notifier).pickAndScan(source),
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: () => ref.read(scanProvider.notifier).pickAndScan(source),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text('Analizando imagen...', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
