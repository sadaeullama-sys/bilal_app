# Veterinary Care Pro — Flutter Android starter

A starter Android app for a veterinary clinic and medicine shop.

## Included in this first build
- Admin demo login (`Admin` / `1234`) — change before real use.
- Local SQLite database stored on the device.
- Animal patient registration.
- Medicine item registration with batch, expiry, purchase/sale price and stock.
- Sales entries with paid and outstanding balance.
- Basic dashboard and reports.
- Urdu + English labels on key forms.

## Build APK
1. Install Flutter SDK and Android SDK.
2. Extract this ZIP and open the `Veterinary_Care_Pro_Flutter` folder.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```
4. For release APK:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions
Push this project to a GitHub repository. The workflow at
`.github/workflows/build-apk.yml` builds a release APK and uploads it as an artifact.

## Important next development steps
- Implement secure user/password management (the included login is demo-only).
- Add medicine sale line items and automatic stock deduction.
- Add treatment records, prescription PDF and appointment reminders.
- Add backup/restore and encrypted cloud sync after choosing a backend.
- Add role permissions, supplier ledger, expiry alerts and printable receipts.

This source ZIP is a functional starter, not a finished or production-certified veterinary/medical system.

## Barcode scanner update
- App logo is included at `assets/veterinary_logo.png`.
- Medicine form supports camera barcode scanning when registering a medicine.
- Sales screen supports scanning a registered medicine barcode, adding it to the cart,
  and automatically reducing stock after checkout.
- Barcode values must be entered/scanned when medicines are first registered.
