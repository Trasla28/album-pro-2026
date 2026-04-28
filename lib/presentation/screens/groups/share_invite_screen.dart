import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/group_entity.dart';
import '../../widgets/app_button.dart';

class ShareInviteScreen extends StatelessWidget {
  final GroupEntity group;

  const ShareInviteScreen({super.key, required this.group});

  String get _deepLink => 'albummundial://join?code=${group.inviteCode}';

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '¡Unite a mi grupo "${group.name}" en AlbumPro 2026!\n'
            'Código: ${group.inviteCode}\n\n'
            'Abrí la app y usá el código para unirte.',
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: group.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir invitación'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.spacingL),
            Text(
              group.name,
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),

            // QR code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _deepLink,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingXL),

            // Invite code
            Text('Código de invitación',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppConstants.spacingS),
            GestureDetector(
              onTap: () => _copyCode(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.inviteCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.copy, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Tocá el código para copiarlo',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textDisabled),
            ),
            const SizedBox(height: AppConstants.spacingXXL),
            AppButton(
              label: 'Compartir por WhatsApp u otras apps',
              icon: const Icon(Icons.share, size: 18, color: AppColors.white),
              onPressed: _share,
            ),
          ],
        ),
      ),
    );
  }
}
