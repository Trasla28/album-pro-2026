import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ── Servicio de anuncios ──────────────────────────────────────────────────
class AdService {
  static String get bannerAdUnitId => Platform.isIOS
      ? 'ca-app-pub-2794505381439193/5313101693'
      : 'ca-app-pub-2794505381439193/3516893589';

  static String get _interstitialAdUnitId => Platform.isIOS
      ? 'ca-app-pub-2794505381439193/4247206692'
      : 'ca-app-pub-2794505381439193/5700114503';

  static InterstitialAd? _interstitial;
  static bool _isLoading = false;

  static void preload() {
    if (_isLoading || _interstitial != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) {
              _interstitial = null;
              preload();
            },
            onAdFailedToShowFullScreenContent: (_, __) {
              _interstitial = null;
              preload();
            },
          );
        },
        onAdFailedToLoad: (_) => _isLoading = false,
      ),
    );
  }

  /// Muestra el interstitial si está listo. Siempre llama [onComplete]
  /// para que el flujo de la app continúe aunque no haya anuncio.
  static void showInterstitial({required void Function() onComplete}) {
    if (_interstitial != null) {
      _interstitial!.show();
      onComplete();
    } else {
      onComplete();
    }
  }
}
