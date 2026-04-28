import 'package:flutter/material.dart';
import 'medicine.dart';

/// A patient record — either explicitly added by the user (has a Firestore [id])
/// or derived from the medicines collection ([id] is empty).
///
/// When loading the patients screen, both sources are merged by name so a
/// Firestore-stored patient and their medicine-linked entries appear as one row.
class PatientData {
  /// Firestore document ID. Empty string = medicine-derived only (not yet saved
  /// as an explicit patient record).
  final String id;

  final String name;
  final String initials;
  final Color  avatarColor;

  /// Optional relationship label ('Self', 'Spouse', 'Child', 'Parent', 'Other').
  /// Empty string means not specified.
  final String relationship;

  final List<MedicineData> medicines;

  const PatientData({
    this.id           = '',
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.relationship = '',
    required this.medicines,
  });

  // ── Derived counts ────────────────────────────────────────────────────────

  int  get medicineCount => medicines.length;
  int  get expiringCount => medicines.where((m) => m.topStatus == 'Expiring').length;
  int  get openedCount   => medicines.where((m) => m.topStatus == 'Opened').length;
  bool get hasAlerts     => expiringCount > 0 || openedCount > 0;

  /// Whether this patient was explicitly saved (not just medicine-derived).
  bool get isExplicit => id.isNotEmpty;

  // ── copyWith ──────────────────────────────────────────────────────────────

  PatientData copyWith({List<MedicineData>? medicines}) => PatientData(
        id:           id,
        name:         name,
        initials:     initials,
        avatarColor:  avatarColor,
        relationship: relationship,
        medicines:    medicines ?? this.medicines,
      );

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
      medicines:    [],
    );
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  static Color _parseColor(String hex) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse('0xFF$cleaned'));
  }

  /// Merges explicitly-stored Firestore patients with medicine-derived patients.
  ///
  /// Firestore patients take precedence (their id / relationship / color are
  /// kept). Medicines are appended to whichever patient record matches by name.
  /// Medicine-only patients (no explicit record) appear last, in encounter order.
  static List<PatientData> merge({
    required List<PatientData> stored,
    required List<MedicineData> medicines,
  }) {
    // Build a mutable map keyed by name, seeded from stored patients.
    final map = <String, PatientData>{
      for (final p in stored) p.name: p,
    };

    // Walk medicines and attach each to the matching patient entry.
    final medicineOrder = <String>[];
    for (final m in medicines) {
      if (!map.containsKey(m.patient)) {
        // Medicine-derived patient not in the explicit list
        medicineOrder.add(m.patient);
        map[m.patient] = PatientData(
          name:        m.patient,
          initials:    m.patientInitials,
          avatarColor: m.patientAvatarColor,
          medicines:   [],
        );
      }
      map[m.patient] = map[m.patient]!.copyWith(
        medicines: [...map[m.patient]!.medicines, m],
      );
    }

    // Return stored patients first (in their original order), then
    // any medicine-only patients that weren't in the explicit list.
    final result = stored.map((p) => map[p.name]!).toList();
    for (final name in medicineOrder) {
      result.add(map[name]!);
    }
    return result;
  }
}
