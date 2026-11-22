# 🏍️ ecu_logger 📊

🚀 **High-frequency CAN bus and OBD-II telemetry logger with Option 3 Minimalist Dashboard, dynamic PIN pocket lock overlay, and live Volumetric Efficiency fuel tuning accumulator.**

Built specifically for motorcycle telemetry acquisition and motorcycle ECU tuning on Flutter Android, `ecu_logger` brings seamless, crash-resilient 50–100Hz background logging to your road runs! Whether you are tuning Yamaha low-end fueling, diagnosing VVA camshaft transitions, or recording high-speed CAN streams from a NEXAS NexLink BLE adapter, `ecu_logger` provides a high-contrast GitHub Primer cockpit and continuous background disk logging right out of the box. ⚡

**Homepage & Documentation**: [ecu_logger Documentation](documentation/index.html)

---

## 📦 Requirements & Installation

Before running or building, ensure your environment meets the minimum version constraints defined in `pubspec.yaml`:

* **Flutter SDK (`>= 3.5.0 < 4.0.0`):** The Flutter cross-platform mobile SDK.
* **Dart SDK (`>= 3.5.0`):** Modern Dart language with sound null safety.
* **Android SDK (`minSdk >= 21`, `targetSdk 34+`):** Android 5.0+ with BLE 5.0 hardware support.
* **NEXAS NexLink BLE 5.0 or ELM327 OBD-II Adapter:** Hardware adapter plugged into motorcycle CAN diagnostic port.

Clone the repository and install dependencies via Flutter:

```bash
git clone https://github.com/AceBurgundy/ecu_logger.git
cd ecu_logger
flutter pub get
```

---

## 🚀 Core Features

* 📱 **Option 3 Minimalist Dashboard:** 6 high-contrast digital cards (Engine Speed, Throttle TPS %, Manifold MAP kPa, Volumetric Efficiency VE %, Coolant Temp ECT °C, and VVA Cam Status) rendered in GitHub Primer dark aesthetics (`#0D1117`).
* 🔒 **Translucent Pocket Lock Screen:** Full-page translucent modal with dynamic 4-digit PIN challenge (e.g. `Press "7 2 9 4" to open`) and glove-friendly numeric keypad. Prevents accidental pocket touches while preserving 100% background visibility and active logging.
* 📶 **Color-Coded Bluetooth FAB:** Dynamic floating action button reflecting real-time connection state: Grey (Disconnected), Orange (Scanning / Connecting), Green (Connected & Logging).
* 📁 **Dual-Stream File Storage:** Simultaneously writes raw incoming CAN hex frames (`raw_can_*.log`), structured CSV metrics (`telemetry_*.csv`), and the 16x11 tuning accumulator matrix (`remap_matrix_*.json`).
* ⚡ **Real-Time Speed-Density VE Calculation:** Evaluates thermodynamic Volumetric Efficiency using the ideal gas law and trims it via Short-Term and Long-Term Fuel Trims (STFT + LTFT).
* 🔄 **Lifecycle Auto-Save Engine:** Listens to `AppLifecycleState` hooks to automatically flush and save logs when the app is paused, backgrounded, or when Bluetooth disconnects.
* 📜 **Collapsible Monospace Log Drawer:** Rolling 200-line console drawer rendered in `Google Sans Code` with instant clear controls and packet counters.

---

## 💻 Quick Start & Usage Examples

Below is a step-by-step breakdown of how to launch `ecu_logger` and record live telemetry.

### 1️⃣ Initialization & Setup ⚙️

Launch the Flutter application on your target Android device (e.g. Pixel 8) with USB or wireless debugging enabled:

```bash
flutter run --release
```

On initial launch, `ecu_logger` automatically requests necessary Bluetooth Scan, Connect, and Storage permissions.

### 2️⃣ Pairing with NEXAS NexLink Adapter 📡

Tap the floating Bluetooth button in the bottom right corner of the screen:

```dart
// BleService initiates automated BLE discovery:
await BleService.instance.startScan();

// Discovered devices stream into the GitHub-styled modal:
BleService.instance.deviceListStream.listen((devices) {
  // Select "NEXAS NexLink" (MAC 8C:DE:52:DF:42:C3)
});
```

