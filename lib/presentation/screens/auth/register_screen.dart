import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _nameCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    ref.listen(authStateProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ── Header verde ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingL,
              56,
              AppConstants.spacingL,
              AppConstants.spacingXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  padding: EdgeInsets.zero,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 36,
                      height: 36,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AlbumPro 2026',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completar nunca fue tan fácil.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          // ── Formulario en tarjeta blanca ──────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingL,
                  AppConstants.spacingXL,
                  AppConstants.spacingL,
                  AppConstants.spacingL,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        hint: 'Tu nombre',
                        label: 'Nombre',
                        controller: _nameCtrl,
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresá tu nombre'
                            : null,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      AppTextField(
                        hint: 'nombre@email.com',
                        label: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Email inválido'
                            : null,
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
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      AppTextField(
                        hint: '••••••••',
                        label: 'Confirmar contraseña',
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) => v != _passwordCtrl.text
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                      const SizedBox(height: AppConstants.spacingXL),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white),
                                )
                              : const Text('Crear cuenta'),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tenés cuenta?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Iniciá sesión'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
