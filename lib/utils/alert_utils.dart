import '../config/app_constants.dart';
import 'date_utils.dart';

/// Pure helper functions that decide whether a medicine triggers an alert.
/// These are intentionally stateless so they work with both live Firestore
/// data and the current in-memory sample data.
abstract final class AlertUtils {
  // ── Expiry checks ───────────────────────────────────────────────────────────

  /// True when [expiryDate] is within [thresholdDays] days from today
  /// (and not yet expired).
  static bool isExpiringSoon(
    DateTime expiryDate, {
    int thresholdDays = AppConstants.warningExpiryDays,
  }) {
    final days = MedDateUtils.daysUntilExpiry(expiryDate);
    return days >= 0 && days <= thresholdDays;
  }

  /// True when [expiryDate] is in the past.
  static bool isExpired(DateTime expiryDate) =>
      MedDateUtils.daysUntilExpiry(expiryDate) < 0;

  /// Urgency level based on days until expiry.
  /// critical ≤ [AppConstants.criticalExpiryDays] (default 7)
  /// warning  ≤ [AppConstants.warningExpiryDays]  (default 30)
  static ExpiryUrgency expiryUrgency(DateTime expiryDate) {
    final days = MedDateUtils.daysUntilExpiry(expiryDate);
    if (days < 0) return ExpiryUrgency.expired;
    if (days <= AppConstants.criticalExpiryDays) return ExpiryUrgency.critical;
    if (days <= AppConstants.warningExpiryDays) return ExpiryUrgency.warning;
    return ExpiryUrgency.ok;
  }

  // ── Opened-too-long check ───────────────────────────────────────────────────

  /// True when a medicine has been open for longer than [thresholdMonths]
  /// calendar months.
  static bool isOpenedTooLong(
    DateTime openedDate, {
    int thresholdMonths = AppConstants.defaultOpenedMonthThreshold,
  }) =>
      MedDateUtils.monthsSinceOpened(openedDate) >= thresholdMonths;

  // ── Label helpers ───────────────────────────────────────────────────────────

  /// Human-readable label for days until expiry, e.g. "4 days left" or "Expired".
  static String expiryLabel(DateTime expiryDate) {
    final days = MedDateUtils.daysUntilExpiry(expiryDate);
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  /// Human-readable label for how long a medicine has been open,
  /// e.g. "3 months" or "45 days".
  static String openedDurationLabel(DateTime openedDate) {
    final months = MedDateUtils.monthsSinceOpened(openedDate);
    if (months >= 1) return '$months ${months == 1 ? "month" : "months"}';
    final days = MedDateUtils.daysDiff(openedDate, DateTime.now());
    return '$days ${days == 1 ? "day" : "days"}';
  }
}

/// Urgency level for a medicine's expiry date.
enum ExpiryUrgency { ok, warning, critical, expired }
