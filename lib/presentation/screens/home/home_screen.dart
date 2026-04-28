import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/friend_provider.dart';
import '../../widgets/in_app_notification_banner.dart';
import '../album/album_screen.dart';
import '../groups/groups_tab.dart';
import '../notifications/notifications_screen.dart';
import '../swaps/swaps_screen.dart';
import '../../widgets/achievement_listener.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _tabs = [
    _Tab(icon: Icons.collections_bookmark_outlined, activeIcon: Icons.collections_bookmark, label: 'Álbum'),
    _Tab(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Grupos'),
    _Tab(icon: Icons.swap_horiz_outlined, activeIcon: Icons.swap_horiz, label: 'Intercambios'),
    _Tab(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifs'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        NotificationService.initialize(
          userId: user.id,
          onNavigate: (tab) {
            if (mounted) {
              ref.read(selectedHomeTabProvider.notifier).state = tab;
            }
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize friend profile in Firestore as soon as the user reaches home.
    ref.watch(friendCodeProvider);

    final tabIndex = ref.watch(selectedHomeTabProvider);

    return Scaffold(
      body: AchievementListener(
        child: InAppNotificationBanner(
          child: IndexedStack(
            index: tabIndex,
            children: const [
              AlbumScreen(),
              GroupsTab(),
              SwapsScreen(),
              NotificationsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BannerAdWidget(),
          _MainNavBar(
            currentIndex: tabIndex,
            onTap: (i) => ref.read(selectedHomeTabProvider.notifier).state = i,
            tabs: _tabs,
          ),
        ],
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _Tab({required this.icon, required this.activeIcon, required this.label});
}

class _MainNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_Tab> tabs;

  const _MainNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapCount =
        ref.watch(incomingFriendRequestsProvider).valueOrNull?.length ?? 0;
    final notifCount = ref.watch(unreadCountProvider);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: tabs.asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
        final badgeCount = i == 2 ? swapCount : (i == 3 ? notifCount : 0);
        return BottomNavigationBarItem(
          icon: _iconWithBadge(Icon(t.icon), badgeCount),
          activeIcon: _iconWithBadge(Icon(t.activeIcon), badgeCount),
          label: t.label,
        );
      }).toList(),
    );
  }

  Widget _iconWithBadge(Widget icon, int count) {
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -3,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                  fontSize: 8,
                  color: AppColors.white,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Banner ad ─────────────────────────────────────────────────────────────

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _banner;

  @override
  void initState() {
    super.initState();
    _banner = BannerAd(
      // TEST ID — reemplazar con el ID real de admob.google.com
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
