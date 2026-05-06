import 'package:flutter/material.dart';

/// A patient record — a first-class entity stored in Firestore.
///
/// Medicines are linked to patients via [MedicineData.patientId].
/// Prescriptions are linked via [PrescriptionData.patientId].
/// Patient no longer owns a medicines list — query DataService for that.
class PatientData {
  /// Firestore document ID.
  final String id;

  final String name;
  final String initials;
  final Color  avatarColor;

  /// Optional relationship label ('Self', 'Spouse', 'Child', 'Parent', 'Other').
  final String relationship;

  const PatientData({
    this.id           = '',
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.relationship = '',
  });

  /// Whether this patient has been saved to Firestore (has a real ID).
  bool get isExplicit => id.isNotEmpty;

  // ── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'name':         name,
        'initials':     initials,
        'avatarColor':  '#${avatarColor.value.toRadixString(16).substring(2).toUpperCase()}',
        'relationship': relationship,
      };

  factory PatientData.fromFirestore(String id, Map<String, dynamic> data) {
    return PatientData(
      id:           id,
      name:         data['name']         as String,
      initials:     data['initials']     as String,
      avatarColor:  _parseColor(data['avatarColor'] as String),
      relationship: (data['relationship'] as String?) ?? '',
    );
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  static Color _parseColor(String hex) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse('0xFF$cleaned'));
  }
}
