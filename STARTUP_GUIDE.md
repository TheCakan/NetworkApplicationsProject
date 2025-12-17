# Currency Exchange App - Startup Guide

## Description of Operation

**What it does:**
- Users register/login
- View currency exchange rates (USD, EUR, GBP, PLN)
- Exchange currencies
- View transaction history

**How it works:**
- Backend server (Node.js) runs on port 8080
- Flutter app connects to backend
- MySQL database stores user data and transactions

---

## Startup Instructions

### Step 1: Start Backend
```bash
cd "currency app final"
node server.js
```

### Step 2: Run App
```bash
cd mobile
flutter run -d chrome
```

**For Android:**
```bash
flutter run -d emulator-5554
```

---

## Troubleshooting

- **"Failed to fetch"** → Backend not running. Start backend first.
- **Android error** → `cd mobile/android && chmod +x gradlew`
- **App won't start** → `flutter clean && flutter pub get`
