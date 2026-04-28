import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/group_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'share_invite_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final group = await ref
          .read(groupActionsProvider)
          .createGroup(_nameCtrl.text.trim());
      if (!mounted) return;
      AdService.showInterstitial(onComplete: () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ShareInviteScreen(group: group)),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear grupo')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nombre del grupo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Elegí un nombre para que tu familia lo reconozca fácilmente.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.spacingL),
              AppTextField(
                hint: 'ej. Familia García',
                label: 'Nombre',
                controller: _nameCtrl,
                autofocus: true,
                prefixIcon: const Icon(Icons.group_outlined),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresá un nombre' : null,
              ),
              const Spacer(),
              AppButton(
                label: 'Crear y compartir código',
                loading: _loading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
