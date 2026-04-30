/// Pure string helpers used across the CarerMeds UI.
abstract final class StringUtils {
  // ── Name helpers ────────────────────────────────────────────────────────────

  /// Up to 2 uppercase initials from a full name.
  ///   "Ravi Kumar" → "RK"
  ///   "Pradeep"    → "P"
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ── Casing helpers ──────────────────────────────────────────────────────────

  /// Capitalizes the first character, leaves the rest unchanged.
  ///   "viral fever" → "Viral fever"
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Title-cases every word.
  ///   "viral fever" → "Viral Fever"
  static String titleCase(String s) =>
      s.trim().split(RegExp(r'\s+')).map(capitalize).join(' ');

  // ── Safety helpers ──────────────────────────────────────────────────────────

  /// Returns [s] if non-null and non-empty, otherwise [fallback] (default "—").
  static String orFallback(String? s, {String fallback = '—'}) =>
      (s == null || s.trim().isEmpty) ? fallback : s;

  /// Truncates [s] to [maxLength] characters, appending "…" if cut.
  static String truncate(String s, int maxLength) =>
      s.length <= maxLength ? s : '${s.substring(0, maxLength)}…';

  // ── Medicine / prescription helpers ─────────────────────────────────────────

  /// Formats a dosage string for display.
  ///   "250mg · 1 capsule × 3/day"  (already formatted — pass through)
  ///   Or combine parts: dosageAmount + form + frequency.
  static String dosageLabel({
    required String amount,
    required String form,
    required String frequency,
  }) =>
      '$amount · 1 ${form.toLowerCase()} × $frequency';
}
