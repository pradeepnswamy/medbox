import 'package:flutter/material.dart';

// ── RxMedicineStatus ──────────────────────────────────────────────────────────

enum RxMedicineStatus { available, expiring, opened }

// ── RxMedicine ────────────────────────────────────────────────────────────────

class RxMedicine {
  final String name;
  final String dosage;
  final String expiryLabel;
  final RxMedicineStatus status;
  // Optional link to a tracked medicine in the cabinet
  final String? medicineId;

  const RxMedicine({
    required this.name,
    required this.dosage,
    required this.expiryLabel,
    required this.status,
    this.medicineId,
  });

  // ── Firestore / JSON deserialization (camelCase keys) ─────────────────────

  factory RxMedicine.fromJson(Map<String, dynamic> json) {
    return RxMedicine(
      name:        json['name'] as String,
      dosage:      json['dosage'] as String,
      expiryLabel: json['expiryLabel'] as String,
      status:      _parseStatus(json['status'] as String),
      medicineId:  json['medicineId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':        name,
    'dosage':      dosage,
    'expiryLabel': expiryLabel,
    'status':      _statusString(status),
    'medicineId':  medicineId,
  };

  static RxMedicineStatus _parseStatus(String s) {
    switch (s) {
      case 'expiring': return RxMedicineStatus.expiring;
      case 'opened':   return RxMedicineStatus.opened;
      default:         return RxMedicineStatus.available;
    }
  }

  static String _statusString(RxMedicineStatus s) {
    switch (s) {
      case RxMedicineStatus.expiring: return 'expiring';
      case RxMedicineStatus.opened:   return 'opened';
      case RxMedicineStatus.available: return 'available';
    }
  }
}

// ── PrescriptionData ──────────────────────────────────────────────────────────

class PrescriptionData {
  final String id;
  final String cause;
  final String date;
  final String dateFull;
  final int year;
  final String hospital;
  final String hospitalFull;
  final String doctor;
  final String notes;
  final String patientName;
  final String patientInitials;
  final Color patientAvatarColor;
  final List<RxMedicine> medicines;

  const PrescriptionData({
    required this.id,
    required this.cause,
    required this.date,
    required this.dateFull,
    required this.year,
    required this.hospital,
    required this.hospitalFull,
    required this.doctor,
    required this.notes,
    required this.patientName,
    required this.patientInitials,
    required this.patientAvatarColor,
    required this.medicines,
  });

  // ── Firestore / JSON deserialization (camelCase keys) ─────────────────────

  factory PrescriptionData.fromJson(Map<String, dynamic> json) {
    return PrescriptionData(
      id:                 json['id'] as String,
      cause:              json['cause'] as String,
      date:               json['date'] as String,
      dateFull:           json['dateFull'] as String,
      year:               json['year'] as int,
      hospital:           json['hospital'] as String,
      hospitalFull:       json['hospitalFull'] as String,
      doctor:             json['doctor'] as String,
      notes:              json['notes'] as String,
      patientName:        json['patientName'] as String,
      patientInitials:    json['patientInitials'] as String,
      patientAvatarColor: _parseColor(json['patientAvatarColor'] as String),
      medicines:          (json['medicines'] as List<dynamic>)
                              .map((m) => RxMedicine.fromJson(m as Map<String, dynamic>))
                              .toList(),
    );
  }

  // ── toFirestore — medicines stored as array field, not subcollection ───────

  Map<String, dynamic> toFirestore() => {
    'cause':              cause,
    'date':               date,
    'dateFull':           dateFull,
    'year':               year,
    'hospital':           hospital,
    'hospitalFull':       hospitalFull,
    'doctor':             doctor,
    'notes':              notes,
    'patientName':        patientName,
    'patientInitials':    patientInitials,
    'patientAvatarColor': '#${patientAvatarColor.value.toRadixString(16).substring(2).toUpperCase()}',
    'medicineCount':      medicines.length,
    'medicines':          medicines.map((m) => m.toFirestore()).toList(),
  };

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Color _parseColor(String hex) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse('0xFF$cleaned'));
  }
}
