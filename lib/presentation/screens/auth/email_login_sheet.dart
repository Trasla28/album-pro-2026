import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EmailLoginSheet extends ConsumerStatefulWidget {
  const EmailLoginSheet({super.key});

  @override
  ConsumerState<EmailLoginSheet> createState() => _EmailLoginSheetState();
}

class _EmailLoginSheetState extends ConsumerState<EmailLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacingL,
        AppConstants.spacingL,
        AppConstants.spacingL,
        AppConstants.spacingL + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Iniciar sesión',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppConstants.spacingL),
            AppTextField(
              hint: 'nombre@email.com',
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
            ),
            const SizedBox(height: AppConstants.spacingM),
            AppTextField(
              hint: '••••••••',
              label: 'Contraseña',
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: AppConstants.spacingL),
            AppButton(
              label: 'Iniciar sesión',
              loading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
