# CarerMeds — Firestore Database Design

## Overview

CarerMeds uses **Cloud Firestore** with a user-scoped collection tree.
All data lives under `users/{userId}/...` so security rules are simple
and one user's data is never visible to another.

---

## Collection Tree

```
users/
└── {userId}/                          ← one doc per Firebase Auth user
    ├── patients/
    │   └── {patientId}/               ← family member
    ├── medicines/
    │   └── {medicineId}/              ← one medicine box/pack
    ├── prescriptions/
    │   └── {prescriptionId}/          ← one hospital visit
    │       └── medicines/
    │           └── {rxMedicineId}/    ← medicine listed on that Rx
    └── alerts/
        └── {alertId}/                 ← pre-computed alert (expiry / opened)
```

---

## Document Schemas

### `users/{userId}`

Stores account-level profile data.

| Field | Type | Notes |
|---|---|---|
| `uid` | `string` | Mirrors Firebase Auth UID |
| `name` | `string` | Display name, e.g. "Pradeep" |
| `email` | `string` | Firebase Auth email |
| `createdAt` | `timestamp` | Account creation time |
| `updatedAt` | `timestamp` | Last profile update |

```json
{
  "uid": "abc123",
  "name": "Pradeep",
  "email": "pradeepnswamy@gmail.com",
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-04-12T10:30:00Z"
}
```

---

### `users/{userId}/patients/{patientId}`

One document per family member tracked in CarerMeds.

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | Mirrors document ID |
| `name` | `string` | Full name, e.g. "Ravi Kumar" |
| `initials` | `string` | Avatar initials, e.g. "RK" |
| `avatarColor` | `string` | Hex colour, e.g. "#4ECBA0" |
| `relationship` | `string` | "self" \| "spouse" \| "child" \| "parent" \| "other" |
| `dateOfBirth` | `timestamp?` | Optional — for age-based alerts |
| `notes` | `string` | Any general health notes |
| `createdAt` | `timestamp` | |
| `updatedAt` | `timestamp` | |

```json
{
  "id": "pat_ravi",
  "name": "Ravi Kumar",
  "initials": "RK",
  "avatarColor": "#4ECBA0",
  "relationship": "self",
  "dateOfBirth": null,
  "notes": "",
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-01-01T00:00:00Z"
}
```

---

### `users/{userId}/medicines/{medicineId}`

One document per medicine box/pack in the family cabinet.

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | Mirrors document ID |
| `name` | `string` | e.g. "Paracetamol 500mg" |
| `form` | `string` | "Tablet" \| "Capsule" \| "Syrup" \| "Drops" \| "Injection" |
| `dosage` | `string` | e.g. "500mg · 1 tablet × 3/day" |
| `quantity` | `string` | e.g. "10 tablets remaining" |
| `notes` | `string` | Special instructions |
| `photoUrl` | `string?` | Firebase Storage URL for medicine photo |
| `patientId` | `string` | Foreign key → `patients/{patientId}` |
| `patientName` | `string` | Denormalised for display without a join |
| `patientInitials` | `string` | Denormalised |
| `patientAvatarColor` | `string` | Denormalised hex colour |
| `acquiredDate` | `timestamp` | When the medicine was bought |
| `expiryDate` | `timestamp` | Expiry date printed on the pack |
| `isOpened` | `boolean` | Has the seal been broken? |
| `openedDate` | `timestamp?` | Date opened (null if unopened) |
| `linkedPrescriptionId` | `string?` | FK → `prescriptions/{id}` (null if OTC) |
| `linkedPrescriptionCause` | `string?` | Denormalised e.g. "Viral Fever" |
| `status` | `string` | Computed: "available" \| "expiring" \| "expired" \| "opened_too_long" |
| `createdAt` | `timestamp` | |
| `updatedAt` | `timestamp` | |

