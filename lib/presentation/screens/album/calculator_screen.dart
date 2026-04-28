import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/album_provider.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  // Extra packs beyond what's needed (user can adjust)
  double _extraPacks = 0;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(albumProvider).stats;
    final missing = stats.missing;
    final total = stats.total;
    final owned = stats.owned;

    // Coupon collector expected value for remaining stickers
    // E[packs to collect k more from N distinct] ≈ N * H(N) - N * H(N-k)
    // where H(n) = sum_{i=1}^{n} 1/i (harmonic number)
    final expectedPacks = _expectedPacksToComplete(total, owned);
    final displayPacks = (expectedPacks + _extraPacks).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de sobres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(
              total: total,
              owned: owned,
              missing: missing,
            ),
            const SizedBox(height: AppConstants.spacingL),
            _EstimateCard(
              expectedPacks: expectedPacks,
              extra: _extraPacks.toInt(),
            ),
            const SizedBox(height: AppConstants.spacingL),
            _SliderSection(
              label: 'Sobres extra (margen de seguridad)',
              value: _extraPacks,
              max: 200,
              onChanged: (v) => setState(() => _extraPacks = v),
            ),
            const SizedBox(height: AppConstants.spacingL),
            _ResultCard(
              totalPacks: displayPacks,
              stickersPerPack: 7,
              costPerPack: 5000,
            ),
            const SizedBox(height: AppConstants.spacingL),
            const _DisclaimerNote(),
          ],
        ),
      ),
    );
  }
}

// Coupon collector formula:
// E[new stickers to finish album] = N * (H(N) - H(N - missing))
// where H is the harmonic number.
// We then convert to packs by dividing by stickers-per-pack (7).
double _expectedPacksToComplete(int total, int owned) {
  if (total <= 0) return 0;
  final missing = total - owned;
  if (missing <= 0) return 0;

  double harmonic(int n) {
    double h = 0;
    for (int i = 1; i <= n; i++) {
      h += 1 / i;
    }
    return h;
  }

  final hN = harmonic(total);
  final hOwned = owned > 0 ? harmonic(owned) : 0.0;
  final expectedStickers = total * (hN - hOwned);
  return (expectedStickers / 7).ceilToDouble();
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int owned;
  final int missing;

  const _SummaryCard(
      {required this.total, required this.owned, required this.missing});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? owned / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu álbum',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(
                    label: 'Conseguidas',
                    value: '$owned',
                    color: AppColors.success),
                const SizedBox(width: 16),
                _Stat(
                    label: 'Faltantes',
                    value: '$missing',
                    color: AppColors.error),
                const SizedBox(width: 16),
                _Stat(
                    label: 'Total',
                    value: '$total',
                    color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(pct * 100).toStringAsFixed(1)}% completado',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final double expectedPacks;
  final int extra;

  const _EstimateCard({required this.expectedPacks, required this.extra});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate_outlined,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text('Estimación estadística',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Según la fórmula del coleccionista de cupones, necesitás en promedio ${expectedPacks.ceil()} sobres para terminar el álbum.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            if (extra > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Agregaste $extra sobres extra de margen.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '+${value.toInt()} sobres',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: max,
          divisions: 40,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.divider,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final int totalPacks;
  final int stickersPerPack;
  final int costPerPack;

  const _ResultCard({
    required this.totalPacks,
    required this.stickersPerPack,
    required this.costPerPack,
  });

  @override
  Widget build(BuildContext context) {
    final totalStickers = totalPacks * stickersPerPack;
    final totalCost = totalPacks * costPerPack;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resultado estimado',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ResultRow(
              icon: Icons.inventory_2_outlined,
              label: 'Sobres necesarios',
              value: '$totalPacks',
              color: AppColors.primary,
            ),
            const Divider(height: 20),
            _ResultRow(
              icon: Icons.style_outlined,
              label: 'Figuritas totales',
              value: '$totalStickers',
              color: AppColors.info,
            ),
            const Divider(height: 20),
            _ResultRow(
              icon: Icons.attach_money,
              label: 'Costo estimado',
              value: '\$ ${_formatNumber(totalCost)}',
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'La estimación usa la fórmula del coleccionista de cupones y asume que cada sobre tiene 7 figuritas aleatorias uniformes. En la práctica el resultado varía.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
