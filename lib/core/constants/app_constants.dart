class AppConstants {
  AppConstants._();

  static const String appName = 'AlbumPro 2026';
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  // Hive boxes
  static const String userBox = 'user_box';
  static const String stickerQuantitiesBox = 'sticker_quantities';
  static const String settingsBox = 'settings_box';
  static const String personalBackupBox = 'personal_backup';

  // Hive type IDs
  static const int userTypeId = 0;
  static const int stickerTypeId = 1;

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Border radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  // Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
