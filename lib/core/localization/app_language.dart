enum AppLanguage {
  sorani,
  badini;

  String get code => switch (this) {
    AppLanguage.sorani => 'ckb',
    AppLanguage.badini => 'kmr',
  };

  String get nativeName => switch (this) {
    AppLanguage.sorani => 'سۆرانی',
    AppLanguage.badini => 'بادینی',
  };

  static AppLanguage fromCode(String? code) {
    return switch (code) {
      'kmr' => AppLanguage.badini,
      _ => AppLanguage.sorani,
    };
  }
}
