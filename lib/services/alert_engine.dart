import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/alert_item.dart';
import '../models/medicine.dart';
import '../utils/date_utils.dart';
import 'notification_service.dart';

/// Automatically generates and maintains alerts in Firestore based on the
/// current state of every medicine belonging to the signed-in user.
///
/// ## How it works
///
/// Call [AlertEngine.sync()] after any medicine mutation (add / update / delete)
/// and once on app startup.  The engine:
///
///   1. Loads all medicines from `users/{uid}/medicines`
///   2. Computes which alert documents *should* exist:
///      • **Expiring alert** — created when `daysUntilExpiry ≤ 30`
///        - severity = critical  (≤ 7 days)
///        - severity = warning   (8 – 30 days)
///      • **Opened alert** — created when `monthsSinceOpened ≥ 3`
///   3. Loads existing alerts to preserve `isDismissed` flags the user set
///   4. Batch-writes the result:
///      - Upserts every alert that should exist
///      - Deletes alerts for medicines that no longer qualify (expired alert
///        cleared after medicine is deleted or expiry extended, etc.)
///
/// ## Document IDs
///
/// Deterministic IDs make the engine idempotent:
///   • `{medicineId}_expiring`
///   • `{medicineId}_opened`
///
/// Running sync() twice produces the same Firestore state.
abstract final class AlertEngine {

  // ── Firestore refs ────────────────────────────────────────────────────────────

  static FirebaseFirestore get _db   => FirebaseFirestore.instance;
  static FirebaseAuth      get _auth => FirebaseAuth.instance;
  static String?           get _uid  => _auth.currentUser?.uid;

  static CollectionReference _col(String name) =>
      _db.collection('users/$_uid/$name');

  // ── Thresholds (easy to adjust or read from AlertSettings later) ──────────────

  static const int _expiryWarningDays  = 30; // amber alert threshold
  static const int _expiryCriticalDays = 7;  // red alert threshold
  static const int _openedWarningMonths = 3; // opened-too-long threshold

  // ── Entry point ───────────────────────────────────────────────────────────────

  static const _kTimeout = Duration(seconds: 10);

  /// Syncs the alerts collection to match the current medicine state.
  /// Safe to call multiple times — fully idempotent.
  /// Silently aborts when offline so it never blocks the UI.
  static Future<void> sync() async {
    final uid = _uid;
    if (uid == null) return; // not signed in
    try {
      await _doSync(uid).timeout(_kTimeout);
    } on TimeoutException {
      debugPrint('[AlertEngine] sync skipped — offline or slow network');
    } catch (e) {
      debugPrint('[AlertEngine] sync error: $e');
    }
  }

