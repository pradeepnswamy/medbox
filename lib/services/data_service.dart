import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/medicine.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../models/alert_item.dart';
import 'alert_engine.dart';

/// Singleton service that reads from / writes to Firestore.
///
/// All data lives under users/{uid}/ so one user never sees another's data.
///
/// ## Offline strategy
///
/// Firestore persistence is enabled in [main.dart], so every successful fetch
/// is automatically cached on-device.  [_fetch] enforces an 8-second timeout
/// on every read:
///
///   • **Online** — query resolves from the server, result is cached.
///   • **Offline + cached data** — Firestore returns the local copy instantly
///     (well under the timeout threshold).
///   • **Offline + no cache** — query hangs, timeout fires, falls back to the
///     Firestore local cache (returns empty if truly nothing is cached), then
///     throws [OfflineException] so callers can show a message.
///
/// Usage:
///   final meds = await DataService.instance.getMedicines();
class DataService {
  DataService._();
  static final DataService instance = DataService._();

  static const _kTimeout = Duration(seconds: 8);

  // ── Firestore & Auth references ───────────────────────────────────────────

  FirebaseFirestore get _db   => FirebaseFirestore.instance;
  FirebaseAuth      get _auth => FirebaseAuth.instance;

  /// Returns the current user's UID, or null if not signed in.
  String? get _uid => _auth.currentUser?.uid;

  /// Base collection path for the signed-in user.
  CollectionReference _col(String name) =>
      _db.collection('users/$_uid/$name');

  // ── Offline-resilient fetch ───────────────────────────────────────────────

  /// Executes [query] with a hard timeout.
  ///
  /// On timeout (offline + no cache available yet) falls back to the local
  /// Firestore cache.  If the cache is also empty, throws [OfflineException].
  Future<QuerySnapshot<Object?>> _fetch(Query query) async {
    try {
      return await query.get().timeout(_kTimeout);
    } on TimeoutException {
      debugPrint('[DataService] Server timeout — serving from local cache');
      try {
        return await query.get(const GetOptions(source: Source.cache));
      } catch (_) {
        throw OfflineException();
      }
    }
  }

  // ── Medicines ─────────────────────────────────────────────────────────────

  Future<List<MedicineData>> getMedicines() async {
    if (_uid == null) return [];
    final snap = await _fetch(_col('medicines'));
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MedicineData.fromJson({'id': doc.id, ...data});
    }).toList();
  }

  Future<void> addMedicine(MedicineData med) async {
    if (_uid == null) return;
    await _col('medicines')
        .doc(med.id.isEmpty ? null : med.id)
        .set(med.toFirestore());
    AlertEngine.sync(); // fire-and-forget — keep alerts in sync
  }

  Future<void> updateMedicine(MedicineData med) async {
    if (_uid == null) return;
    await _col('medicines').doc(med.id).update(med.toFirestore());
    AlertEngine.sync(); // fire-and-forget
  }

  Future<void> deleteMedicine(String medicineId, {String? photoPath}) async {
    if (_uid == null) return;

    // Delete the local photo file before removing the Firestore document so
    // we never leave orphaned files on disk if the Firestore call fails.
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final file = File(photoPath);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('[DataService] Could not delete photo file: $e');
        // Non-fatal — proceed with Firestore delete regardless.
      }
    }

    await _col('medicines').doc(medicineId).delete();
    AlertEngine.sync(); // fire-and-forget — cleans up stale alerts
  }

  // ── Patients ──────────────────────────────────────────────────────────────

  Future<List<PatientData>> getPatients() async {
    if (_uid == null) return [];
    final snap = await _fetch(_col('patients'));
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PatientData.fromFirestore(doc.id, data);
    }).toList();
  }

  /// Convenience: returns all patients keyed by Firestore document ID.
  /// Useful for O(1) patient-name lookups when rendering medicine lists.
  Future<Map<String, PatientData>> getPatientsMap() async {
    final list = await getPatients();
    return {for (final p in list) p.id: p};
  }

  /// Fetches medicines belonging to a specific patient using a server-side
  /// Firestore filter — more efficient than loading all and filtering in Dart.
  Future<List<MedicineData>> getMedicinesByPatient(String patientId) async {
    if (_uid == null) return [];
    final snap = await _fetch(
      _col('medicines').where('patientId', isEqualTo: patientId),
    );
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return MedicineData.fromJson({'id': doc.id, ...data});
    }).toList();
  }

  /// Fetches a single patient by Firestore document ID.
  /// Returns null if the document does not exist.
  Future<PatientData?> getPatient(String patientId) async {
    if (_uid == null) return null;
    try {
      final doc = await _col('patients').doc(patientId).get()
          .timeout(_kTimeout);
      if (!doc.exists) return null;
      return PatientData.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } on TimeoutException {
      return null;
    }
  }

  Future<void> addPatient(PatientData patient) async {
    if (_uid == null) return;
    await _col('patients').add(patient.toFirestore());
  }

  /// Deletes the patient and unlinks any medicines that referenced them
  /// (sets their patientId to null so they become OTC/unassigned).
  Future<void> deletePatient(String patientId) async {
    if (_uid == null) return;

    // Unlink medicines before deleting the patient so they are never orphaned.
    final linkedMeds = await getMedicinesByPatient(patientId);
    if (linkedMeds.isNotEmpty) {
      final batch = _db.batch();
      for (final med in linkedMeds) {
        batch.update(
          _col('medicines').doc(med.id),
          {'patientId': null},
        );
      }
      await batch.commit();
    }

    await _col('patients').doc(patientId).delete();
  }

  // ── Prescriptions ─────────────────────────────────────────────────────────

  Future<List<PrescriptionData>> getPrescriptions() async {
    if (_uid == null) return [];
    final snap = await _fetch(
      _col('prescriptions').orderBy('date', descending: true),
    );
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PrescriptionData.fromJson({'id': doc.id, ...data});
    }).toList();
  }

  Future<void> addPrescription(PrescriptionData rx) async {
    if (_uid == null) return;
    await _col('prescriptions')
        .doc(rx.id.isEmpty ? null : rx.id)
        .set(rx.toFirestore());
  }

  Future<void> updatePrescription(PrescriptionData rx) async {
    if (_uid == null || rx.id.isEmpty) return;
    await _col('prescriptions').doc(rx.id).update(rx.toFirestore());
  }

  Future<void> deletePrescription(String prescriptionId) async {
    if (_uid == null) return;
    await _col('prescriptions').doc(prescriptionId).delete();
  }

  // ── Alerts ────────────────────────────────────────────────────────────────

  Future<List<AlertItem>> getAlerts() async {
    if (_uid == null) return [];
    final snap = await _fetch(
      _col('alerts').where('isDismissed', isEqualTo: false),
    );
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AlertItem.fromJson({'id': doc.id, ...data});
    }).toList();
  }

  Future<void> dismissAlert(String alertId) async {
    if (_uid == null) return;
    await _col('alerts').doc(alertId).update({'isDismissed': true});
  }

  Future<void> restoreAlert(String alertId) async {
    if (_uid == null) return;
    await _col('alerts').doc(alertId).update({'isDismissed': false});
  }
}

// ── Offline exception ─────────────────────────────────────────────────────────

/// Thrown by [DataService] when a query times out AND the local Firestore
/// cache has no data to serve (i.e. the user has never loaded this data online).
class OfflineException implements Exception {
  @override
  String toString() =>
      'No internet connection and no locally cached data available.';
}