**Status computation rules** (applied when saving / Cloud Function on schedule):
- `expired` — `expiryDate < now`
- `expiring` — `expiryDate` within next 30 days
- `opened_too_long` — `isOpened == true` AND `openedDate` > 90 days ago
- `available` — everything else

```json
{
  "id": "med_amox",
  "name": "Amoxicillin 250mg",
  "form": "Capsule",
  "dosage": "250mg · 1 capsule × 3/day",
  "quantity": "6 capsules remaining",
  "notes": "Take with water. Complete full course.",
  "photoUrl": null,
  "patientId": "pat_ravi",
  "patientName": "Ravi Kumar",
  "patientInitials": "RK",
  "patientAvatarColor": "#4ECBA0",
  "acquiredDate": "2025-01-02T00:00:00Z",
  "expiryDate": "2025-04-20T00:00:00Z",
  "isOpened": true,
  "openedDate": "2025-01-02T00:00:00Z",
  "linkedPrescriptionId": "rx_viral_fever",
  "linkedPrescriptionCause": "Viral Fever",
  "status": "expiring",
  "createdAt": "2025-01-02T09:00:00Z",
  "updatedAt": "2025-04-15T10:00:00Z"
}
```

---

### `users/{userId}/prescriptions/{prescriptionId}`

One document per hospital/clinic visit.

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | Mirrors document ID |
| `cause` | `string` | Reason for visit, e.g. "Viral Fever" |
| `date` | `timestamp` | Visit date |
| `hospital` | `string` | Short name, e.g. "City Hospital" |
| `hospitalFull` | `string` | Full name + city |
| `doctor` | `string` | e.g. "Dr. Ramesh Kumar" |
| `notes` | `string` | Doctor's notes / follow-up instructions |
| `patientId` | `string` | FK → `patients/{patientId}` |
| `patientName` | `string` | Denormalised |
| `patientInitials` | `string` | Denormalised |
| `patientAvatarColor` | `string` | Denormalised |
| `medicineCount` | `number` | Cached count of medicines in subcollection |
| `photoUrls` | `string[]` | Firebase Storage URLs for Rx photos |
| `createdAt` | `timestamp` | |
| `updatedAt` | `timestamp` | |

```json
{
  "id": "rx_viral_fever",
  "cause": "Viral Fever",
  "date": "2025-04-12T00:00:00Z",
  "hospital": "City Hospital",
  "hospitalFull": "City Hospital, Chennai",
  "doctor": "Dr. Ramesh Kumar",
  "notes": "Follow up in 5 days if fever persists.",
  "patientId": "pat_ravi",
  "patientName": "Ravi Kumar",
  "patientInitials": "RK",
  "patientAvatarColor": "#4ECBA0",
  "medicineCount": 3,
  "photoUrls": [],
  "createdAt": "2025-04-12T11:00:00Z",
  "updatedAt": "2025-04-12T11:00:00Z"
}
```

---

### `users/{userId}/prescriptions/{prescriptionId}/medicines/{rxMedicineId}`

The medicines listed on a prescription (lightweight — not the same as the cabinet medicines).

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | Mirrors document ID |
| `name` | `string` | e.g. "Paracetamol 500mg" |
| `dosage` | `string` | e.g. "1 tab × 3/day" |
| `expiryDate` | `timestamp?` | If known |
| `status` | `string` | "available" \| "expiring" \| "opened" |
| `medicineId` | `string?` | FK → `medicines/{id}` if this Rx medicine is tracked in the cabinet |

```json
{
  "id": "rxmed_para",
  "name": "Paracetamol 500mg",
  "dosage": "1 tab × 3/day",
  "expiryDate": "2026-06-30T00:00:00Z",
  "status": "available",
  "medicineId": "med_para"
}
```

---

### `users/{userId}/alerts/{alertId}`

Pre-computed alerts — written by the app (or a Cloud Function) whenever a medicine
is saved/updated or on a daily schedule.  Storing them separately lets the Alerts
screen load instantly with a single collection query.

