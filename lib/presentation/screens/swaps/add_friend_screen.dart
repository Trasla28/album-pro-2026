import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(friendActionsProvider).sendRequest(_codeCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada'),
          backgroundColor: AppColors.success,
        ),
      );
      AdService.showInterstitial(onComplete: () {
        if (!mounted) return;
        Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Agregar amigo')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Código de amigo',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Pedile a tu amigo que te comparta su código de 8 caracteres. '
                'Lo puede ver en la pantalla de Amigos.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.spacingL),
              AppTextField(
                hint: 'ej. AB3X7KNM',
                label: 'Código',
                controller: _codeCtrl,
                autofocus: true,
                prefixIcon: const Icon(Icons.person_search_outlined),
                validator: (v) => v == null || v.trim().length < 8
                    ? 'El código debe tener 8 caracteres'
                    : null,
              ),
              const Spacer(),
              AppButton(
                label: 'Enviar solicitud',
                loading: _loading,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
