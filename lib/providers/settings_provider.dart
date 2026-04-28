import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// Holds user-configurable app preferences.
/// Lives in memory for the session — extend with SharedPreferences for persistence.
class AppSettings {
  final bool pushNotificationsEnabled;
  final bool expiryAlertsEnabled;
  final bool openedAlertsEnabled;

  const AppSettings({
    this.pushNotificationsEnabled = true,
    this.expiryAlertsEnabled      = true,
    this.openedAlertsEnabled      = true,
  });

  AppSettings copyWith({
    bool? pushNotificationsEnabled,
    bool? expiryAlertsEnabled,
    bool? openedAlertsEnabled,
  }) {
    return AppSettings(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      expiryAlertsEnabled:      expiryAlertsEnabled      ?? this.expiryAlertsEnabled,
      openedAlertsEnabled:      openedAlertsEnabled      ?? this.openedAlertsEnabled,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void setPushNotifications(bool v) =>
      state = state.copyWith(pushNotificationsEnabled: v);

  void setExpiryAlerts(bool v) =>
      state = state.copyWith(expiryAlertsEnabled: v);

  void setOpenedAlerts(bool v) =>
      state = state.copyWith(openedAlertsEnabled: v);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
