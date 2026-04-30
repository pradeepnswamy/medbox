import 'package:flutter_test/flutter_test.dart';
import 'package:carermeds/utils/date_utils.dart';

void main() {
  // ── Formatting ───────────────────────────────────────────────────────────────

  group('MedDateUtils.formatDate', () {
    test('formats a date with a double-digit day', () {
      expect(MedDateUtils.formatDate(DateTime(2025, 4, 12)), '12 Apr 2025');
    });

    test('formats a date with a single-digit day (no zero-padding)', () {
      expect(MedDateUtils.formatDate(DateTime(2025, 1, 5)), '5 Jan 2025');
    });

    test('uses abbreviated month names for all 12 months', () {
      final abbrs = ['Jan','Feb','Mar','Apr','May','Jun',
                     'Jul','Aug','Sep','Oct','Nov','Dec'];
      for (var m = 1; m <= 12; m++) {
        final result = MedDateUtils.formatDate(DateTime(2025, m, 1));
        expect(result, contains(abbrs[m - 1]), reason: 'month $m');
      }
    });
  });

  group('MedDateUtils.formatMonthYear', () {
    test('formats month and year without a day', () {
      expect(MedDateUtils.formatMonthYear(DateTime(2025, 4, 1)), 'Apr 2025');
    });

    test('day component is ignored', () {
      expect(
        MedDateUtils.formatMonthYear(DateTime(2025, 12, 31)),
        'Dec 2025',
      );
    });
  });

  group('MedDateUtils.formatShort', () {
    test('formats abbreviated month followed by day', () {
      expect(MedDateUtils.formatShort(DateTime(2025, 4, 20)), 'Apr 20');
    });

    test('single-digit day has no leading zero', () {
      expect(MedDateUtils.formatShort(DateTime(2025, 6, 3)), 'Jun 3');
    });
  });

  // ── daysDiff ─────────────────────────────────────────────────────────────────

  group('MedDateUtils.daysDiff', () {
    test('same day returns 0', () {
      final d = DateTime(2025, 4, 1);
      expect(MedDateUtils.daysDiff(d, d), 0);
    });

    test('one day later returns 1', () {
      expect(
        MedDateUtils.daysDiff(DateTime(2025, 4, 1), DateTime(2025, 4, 2)),
        1,
      );
    });

    test('one day earlier returns −1', () {
      expect(
        MedDateUtils.daysDiff(DateTime(2025, 4, 2), DateTime(2025, 4, 1)),
        -1,
      );
    });

    test('ignores the time-of-day component', () {
      // 23:59 → 00:01 next day should still be exactly 1 day
      expect(
        MedDateUtils.daysDiff(
          DateTime(2025, 4, 1, 23, 59),
          DateTime(2025, 4, 2, 0, 1),
        ),
        1,
      );
    });

    test('counts days across a month boundary', () {
      expect(
        MedDateUtils.daysDiff(DateTime(2025, 1, 28), DateTime(2025, 2, 3)),
        6,
      );
    });

    test('counts days across a year boundary', () {
      expect(
        MedDateUtils.daysDiff(DateTime(2024, 12, 30), DateTime(2025, 1, 2)),
        3,
      );
    });
  });

  // ── monthsDiff ───────────────────────────────────────────────────────────────

  group('MedDateUtils.monthsDiff', () {
    test('same month returns 0', () {
      expect(
        MedDateUtils.monthsDiff(DateTime(2025, 4, 1), DateTime(2025, 4, 30)),
        0,
      );
    });

    test('one month later returns 1', () {
      expect(
        MedDateUtils.monthsDiff(DateTime(2025, 4, 1), DateTime(2025, 5, 1)),
        1,
      );
    });

    test('spans a year boundary correctly', () {
      expect(
        MedDateUtils.monthsDiff(DateTime(2024, 11, 1), DateTime(2025, 2, 1)),
        3,
      );
    });

    test('twelve months equals one year', () {
      expect(
        MedDateUtils.monthsDiff(DateTime(2024, 1, 1), DateTime(2025, 1, 1)),
        12,
      );
    });
  });

  // ── daysUntilExpiry (drives expiry alert thresholds) ──────────────────────────

  group('MedDateUtils.daysUntilExpiry — alert window logic', () {
    test('medicine expiring in 31 days is outside the 30-day warning window', () {
      final expiry = DateTime.now().add(const Duration(days: 31));
      expect(MedDateUtils.daysUntilExpiry(expiry), greaterThan(30));
    });

    test('medicine expiring in exactly 30 days is at the warning threshold', () {
      final expiry = DateTime.now().add(const Duration(days: 30));
      expect(MedDateUtils.daysUntilExpiry(expiry), lessThanOrEqualTo(30));
    });

    test('medicine expiring in 7 days is at the critical threshold', () {
      final expiry = DateTime.now().add(const Duration(days: 7));
      expect(MedDateUtils.daysUntilExpiry(expiry), lessThanOrEqualTo(7));
    });

    test('medicine expiring today returns 0', () {
      // Use noon today to avoid any midnight boundary flicker.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      expect(MedDateUtils.daysUntilExpiry(today), 0);
    });

    test('medicine that expired yesterday returns a negative value', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(MedDateUtils.daysUntilExpiry(yesterday), isNegative);
    });

    test('medicine expired 5 days ago returns −5', () {
      final expiry = DateTime.now().subtract(const Duration(days: 5));
      expect(MedDateUtils.daysUntilExpiry(expiry), -5);
    });
  });

  // ── monthsSinceOpened (drives opened-too-long alert threshold) ────────────────

  group('MedDateUtils.monthsSinceOpened — opened alert threshold', () {
    test('medicine opened 3+ months ago triggers the alert threshold', () {
      // 100 days ≈ 3.3 months
      final opened = DateTime.now().subtract(const Duration(days: 100));
      expect(MedDateUtils.monthsSinceOpened(opened), greaterThanOrEqualTo(3));
    });

    test('medicine opened less than 3 months ago is within the safe window', () {
      final opened = DateTime.now().subtract(const Duration(days: 50));
      expect(MedDateUtils.monthsSinceOpened(opened), lessThan(3));
    });

    test('returns a non-negative value even when opened in the future', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(MedDateUtils.monthsSinceOpened(future), isNonNegative);
    });
  });
}
