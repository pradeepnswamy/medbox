import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alert_item.dart';

/// Manages all local push notifications for medicine alerts.
///
/// ## How it fits in
///
/// [AlertEngine.sync()] calls [scheduleAlertsNotifications] after every
/// Firestore batch write.  That method:
///   1. Cancels **all** currently pending notifications.
///   2. Re-schedules one notification per active (non-dismissed) alert.
///
/// This keeps the OS notification queue perfectly in sync with the alert
/// engine output without having to track deltas.
///
/// ## Notification strategy
///
/// | Alert type          | Trigger time  | Repeat     |
/// |---------------------|---------------|------------|
/// | Expiring – critical | 09:00 today*  | Daily      |
/// | Expiring – warning  | 09:00 today*  | None       |
/// | Opened              | 09:00 today*  | None       |
///
/// *If 09:00 has already passed today the notification fires at 09:00 tomorrow.
abstract final class NotificationService {
  // ── Plugin singleton ───────────────────────────────────────────────────────
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Android notification channels ──────────────────────────────────────────
  static const _chCritical = AndroidNotificationChannel(
    'carermeds_critical',
    'Critical Medicine Alerts',
    description: 'Medicines expiring within 7 days — shown daily until resolved.',
    importance: Importance.high,
  );

  static const _chWarning = AndroidNotificationChannel(
    'carermeds_warning',
    'Expiry Warnings',
    description: 'Medicines expiring within 30 days.',
    importance: Importance.defaultImportance,
  );

  static const _chOpened = AndroidNotificationChannel(
    'carermeds_opened',
    'Opened Medicine Alerts',
    description: 'Medicines that have been open longer than 3 months.',
    importance: Importance.defaultImportance,
  );

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Must be called once from [main] before [runApp].
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> init() async {
    if (_initialized) return;

    // Set up timezone so zonedSchedule fires in the device's local time.
    tz.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('[Notifications] Timezone detection failed, using UTC: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      // Permissions are requested separately via requestPermissions().
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create Android channels (no-op on iOS / if channels already exist).
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_chCritical);
    await androidPlugin?.createNotificationChannel(_chWarning);
    await androidPlugin?.createNotificationChannel(_chOpened);

    _initialized = true;
    debugPrint('[Notifications] Initialised ✓');
  }

  // ── Permission request ─────────────────────────────────────────────────────

  /// Asks the OS for notification permission.
  ///
  /// On iOS this shows the system permission alert (only once per install).
  /// On Android 13+ this requests the POST_NOTIFICATIONS runtime permission.
  /// Returns true if permission is granted.
  static Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Notifications] iOS permission: $granted');
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      debugPrint('[Notifications] Android permission: $granted');
      return granted ?? false;
    }

    return false;
  }

  // ── Main sync entry point ──────────────────────────────────────────────────

  /// Called by [AlertEngine.sync()] after every Firestore update.
  ///
  /// Cancels all pending notifications and re-schedules them from [alerts].
  /// Dismissed alerts are silently skipped.
  static Future<void> scheduleAlertsNotifications(
      List<AlertItem> alerts) async {
    if (!_initialized) await init();

    // Wipe the OS queue and rebuild it from scratch — fully idempotent.
    await _plugin.cancelAll();

    final active = alerts.where((a) => !a.isDismissed).toList();
    debugPrint('[Notifications] Scheduling ${active.length} notification(s)');

    for (final alert in active) {
      try {
        await _scheduleAt9am(
          alert,
          // Critical alerts repeat daily so the user gets reminded every
          // morning until they deal with the medicine.
          repeatDaily: alert.severity == AlertSeverity.critical,
        );
      } catch (e) {
        // Never crash the app over a scheduling failure.
        debugPrint('[Notifications] Could not schedule ${alert.id}: $e');
      }
    }
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  static Future<void> _scheduleAt9am(
    AlertItem alert, {
    required bool repeatDaily,
  }) async {
    final id      = _idFor(alert.id);
    final channel = _channelFor(alert);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.importance == Importance.high
            ? Priority.high
            : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(_body(alert)),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      _title(alert),
      _body(alert),
      _next9am(),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Required by flutter_local_notifications on iOS — tells the plugin to
      // treat the scheduled time as a wall-clock absolute time (not relative).
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // DateTimeComponents.time → repeat at the same clock time every day.
      // Omitting matchDateTimeComponents means fire once only.
      matchDateTimeComponents:
          repeatDaily ? DateTimeComponents.time : null,
    );
  }

  /// Cancels all pending notifications — call this on sign-out.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Pure helpers ───────────────────────────────────────────────────────────

  /// Next occurrence of 09:00 local time.
  /// Returns tomorrow at 09:00 if 09:00 has already passed today.
  static tz.TZDateTime _next9am() {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  /// Stable non-negative integer ID derived from the string alert ID.
  static int _idFor(String alertId) =>
      alertId.hashCode.abs() % 2000000000;

  static AndroidNotificationChannel _channelFor(AlertItem alert) {
    if (alert.type == AlertType.opened)           return _chOpened;
    if (alert.severity == AlertSeverity.critical) return _chCritical;
    return _chWarning;
  }

  static String _title(AlertItem alert) {
    switch (alert.type) {
      case AlertType.expiring:
        return alert.severity == AlertSeverity.critical
            ? '🚨 ${alert.medicineName} — expiring soon!'
            : '⚠️  ${alert.medicineName} — expiring';
      case AlertType.opened:
        return '💊 Check ${alert.medicineName}';
    }
  }

  static String _body(AlertItem alert) {
    switch (alert.type) {
      case AlertType.expiring:
        return '${alert.daysLabel} · For ${alert.patientName}';
      case AlertType.opened:
        return 'Opened ${alert.daysLabel} for ${alert.patientName}'
            " — verify it's still safe to use.";
    }
  }
}
