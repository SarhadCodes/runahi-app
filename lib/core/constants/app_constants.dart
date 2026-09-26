class AppConstants {
  AppConstants._();

  static const String appName = 'رووناهى';
  static const String appId = 'com.rounahi.rounahi';
  static const String version = '1.0.0';
  static const String deepLinkScheme = 'rounahi';
  static const String deepLinkHost = 'app';

  static const Duration searchDebounce = Duration(milliseconds: 280);
  static const Duration splashDuration = Duration(milliseconds: 1600);
  static const Duration pageTransition = Duration(milliseconds: 420);
  static const Duration petalAnimation = Duration(milliseconds: 280);

  static const int searchHistoryLimit = 12;
  static const int notifiedIdRetention = 400;

  static const String widgetAyah = 'RounahiAyahWidget';
  static const String widgetWord = 'RounahiWordWidget';
  static const String widgetTopic = 'RounahiTopicWidget';
  static const String widgetLatest = 'RounahiLatestWidget';
  static const String widgetCompact = 'RounahiCompactWidget';

  static const String workmanagerTask = 'rounahi.content.sync';
}

class StorageKeys {
  StorageKeys._();

  static const String language = 'language';
  static const String themeMode = 'theme_mode';
  static const String fontScale = 'font_scale';
  static const String quranFontScale = 'quran_font_scale';
  static const String bookmarks = 'bookmarks';
  static const String readingProgress = 'reading_progress';
  static const String videoProgress = 'video_progress';
  static const String recentSearches = 'recent_searches';
  static const String lastContentCheck = 'last_content_check';
  static const String lastContentVersion = 'last_content_version';
  static const String notifiedIds = 'notified_content_ids';
  static const String notificationPrefs = 'notification_prefs';
  static const String cachedCatalog = 'cached_catalog';
  static const String appConfig = 'app_config';
  static const String onboardingComplete = 'onboarding_complete_v1';
  static const String qiblaCity = 'qibla_city';
}
