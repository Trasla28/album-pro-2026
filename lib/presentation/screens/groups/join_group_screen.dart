import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/group_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'group_detail_screen.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unirse al grupo'),
        content: const Text(
          'Al unirte, tu álbum se sincronizará con el del grupo. '
          'Tu colección personal se guardará y podrás recuperarla si salís del grupo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unirme'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final group = await ref
          .read(groupActionsProvider)
          .joinGroup(_codeCtrl.text.trim());
      if (!mounted) return;
      AdService.showInterstitial(onComplete: () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a un grupo')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código de invitación',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Pedile a un miembro del grupo que te comparta el código de 6 caracteres.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.spacingL),
              AppTextField(
                hint: 'ej. AB3X7K',
                label: 'Código',
                controller: _codeCtrl,
                autofocus: true,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                validator: (v) => v == null || v.trim().length < 6
                    ? 'El código debe tener 6 caracteres'
                    : null,
              ),
              const Spacer(),
              AppButton(
                label: 'Unirme al grupo',
                loading: _loading,
                onPressed: _join,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
