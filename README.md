# MedBox

A Flutter app for family caregivers to track medicines, prescriptions, and expiry alerts across multiple patients.

---

## Features

- **Medicine tracker** — log medicines with form, dosage, quantity, acquired and expiry dates, and a photo of the box
- **Prescription tracker** — record hospital visits with linked medicines and patient details
- **Patient profiles** — manage medicines across multiple family members
- **Alert engine** — automatic expiry and "opened too long" alerts with push notifications
- **Dashboard** — live overview with connectivity monitoring and auto-refresh on reconnect
- **Offline support** — Firestore persistence with graceful degradation and pull-to-refresh
- **Profile & settings** — notification preferences and account management

---

## Tech stack

| Layer | Package |
|---|---|
| Framework | Flutter 3.x / Dart 3.x |
| Auth | firebase_auth |
| Database | cloud_firestore |
| Navigation | go_router |
| State | flutter_riverpod |
| Notifications | flutter_local_notifications + timezone |
| Connectivity | connectivity_plus |
| Images | image_picker + image |
| Typography | google_fonts (DM Sans) |
| Local storage | path_provider |

---

## Prerequisites

- Flutter SDK `^3.11`
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- Xcode (iOS builds) or Android Studio (Android builds)
- Firebase CLI — `npm install -g firebase-tools`

---

## Getting started

### 1. Clone the repo

```bash
git clone https://github.com/pradeepnswamy/medbox.git
cd medbox
```

### 2. Add Firebase config files

These files are gitignored. Download them from the Firebase console and place them at:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Deploy Firestore security rules

```bash
firebase login
firebase use --add        # select your Firebase project
firebase deploy --only firestore
```

### 5. Run the app

```bash
flutter run
```

---

## Project structure

```
lib/
├── config/           # Theme, colours, router
├── models/           # MedicineData, PatientData, PrescriptionData, AlertItem
├── providers/        # Riverpod providers (app settings)
├── screens/
│   ├── auth/         # Login, sign-up
│   ├── dashboard/    # Home screen and components
│   ├── medicines/    # List, detail, add/edit
│   ├── prescriptions/
│   ├── patients/
│   ├── alerts/
│   ├── profile/
│   └── splash/
├── services/
│   ├── data_service.dart         # Firestore reads/writes with offline fallback
│   ├── alert_engine.dart         # Computes and syncs alerts
│   ├── notification_service.dart # Push notification scheduling
│   └── auth_service.dart
├── utils/
│   └── image_utils.dart          # Photo compression and resizing
└── widgets/                      # Shared UI components
```

---

## Firestore data model

All data is scoped to the authenticated user — no user can read or write another user's documents.

```
users/{userId}/
  medicines/{medicineId}
  patients/{patientId}
  prescriptions/{prescriptionId}
  alerts/{alertId}
```

Security rules enforce per-user isolation and validate required fields on every write. See [`firestore.rules`](firestore.rules).

---

## Building for production

```bash
# iOS
flutter build ipa

# Android
flutter build appbundle
```

Ensure `google-services.json` and `GoogleService-Info.plist` are present before building.

---

## Notes

- Firebase config files are gitignored — add them locally before each build
- Medicine photos are stored on-device in the app's documents directory; they are not uploaded to cloud storage
- Push notifications require a physical device — simulators do not support them
