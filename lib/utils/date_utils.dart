/// Convenience wrappers for common date operations used across CarerMeds.
/// All functions are pure (no side-effects) so they are easy to unit-test.
abstract final class MedDateUtils {
  // ── Formatting ──────────────────────────────────────────────────────────────

  /// "12 Apr 2025"
  static String formatDate(DateTime date) =>
      '${date.day} ${_abbr(date.month)} ${date.year}';

  /// "Apr 2025"
  static String formatMonthYear(DateTime date) =>
      '${_abbr(date.month)} ${date.year}';

  /// "Apr 20"  (used on medicine list cards)
  static String formatShort(DateTime date) =>
      '${_abbr(date.month)} ${date.day}';

  /// Full month name for a 1-based [month] index.
  /// Used wherever the label needs the full word, e.g. "2 January 2025".
  static String monthName(int month) => _fullMonth(month);

  // ── Differences ─────────────────────────────────────────────────────────────

  /// Whole days between [from] and [to]. Positive means [to] is later.
  static int daysDiff(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Approximate whole months between [from] and [to]. Positive means [to] is later.
  static int monthsDiff(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  /// Days remaining until [expiryDate] from today. Negative = already expired.
  static int daysUntilExpiry(DateTime expiryDate) =>
      daysDiff(DateTime.now(), expiryDate);

  /// Whole months elapsed since [openedDate] up to today.
  static int monthsSinceOpened(DateTime openedDate) =>
      monthsDiff(openedDate, DateTime.now()).abs();

  // ── Private helpers ─────────────────────────────────────────────────────────

  static const _months = [
    '',
    'January', 'February', 'March',    'April',   'May',      'June',
    'July',    'August',   'September', 'October', 'November', 'December',
  ];

  static const _abbrs = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fullMonth(int m) =>
      (m >= 1 && m <= 12) ? _months[m] : '';

  static String _abbr(int m) =>
      (m >= 1 && m <= 12) ? _abbrs[m] : '';
}
