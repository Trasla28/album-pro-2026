import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/app_button.dart';

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isNotificationPage;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.isNotificationPage = false,
  });
}

const _pages = [
  _OnboardingPage(
    emoji: '⚽',
    title: 'Tu álbum digital',
    subtitle:
        'Registrá tus figuritas del Mundial 2026 y seguí tu progreso para completar el álbum.',
  ),
  _OnboardingPage(
    emoji: '👨‍👩‍👧‍👦',
    title: 'Con tu familia',
    subtitle:
        'Creá un grupo familiar, coordinen quién consigue cada figurita y eviten comprar repetidas.',
  ),
  _OnboardingPage(
    emoji: '🔄',
    title: 'Intercambiá repetidas',
    subtitle:
        'Publicá tus repetidas, reclamalas de otros o encontrá intercambios con coleccionistas cercanos.',
  ),
  _OnboardingPage(
    emoji: '🔔',
    title: 'Mantenete al tanto',
    subtitle:
        'Recibí avisos cuando alguien del grupo consiga una figurita, reclame tus repetidas o acepte un intercambio.',
    isNotificationPage: true,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _permissionRequested = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: AppConstants.animMedium,
        curve: Curves.easeInOut,
      );
    } else {
      // Last page: request notification permission then proceed
      if (!_permissionRequested) {
        _permissionRequested = true;
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}
      }
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Omitir'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => _Dot(active: i == _currentPage),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  if (isLastPage && _pages[_currentPage].isNotificationPage)
                    Column(
                      children: [
                        AppButton(
                          label: 'Activar notificaciones',
                          onPressed: _onNext,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Ahora no',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  else
                    AppButton(
                      label: isLastPage ? 'Comenzar' : 'Siguiente',
                      onPressed: _onNext,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.emoji, style: const TextStyle(fontSize: 88)),
          const SizedBox(height: AppConstants.spacingXL),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animFast,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
