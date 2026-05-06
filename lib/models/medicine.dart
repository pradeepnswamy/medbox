import 'package:flutter/material.dart';

// ── BadgeStyle ────────────────────────────────────────────────────────────────

enum BadgeStyle {
  available,    // green
  expiring,     // red
  opened,       // amber
  prescription, // blue/teal
  neutral,      // grey (Unopened, No Rx, etc.)
}

// ── MedicineData ──────────────────────────────────────────────────────────────

class MedicineData {
  final String id;
  final String name;

  /// ID of the [PatientData] this medicine belongs to.
  /// Null for OTC / family-shared medicines with no specific patient.
  final String? patientId;

  final String acquiredDate;
  final String acquiredDateFull;
  final String expiryLabel;
  final String expiryDateFull;
  final Color expiryColor;
  final Color? attentionColor;
  final List<(String, BadgeStyle)> badges;
  // Detail-only fields
  final String form;
  final String dosage;
  final String quantity;
  final String notes;
  final String? linkedPrescription;
  final String? linkedPrescriptionMeta;
  final bool isOpened;
  final String openedOn;
  final String topStatus;

  /// Raw timestamps (milliseconds since epoch) stored in Firestore for
  /// precise alert computation.
  final int? expiryTimestamp;
  final int? openedTimestamp;

  /// Absolute path to a medicine box photo stored in the app's documents
  /// directory. Null when no photo has been added.
  final String? photoPath;

  const MedicineData({
    required this.id,
    required this.name,
    this.patientId,
    required this.acquiredDate,
    required this.acquiredDateFull,
    required this.expiryLabel,
    required this.expiryDateFull,
    required this.expiryColor,
    this.attentionColor,
    required this.badges,
    required this.form,
    required this.dosage,
    required this.quantity,
    required this.notes,
    this.linkedPrescription,
    this.linkedPrescriptionMeta,
    required this.isOpened,
    required this.openedOn,
    required this.topStatus,
    this.expiryTimestamp,
    this.openedTimestamp,
    this.photoPath,
  });

  MedicineData copyWith({
    String? id,
    String? name,
    Object? patientId = _sentinel,
    String? acquiredDate,
    String? acquiredDateFull,
    String? expiryLabel,
    String? expiryDateFull,
    Color? expiryColor,
    Color? attentionColor,
    List<(String, BadgeStyle)>? badges,
    String? form,
    String? dosage,
    String? quantity,
    String? notes,
    String? linkedPrescription,
    String? linkedPrescriptionMeta,
    bool? isOpened,
    String? openedOn,
    String? topStatus,
    int? expiryTimestamp,
    int? openedTimestamp,
    Object? photoPath = _sentinel,
  }) {
    return MedicineData(
      id:                    id ?? this.id,
      name:                  name ?? this.name,
      patientId:             identical(patientId, _sentinel)
                                 ? this.patientId
                                 : patientId as String?,
      acquiredDate:          acquiredDate ?? this.acquiredDate,
      acquiredDateFull:      acquiredDateFull ?? this.acquiredDateFull,
      expiryLabel:           expiryLabel ?? this.expiryLabel,
      expiryDateFull:        expiryDateFull ?? this.expiryDateFull,
      expiryColor:           expiryColor ?? this.expiryColor,
      attentionColor:        attentionColor ?? this.attentionColor,
      badges:                badges ?? this.badges,
      form:                  form ?? this.form,
      dosage:                dosage ?? this.dosage,
      quantity:              quantity ?? this.quantity,
      notes:                 notes ?? this.notes,
      linkedPrescription:    linkedPrescription ?? this.linkedPrescription,
      linkedPrescriptionMeta: linkedPrescriptionMeta ?? this.linkedPrescriptionMeta,
      isOpened:              isOpened ?? this.isOpened,
      openedOn:              openedOn ?? this.openedOn,
      topStatus:             topStatus ?? this.topStatus,
      expiryTimestamp:       expiryTimestamp ?? this.expiryTimestamp,
      openedTimestamp:       openedTimestamp ?? this.openedTimestamp,
      photoPath:             identical(photoPath, _sentinel)
                                 ? this.photoPath
                                 : photoPath as String?,
    );
  }

