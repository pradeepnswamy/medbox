import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carermeds/models/medicine.dart';

void main() {
  // ── Shared test fixture ───────────────────────────────────────────────────────
  //
  // Mirrors exactly what Firestore would return when reading a medicine document,
  // with every optional field exercised (some null, some populated).

  const Map<String, dynamic> sampleJson = {
    'id':                    'med_001',
    'name':                  'Paracetamol 500mg',
    'patient':               'Amma',
    'patientInitials':       'AM',
    'patientAvatarColor':    '#4CAF50',
    'acquiredDate':          'Apr 2025',
    'acquiredDateFull':      '1 Apr 2025',
    'expiryLabel':           'Apr 2026',
    'expiryDateFull':        'Apr 2026',
    'expiryColor':           '#FF5722',
    'attentionColor':        null,
    'badges': [
      {'label': 'Available',   'style': 'available'},
      {'label': 'Rx',          'style': 'prescription'},
    ],
    'form':                  'Tablet',
    'dosage':                '500mg',
    'quantity':              '20 tablets',
    'notes':                 'Take after meals',
    'linkedPrescription':    'pres_001',
    'linkedPrescriptionMeta':'Apollo Hospital, Apr 2025',
    'isOpened':              false,
    'openedOn':              'Not opened yet',
    'topStatus':             'Available',
    'expiryTimestamp':       1774982400000,
    'openedTimestamp':       null,
    'photoPath':             null,
  };

  // ── fromJson ──────────────────────────────────────────────────────────────────

  group('MedicineData.fromJson', () {
    test('parses every required scalar field', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.id,       'med_001');
      expect(med.name,     'Paracetamol 500mg');
      expect(med.patient,  'Amma');
      expect(med.patientInitials, 'AM');
      expect(med.form,     'Tablet');
      expect(med.dosage,   '500mg');
      expect(med.quantity, '20 tablets');
      expect(med.notes,    'Take after meals');
      expect(med.isOpened, isFalse);
      expect(med.openedOn, 'Not opened yet');
      expect(med.topStatus,'Available');
    });

    test('parses hex colour strings into Color objects', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.patientAvatarColor, const Color(0xFF4CAF50));
      expect(med.expiryColor,        const Color(0xFFFF5722));
    });

    test('parses a null attentionColor as null', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.attentionColor, isNull);
    });

    test('parses a non-null attentionColor into a Color', () {
      final med = MedicineData.fromJson({
        ...sampleJson,
        'attentionColor': '#E91E63',
      });
      expect(med.attentionColor, const Color(0xFFE91E63));
    });

    test('parses the badges list with correct labels and styles', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.badges.length, 2);
      expect(med.badges[0].$1, 'Available');
      expect(med.badges[0].$2, BadgeStyle.available);
      expect(med.badges[1].$1, 'Rx');
      expect(med.badges[1].$2, BadgeStyle.prescription);
    });

    test('parses all five BadgeStyle values', () {
      for (final pair in [
        ('available',    BadgeStyle.available),
        ('expiring',     BadgeStyle.expiring),
        ('opened',       BadgeStyle.opened),
        ('prescription', BadgeStyle.prescription),
        ('neutral',      BadgeStyle.neutral),
      ]) {
        final json = {
          ...sampleJson,
          'badges': [{'label': 'Test', 'style': pair.$1}],
        };
        final med = MedicineData.fromJson(json);
        expect(med.badges[0].$2, pair.$2, reason: 'style: ${pair.$1}');
      }
    });

    test('parses optional timestamp fields', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.expiryTimestamp, 1774982400000);
      expect(med.openedTimestamp, isNull);
    });

    test('parses nullable linkedPrescription fields', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.linkedPrescription,     'pres_001');
      expect(med.linkedPrescriptionMeta, 'Apollo Hospital, Apr 2025');
    });

    test('parses null photoPath as null', () {
      final med = MedicineData.fromJson(sampleJson);
      expect(med.photoPath, isNull);
    });

    test('parses a non-null photoPath', () {
      final med = MedicineData.fromJson({
        ...sampleJson,
        'photoPath': '/data/user/0/com.pradeep.carermeds/files/box.jpg',
      });
      expect(med.photoPath,
          '/data/user/0/com.pradeep.carermeds/files/box.jpg');
    });
  });

  // ── toFirestore → fromJson round-trip ─────────────────────────────────────────

  group('MedicineData toFirestore → fromJson round-trip', () {
    MedicineData roundTrip(Map<String, dynamic> json) {
      final original = MedicineData.fromJson(json);
      return MedicineData.fromJson({'id': original.id, ...original.toFirestore()});
    }

    test('all scalar string fields survive the round-trip', () {
      final orig = MedicineData.fromJson(sampleJson);
      final rt   = roundTrip(sampleJson);
      expect(rt.id,          orig.id);
      expect(rt.name,        orig.name);
      expect(rt.patient,     orig.patient);
      expect(rt.patientInitials, orig.patientInitials);
      expect(rt.form,        orig.form);
      expect(rt.dosage,      orig.dosage);
      expect(rt.quantity,    orig.quantity);
      expect(rt.notes,       orig.notes);
      expect(rt.openedOn,    orig.openedOn);
      expect(rt.topStatus,   orig.topStatus);
    });

    test('colour fields survive the round-trip', () {
      final orig = MedicineData.fromJson(sampleJson);
      final rt   = roundTrip(sampleJson);
      expect(rt.patientAvatarColor, orig.patientAvatarColor);
      expect(rt.expiryColor,        orig.expiryColor);
    });

    test('attentionColor survives when non-null', () {
      final json = {...sampleJson, 'attentionColor': '#9C27B0'};
      final orig = MedicineData.fromJson(json);
      final rt   = roundTrip(json);
      expect(rt.attentionColor, orig.attentionColor);
    });

    test('null attentionColor survives the round-trip', () {
      final rt = roundTrip(sampleJson);
      expect(rt.attentionColor, isNull);
    });

    test('badges survive the round-trip (label and style)', () {
      final orig = MedicineData.fromJson(sampleJson);
      final rt   = roundTrip(sampleJson);
      expect(rt.badges.length, orig.badges.length);
      for (var i = 0; i < orig.badges.length; i++) {
        expect(rt.badges[i].$1, orig.badges[i].$1, reason: 'label at $i');
        expect(rt.badges[i].$2, orig.badges[i].$2, reason: 'style at $i');
      }
    });

    test('boolean isOpened survives the round-trip', () {
      final rt = roundTrip({...sampleJson, 'isOpened': true});
      expect(rt.isOpened, isTrue);
    });

    test('integer timestamps survive the round-trip', () {
      final orig = MedicineData.fromJson(sampleJson);
      final rt   = roundTrip(sampleJson);
      expect(rt.expiryTimestamp, orig.expiryTimestamp);
      expect(rt.openedTimestamp, orig.openedTimestamp);
    });

    test('null photoPath survives the round-trip', () {
      final rt = roundTrip(sampleJson);
      expect(rt.photoPath, isNull);
    });

    test('non-null photoPath survives the round-trip', () {
      final json = {...sampleJson, 'photoPath': '/files/box.jpg'};
      final rt   = roundTrip(json);
      expect(rt.photoPath, '/files/box.jpg');
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────────

  group('MedicineData.copyWith', () {
    test('updates the name field and leaves everything else unchanged', () {
      final original = MedicineData.fromJson(sampleJson);
      final copy = original.copyWith(name: 'Ibuprofen 400mg');
      expect(copy.name,    'Ibuprofen 400mg');
      expect(copy.patient, original.patient); // untouched
      expect(copy.form,    original.form);    // untouched
    });

    test('updates isOpened from false to true', () {
      final original = MedicineData.fromJson(sampleJson);
      final copy = original.copyWith(isOpened: true);
      expect(copy.isOpened, isTrue);
    });

    test('can explicitly set photoPath to null (sentinel pattern)', () {
      final original = MedicineData.fromJson({
        ...sampleJson,
        'photoPath': '/files/box.jpg',
      });
      expect(original.photoPath, isNotNull);

      final copy = original.copyWith(photoPath: null);
      expect(copy.photoPath, isNull);
    });

    test('updating photoPath to a new value works', () {
      final original = MedicineData.fromJson(sampleJson);
      final copy = original.copyWith(photoPath: '/new/path/photo.jpg');
      expect(copy.photoPath, '/new/path/photo.jpg');
    });

    test('returns a new object — does not mutate the original', () {
      final original = MedicineData.fromJson(sampleJson);
      original.copyWith(name: 'Changed');
      expect(original.name, 'Paracetamol 500mg');
    });

    test('updating multiple fields at once works', () {
      final original = MedicineData.fromJson(sampleJson);
      final copy = original.copyWith(
        dosage:   '1000mg',
        quantity: '10 tablets',
        notes:    'Take with water',
      );
      expect(copy.dosage,   '1000mg');
      expect(copy.quantity, '10 tablets');
      expect(copy.notes,    'Take with water');
      // Unchanged field
      expect(copy.name, original.name);
    });
  });
}