Selecting the adapter connects immediately and begins logging regardless of whether the motorcycle ignition is currently idling or at wide-open throttle.

### 3️⃣ Engaging Pocket Touch Lock 🔒

Before placing your phone into your riding jacket or pocket, tap the Lock FAB beside the Bluetooth button.

A translucent overlay activates with a randomized 4-digit PIN challenge:

```text
Press "3 8 1 5" to open
Pocket touch prevention active • Logging continues underneath
```

All 6 digital cockpit cards and the console log drawer remain completely visible and updating underneath. To unlock, simply tap the 4 challenge digits on the circular keypad.

### 4️⃣ Dual-Stream File Logging & Auto-Save 📁

All session files are automatically organized under `getApplicationDocumentsDirectory() / ecu_logs/`:

```dart
// Auto-flush triggered on BLE disconnect or app backgrounding:
FileLoggerService.instance.flush();
FileLoggerService.instance.saveRemapMatrix(TelemetryEngine.instance.remapMatrix);
```

---

## 🧩 The Logging & Matrix Architecture

`ecu_logger` utilizes strongly typed Dart singletons and services for deterministic performance:

* **`BleService`:** Manages BLE GATT connection lifecycle, notification subscriptions, and mock streaming for unit testing.
* **`Elm327Protocol`:** Cleans prompt tokens (`>`, `STOPPED`), parses Mode 01 standard PIDs, and extracts Yamaha raw CAN frame payloads (`0x770` RPM/TPS, `0x212` VVA bit).
* **`TelemetryEngine`:** Central `ChangeNotifier` calculating Speed-Density VE% and managing VVA hysteresis (engages at $\ge 7,400$ RPM when ECT $\ge 60^\circ$C; disengages at $< 7,000$ RPM).
* **`RemapMatrix`:** 16 RPM bins $\times$ 11 TPS bins accumulator maintaining dual-cam cell counts and average VE% for low-cam and high-cam profiles.
* **`FileLoggerService`:** Asynchronous non-blocking file sink streaming raw CAN logs, CSV rows, and formatted JSON matrix structures.

---

## 🗂️ Project Architecture

For contributors and reviewers, the codebase follows a clean, modular structure:

* `lib/main.dart`: App entry point and permission initialization.
* `lib/screens/home_screen.dart`: Primary screen assembling the 6-card dashboard, log drawer, and FABs.
* `lib/theme/github_theme.dart`: GitHub Primer dark theme palette and typography bindings (`Canela`, `Google Sans`, `Google Sans Code`).
* `lib/widgets/metric_card.dart`: High-contrast digital readout card with accent highlighting.
* `lib/widgets/log_drawer.dart`: Collapsible bottom monospace console drawer.
* `lib/widgets/lock_overlay.dart`: Translucent PIN challenge overlay with numeric keypad.
* `lib/widgets/bluetooth_dialog.dart`: GitHub-styled BLE device picker and disconnect dialog.
* `lib/widgets/toast_overlay.dart`: Top-centered floating status chips.
* `lib/services/ble_service.dart`: Bluetooth Low Energy connection and data streams.
* `lib/services/elm327_protocol.dart`: ELM327 AT command sequences and CAN frame decoders.
* `lib/services/telemetry_engine.dart`: VE calculations, VVA hysteresis, and metric state.
* `lib/services/file_logger_service.dart`: Asynchronous dual-stream disk writer.
* `lib/models/remap_matrix.dart`: 16x11 matrix bin accumulator and JSON serializer.
* `documentation/`: Interactive Material Design 3 single page documentation site.
* `test/`: Unit, widget, and protocol test suites.

---

## 🔗 Links & Repository

* **Repository & Source Code**: [https://github.com/AceBurgundy/ecu_logger](https://github.com/AceBurgundy/ecu_logger)
* **Interactive Documentation**: [documentation/index.html](documentation/index.html)
* **Issue Tracker**: [https://github.com/AceBurgundy/ecu_logger/issues](https://github.com/AceBurgundy/ecu_logger/issues)

---

## 📜 License

This project is licensed and distributed under the **Mozilla Public License (MPL-2.0)**.

---

## 👤 Author

* **Name:** AceBurgundy
* **Email:** samadriansabalo99@gmail.com
