# SalesDistribution (Flutter example)

This scaffold implements:
- Products management (Requirement 1)
- Taking orders (Requirement 2)
- Recording payments (cash/qr/invoice) and partial payments (Requirement 3)
- Orders list with total/paid/pending amounts (Requirement 4)
- CSV export (Requirement 5)

Run (PowerShell):
```powershell
cd sales_app
flutter pub get
flutter run
```

Notes:
- This scaffold uses in-memory lists for `products` and `orders` (demo). Add persistence (Hive or SQLite) to store across sessions.
- Payment: QR method is recorded only — actual QR payment flows require integrating a payment gateway or UPI/third-party SDKs.
- Export: The CSV export writes to a temporary file then opens the share dialog; on Android/iOS, `share_plus` will show share targets.

Next steps:
- Persist data with `hive` or `sqflite`
- Integrate real payment/QR flow
- Sync to backend for reporting
