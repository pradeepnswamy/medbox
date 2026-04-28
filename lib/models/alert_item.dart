import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum AlertType { expiring, opened }

enum AlertSeverity { critical, warning }

// ── AlertItem ─────────────────────────────────────────────────────────────────

class AlertItem {
  final String id;
  final String medicineName;
  final int daysValue;
  final String daysLabel;
  final String description;
  final String patientName;
  final String patientInitials;
  final Color patientAvatarColor;
  final AlertType type;
  final AlertSeverity? severity;

  // Mutable — toggled locally when user dismisses/restores an alert
  bool isDismissed;

  AlertItem({
    required this.id,
    required this.medicineName,
    required this.daysValue,
    required this.daysLabel,
    required this.description,
    required this.patientName,
    required this.patientInitials,
    required this.patientAvatarColor,
    required this.type,
    this.severity,
    this.isDismissed = false,
  });

  // ── Firestore / JSON deserialization (camelCase keys) ─────────────────────

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id:                 json['id'] as String,
      medicineName:       json['medicineName'] as String,
      daysValue:          json['daysValue'] as int,
      daysLabel:          json['daysLabel'] as String,
      description:        json['description'] as String,
      patientName:        json['patientName'] as String,
      patientInitials:    json['patientInitials'] as String,
      patientAvatarColor: _parseColor(json['patientAvatarColor'] as String),
      type:               json['type'] == 'expiring'
                              ? AlertType.expiring
                              : AlertType.opened,
      severity:           _parseSeverity(json['severity']),
      isDismissed:        (json['isDismissed'] as bool?) ?? false,
    );
  }

  // ── toFirestore ───────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
    'medicineName':       medicineName,
    'daysValue':          daysValue,
    'daysLabel':          daysLabel,
    'description':        description,
    'patientName':        patientName,
    'patientInitials':    patientInitials,
    'patientAvatarColor': '#${patientAvatarColor.value.toRadixString(16).substring(2).toUpperCase()}',
    'type':               type == AlertType.expiring ? 'expiring' : 'opened',
    'severity':           severity == null
                              ? null
                              : severity == AlertSeverity.critical
                                  ? 'critical'
                                  : 'warning',
    'isDismissed':        isDismissed,
  };

  // ── Computed colours (used by AlertCard) ──────────────────────────────────

  Color get accentColor {
    if (type == AlertType.expiring && severity == AlertSeverity.critical) {
      return AppColors.danger;
    }
    return AppColors.warning;
  }

  Color get cardBg {
    if (type == AlertType.expiring && severity == AlertSeverity.critical) {
      return AppColors.dangerLight;
    }
    return AppColors.warningLight;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Color _parseColor(String hex) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse('0xFF$cleaned'));
  }

  static AlertSeverity? _parseSeverity(dynamic s) {
    if (s == null) return null;
    return s == 'critical' ? AlertSeverity.critical : AlertSeverity.warning;
  }
}
