/// App-wide string literals, thresholds, and magic numbers.
/// Change values here — they propagate everywhere automatically.
abstract final class AppConstants {

  // ── App identity ──────────────────────────────────────────────────────────────
  static const String appName        = 'MedBox';
  static const String appVersion     = '1.0.0';
  static const String appTagline     = 'Your family medicine manager';

  // ── Alert thresholds (expiry) ─────────────────────────────────────────────────
  /// Medicines expiring within this many days are CRITICAL (red).
  static const int criticalExpiryDays  = 7;
  /// Medicines expiring within this many days are a WARNING (amber).
  static const int warningExpiryDays   = 30;
  /// Default multi-select day chips shown in Alert Settings.
  static const Set<int> defaultExpiryDayThresholds = {7, 30};
  /// All available day-threshold options in Alert Settings.
  static const List<int> expiryDayOptions = [1, 7, 30, 60];

  // ── Alert thresholds (opened) ─────────────────────────────────────────────────
  /// Medicines opened longer than this many months trigger an opened alert.
  static const int defaultOpenedMonthThreshold = 3;
  /// All available month-threshold options in Alert Settings.
  static const List<int> openedMonthOptions = [1, 2, 3, 6];

  // ── Notification defaults ─────────────────────────────────────────────────────
  static const int    defaultCheckHour   = 9;
  static const int    defaultCheckMinute = 0;

  // ── UI geometry ───────────────────────────────────────────────────────────────
  static const double radiusCard   = 14.0;
  static const double radiusChip   = 20.0;
  static const double radiusInput  = 12.0;
  static const double radiusSmall  = 10.0;

  // ── Firestore collection names ────────────────────────────────────────────────
  static const String colUsers          = 'users';
  static const String colMedicines      = 'medicines';
  static const String colPrescriptions  = 'prescriptions';
  static const String colPatients       = 'patients';
  static const String colAlerts         = 'alerts';

  // ── Shared-preferences / storage keys ────────────────────────────────────────
  static const String prefExpiryThresholds  = 'expiry_thresholds';
  static const String prefOpenedThreshold   = 'opened_threshold';
  static const String prefCheckHour         = 'check_hour';
  static const String prefCheckMinute       = 'check_minute';
  static const String prefPushEnabled       = 'push_enabled';
  static const String prefInAppBanners      = 'in_app_banners';
  static const String prefBadgeCount        = 'badge_count';

  // ── Misc strings ──────────────────────────────────────────────────────────────
  static const String noLinkedRx    = 'No Rx';
  static const String notOpenedYet  = 'Not opened yet';
  static const String unknown       = '—';
}