  static Future<void> _doSync(String uid) async {

    // ── 1. Load medicines ─────────────────────────────────────────────────────
    final medSnap = await _col('medicines').get();
    final medicines = medSnap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MedicineData.fromJson({'id': doc.id, ...data});
    }).toList();

    // ── 2. Load existing alerts — preserve isDismissed per doc ────────────────
    final alertSnap = await _col('alerts').get();
    final wasDismissed = <String, bool>{};
    for (final doc in alertSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      wasDismissed[doc.id] = (data['isDismissed'] as bool?) ?? false;
    }

    // ── 3. Compute which alerts should exist ──────────────────────────────────
    final shouldExist = <String, Map<String, dynamic>>{};

    for (final med in medicines) {
      _computeExpiringAlert(med, shouldExist, wasDismissed);
      _computeOpenedAlert(med, shouldExist, wasDismissed);
    }

    // ── 4. Batch write ────────────────────────────────────────────────────────
    final batch = _db.batch();
    final alertsCol = _col('alerts');

    // Upsert alerts that should exist
    for (final entry in shouldExist.entries) {
      batch.set(alertsCol.doc(entry.key), entry.value);
    }

    // Delete stale alerts (no longer qualify)
    for (final doc in alertSnap.docs) {
      if (!shouldExist.containsKey(doc.id)) {
        batch.delete(alertsCol.doc(doc.id));
      }
    }

    await batch.commit();

    // ── 5. Sync OS notifications with the freshly computed alert set ──────────
    // Reconstruct AlertItem list from the shouldExist map so we have typed
    // objects with isDismissed already baked in (preserved from wasDismissed).
    final alertItems = shouldExist.entries.map((e) {
      return AlertItem.fromJson({'id': e.key, ...e.value});
    }).toList();

    // Fire-and-forget — notification failures must not block data writes.
    NotificationService.scheduleAlertsNotifications(alertItems)
        .catchError((e) => null);
  }

  // ── Alert computation helpers ─────────────────────────────────────────────────

  static void _computeExpiringAlert(
    MedicineData med,
    Map<String, Map<String, dynamic>> shouldExist,
    Map<String, bool> wasDismissed,
  ) {
    final expiryDate = _resolveExpiryDate(med);
    if (expiryDate == null) return;

    final daysLeft = MedDateUtils.daysUntilExpiry(expiryDate);
    if (daysLeft > _expiryWarningDays) return; // outside alert window

    final alertId  = '${med.id}_expiring';
    final severity = daysLeft <= _expiryCriticalDays
        ? AlertSeverity.critical
        : AlertSeverity.warning;

    final String daysLabel;
    if (daysLeft < 0) {
      final d = -daysLeft;
      daysLabel = 'Expired $d day${d == 1 ? '' : 's'} ago';
    } else if (daysLeft == 0) {
      daysLabel = 'Expires today';
    } else {
      daysLabel = '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    }

    final description =
        'Expires ${MedDateUtils.formatDate(expiryDate)} · ${med.patient}';

    final alert = AlertItem(
      id:                 alertId,
      medicineName:       med.name,
      daysValue:          daysLeft,
      daysLabel:          daysLabel,
      description:        description,
      patientName:        med.patient,
      patientInitials:    med.patientInitials,
      patientAvatarColor: med.patientAvatarColor,
      type:               AlertType.expiring,
      severity:           severity,
      isDismissed:        wasDismissed[alertId] ?? false,
    );

    shouldExist[alertId] = alert.toFirestore();
  }

  static void _computeOpenedAlert(
    MedicineData med,
    Map<String, Map<String, dynamic>> shouldExist,
    Map<String, bool> wasDismissed,
  ) {
    if (!med.isOpened) return;

    final openedDate = _resolveOpenedDate(med);
    if (openedDate == null) return;

    final monthsOpen = MedDateUtils.monthsSinceOpened(openedDate);
    if (monthsOpen < _openedWarningMonths) return; // within safe window

    final alertId    = '${med.id}_opened';
    final daysLabel  = '$monthsOpen mo ago';
    final description =
        'Opened ${MedDateUtils.formatDate(openedDate)} · ${med.patient}';

    final alert = AlertItem(
      id:                 alertId,
      medicineName:       med.name,
      daysValue:          monthsOpen,
      daysLabel:          daysLabel,
      description:        description,
      patientName:        med.patient,
      patientInitials:    med.patientInitials,
      patientAvatarColor: med.patientAvatarColor,
      type:               AlertType.opened,
      severity:           AlertSeverity.warning,
      isDismissed:        wasDismissed[alertId] ?? false,
    );

    shouldExist[alertId] = alert.toFirestore();
  }

  // ── Date resolution ───────────────────────────────────────────────────────────
  //
  // New medicines store precise epoch timestamps.
  // Medicines saved before this change fall back to parsing the display strings.

  /// Returns the expiry [DateTime] for [med], or null if unparseable.
  static DateTime? _resolveExpiryDate(MedicineData med) {
    // Prefer the precise timestamp stored by add_medicine_screen
    if (med.expiryTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(med.expiryTimestamp!);
    }
    // Fallback: parse "Apr 2025" → first day of that month
    return _parseMonthYear(med.expiryDateFull);
  }

  /// Returns the opened [DateTime] for [med], or null if not opened / unparseable.
  static DateTime? _resolveOpenedDate(MedicineData med) {
    if (med.openedTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(med.openedTimestamp!);
    }
    if (med.openedOn.isEmpty || med.openedOn == 'Not opened yet') return null;
    // Fallback: parse "12 Apr 2025"
    return _parseDayMonthYear(med.openedOn);
  }

  // ── String parsers ────────────────────────────────────────────────────────────

  static const _abbrs = {
    'Jan': 1, 'Feb': 2, 'Mar': 3,  'Apr': 4,
    'May': 5, 'Jun': 6, 'Jul': 7,  'Aug': 8,
    'Sep': 9, 'Oct': 10,'Nov': 11, 'Dec': 12,
  };

  /// "Apr 2025" → DateTime(2025, 4, 1)
  static DateTime? _parseMonthYear(String s) {
    final parts = s.trim().split(' ');
    if (parts.length != 2) return null;
    final month = _abbrs[parts[0]];
    final year  = int.tryParse(parts[1]);
    if (month == null || year == null) return null;
    return DateTime(year, month, 1);
  }

  /// "12 Apr 2025" → DateTime(2025, 4, 12)
  static DateTime? _parseDayMonthYear(String s) {
    final parts = s.trim().split(' ');
    if (parts.length != 3) return null;
    final day   = int.tryParse(parts[0]);
    final month = _abbrs[parts[1]];
    final year  = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
