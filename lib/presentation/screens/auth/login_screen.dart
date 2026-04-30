import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingL,
              vertical: AppConstants.spacingL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppConstants.spacingXXL),

                  // ── Logo ────────────────────────────────────────────
                  Image.asset(
                    'assets/images/icon_final_512.png',
                    width: 110,
                    height: 110,
                  ),
                  const SizedBox(height: AppConstants.spacingL),

                  // ── Título y slogan ─────────────────────────────────
                  const Text(
                    'AlbumPro 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lleva tu álbum como un profesional.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXXL),

                  // ── Campos del formulario ───────────────────────────
                  _GreenTheme(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          hint: 'nombre@email.com',
                          label: 'Email',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppColors.white),
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
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.white,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXL),

                  // ── Botón iniciar sesión ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            )
                          : const Text('Iniciar sesión'),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // ── Divisor ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                            color: AppColors.white.withValues(alpha: 0.35)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingM),
                        child: Text(
                          'o continuar con',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                            color: AppColors.white.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // ── Botón Google ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(authStateProvider.notifier)
                              .signInWithGoogle(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.white),
                      ),
                      label: const Text('Continuar con Google'),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingM),

                  // ── Botón Microsoft ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(authStateProvider.notifier)
                              .signInWithMicrosoft(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusM),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Text(
                        '⊞',
                        style: TextStyle(fontSize: 18, color: AppColors.white),
                      ),
                      label: const Text('Continuar con Microsoft'),
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingXL),

                  // ── Registro ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tenés cuenta?',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        child: const Text('Registrate'),
                      ),
                    ],
                  ),

                  // ── Términos ────────────────────────────────────────
                  Text(
                    'Al continuar aceptás los Términos de Servicio\ny la Política de Privacidad',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aplica un tema local para que los campos de texto se vean bien sobre verde.
class _GreenTheme extends StatelessWidget {
  final Widget child;
  const _GreenTheme({required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white.withValues(alpha: 0.15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle:
              const TextStyle(color: AppColors.white, fontSize: 14),
          hintStyle: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5), fontSize: 14),
          prefixIconColor: AppColors.white,
          suffixIconColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: BorderSide(
                color: AppColors.white.withValues(alpha: 0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide:
                const BorderSide(color: AppColors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          errorStyle: const TextStyle(color: AppColors.accentLight),
        ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: AppColors.white,
              displayColor: AppColors.white,
            ),
      ),
      child: child,
    );
  }
}