  static const Object _sentinel = Object();

  // ── Firestore / JSON deserialization ──────────────────────────────────────

  factory MedicineData.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'] as List<dynamic>;
    final badges = rawBadges.map<(String, BadgeStyle)>((b) {
      final map = b as Map<String, dynamic>;
      return (map['label'] as String, _parseBadgeStyle(map['style'] as String));
    }).toList();

    return MedicineData(
      id:                    json['id'] as String,
      name:                  json['name'] as String,
      patientId:             json['patientId'] as String?,
      acquiredDate:          json['acquiredDate'] as String,
      acquiredDateFull:      json['acquiredDateFull'] as String,
      expiryLabel:           json['expiryLabel'] as String,
      expiryDateFull:        json['expiryDateFull'] as String,
      expiryColor:           _parseColor(json['expiryColor'] as String),
      attentionColor:        json['attentionColor'] != null
                                 ? _parseColor(json['attentionColor'] as String)
                                 : null,
      badges:                badges,
      form:                  json['form'] as String,
      dosage:                json['dosage'] as String,
      quantity:              json['quantity'] as String,
      notes:                 json['notes'] as String,
      linkedPrescription:    json['linkedPrescription'] as String?,
      linkedPrescriptionMeta: json['linkedPrescriptionMeta'] as String?,
      isOpened:              json['isOpened'] as bool,
      openedOn:              json['openedOn'] as String,
      topStatus:             json['topStatus'] as String,
      expiryTimestamp:       json['expiryTimestamp'] as int?,
      openedTimestamp:       json['openedTimestamp'] as int?,
      photoPath:             json['photoPath'] as String?,
    );
  }

  // ── toFirestore ───────────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
    'name':                  name,
    'patientId':             patientId,
    'acquiredDate':          acquiredDate,
    'acquiredDateFull':      acquiredDateFull,
    'expiryLabel':           expiryLabel,
    'expiryDateFull':        expiryDateFull,
    'expiryColor':           '#${expiryColor.value.toRadixString(16).substring(2).toUpperCase()}',
    'attentionColor':        attentionColor != null
                                 ? '#${attentionColor!.value.toRadixString(16).substring(2).toUpperCase()}'
                                 : null,
    'badges':                badges.map((b) => {'label': b.$1, 'style': _badgeStyleString(b.$2)}).toList(),
    'form':                  form,
    'dosage':                dosage,
    'quantity':              quantity,
    'notes':                 notes,
    'linkedPrescription':    linkedPrescription,
    'linkedPrescriptionMeta': linkedPrescriptionMeta,
    'isOpened':              isOpened,
    'openedOn':              openedOn,
    'topStatus':             topStatus,
    'expiryTimestamp':       expiryTimestamp,
    'openedTimestamp':       openedTimestamp,
    'photoPath':             photoPath,
  };

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Color _parseColor(String hex) {
    final cleaned = hex.startsWith('#') ? hex.substring(1) : hex;
    return Color(int.parse('0xFF$cleaned'));
  }

  static BadgeStyle _parseBadgeStyle(String s) {
    switch (s) {
      case 'expiring':     return BadgeStyle.expiring;
      case 'opened':       return BadgeStyle.opened;
      case 'prescription': return BadgeStyle.prescription;
      case 'neutral':      return BadgeStyle.neutral;
      default:             return BadgeStyle.available;
    }
  }

  static String _badgeStyleString(BadgeStyle s) {
    switch (s) {
      case BadgeStyle.expiring:     return 'expiring';
      case BadgeStyle.opened:       return 'opened';
      case BadgeStyle.prescription: return 'prescription';
      case BadgeStyle.neutral:      return 'neutral';
      case BadgeStyle.available:    return 'available';
    }
  }
}
