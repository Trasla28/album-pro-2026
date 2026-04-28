import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, outlined, text, social }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 12), Text(label)],
              )
            : Text(label);

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AppButtonVariant.social => OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.labelLarge,
          ),
          child: child,
        ),
    };
  }
}