| Field | Type | Notes |
|---|---|---|
| `id` | `string` | Mirrors document ID |
| `type` | `string` | "expiring" \| "expired" \| "opened_too_long" |
| `severity` | `string?` | "critical" (≤7 days) \| "warning" (≤30 days) — null for `opened_too_long` |
| `medicineId` | `string` | FK → `medicines/{id}` |
| `medicineName` | `string` | Denormalised |
| `patientId` | `string` | FK → `patients/{id}` |
| `patientName` | `string` | Denormalised |
| `patientInitials` | `string` | Denormalised |
| `patientAvatarColor` | `string` | Denormalised |
| `daysValue` | `number` | Days until expiry, or days since opened |
| `description` | `string` | Human-readable detail sentence |
| `isDismissed` | `boolean` | User dismissed this alert |
| `createdAt` | `timestamp` | When the alert was first generated |
| `resolvedAt` | `timestamp?` | Set when the medicine is restocked / discarded |

```json
{
  "id": "alert_amox_expiry",
  "type": "expiring",
  "severity": "critical",
  "medicineId": "med_amox",
  "medicineName": "Amoxicillin 250mg",
  "patientId": "pat_ravi",
  "patientName": "Ravi Kumar",
  "patientInitials": "RK",
  "patientAvatarColor": "#4ECBA0",
  "daysValue": 4,
  "description": "Expires 20 Apr 2025 · Unopened bottles lose potency",
  "isDismissed": false,
  "createdAt": "2025-04-16T06:00:00Z",
  "resolvedAt": null
}
```

---

## Composite Indexes Required

Firestore requires explicit indexes for multi-field queries.

| Collection | Fields | Query use-case |
|---|---|---|
| `medicines` | `patientId ASC`, `expiryDate ASC` | Medicines by patient, sorted by expiry |
| `medicines` | `status ASC`, `expiryDate ASC` | Filter expiring/expired medicines |
| `medicines` | `patientId ASC`, `status ASC` | Patient's medicines by status |
| `prescriptions` | `patientId ASC`, `date DESC` | Patient's prescriptions newest-first |
| `prescriptions` | `date DESC` | All prescriptions newest-first |
| `alerts` | `isDismissed ASC`, `type ASC` | Active alerts by type |
| `alerts` | `isDismissed ASC`, `severity ASC` | Active alerts by severity |
| `alerts` | `medicineId ASC`, `isDismissed ASC` | Alerts for one medicine |

---

## Security Rules (outline)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Only the authenticated user can read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

---

## Migrating `DataService` from JSON → Firestore

The `DataService` singleton in `lib/services/data_service.dart` currently reads
local JSON assets.  To switch to Firestore, replace each method body:

```dart
// BEFORE (JSON asset)
Future<List<MedicineData>> getMedicines() async {
  final raw = await rootBundle.loadString('assets/data/medicines.json');
  final response = jsonDecode(raw);
  return (response['data'] as List)
      .map((e) => MedicineData.fromJson(e))
      .toList();
}

// AFTER (Firestore)
Future<List<MedicineData>> getMedicines() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final snap = await FirebaseFirestore.instance
      .collection('users/$uid/medicines')
      .orderBy('acquiredDate', descending: true)
      .get();
  return snap.docs
      .map((d) => MedicineData.fromJson({'id': d.id, ...d.data()}))
      .toList();
}
```

The `fromJson` factories on each model class already expect the same field
names used in this design, so no other code needs to change.

---

## Firebase Storage Structure

Medicine photos and prescription scan images are stored in Firebase Storage
under a parallel path:

```
gs://carermeds-app.appspot.com/
└── users/
    └── {userId}/
        ├── medicines/
        │   └── {medicineId}/
        │       └── photo.jpg
        └── prescriptions/
            └── {prescriptionId}/
                ├── rx_page_1.jpg
                └── rx_page_2.jpg
```

The download URL is saved into `medicines/{id}.photoUrl` or
`prescriptions/{id}.photoUrls[]` after upload.
