# HEAVY WORK IN PROGRESS

# FTMS Flutter App

I started this app because I bought a rowing machine :) and the free app I was using didn't have the features I wanted and only worked by setting the trainer resistance: 
- target cadence
- target speed

By chance, the rowing machine supports FTMS protocol.

I was looking for a way to learn Flutter and this seemed like a good project to start with.

This app is designed to connect to FTMS (Fitness Machine Service) compatible exercise machines via Bluetooth. It provides a modern, user-friendly interface for managing workouts, tracking live machine data, and running structured training sessions.

It is based on flutter_ftms (https://github.com/Malte2036/flutter_ftms), a Flutter package for FTMS Bluetooth connectivity. Nice work, BTW, it saves a lot of time for translating complicated hex bluetooth codes into meaningful, human readable data.

## Main Features

- **FTMS Bluetooth Connectivity**: scan for and connect to FTMS-compatible fitness machines ( bikes, rowers) using Bluetooth Low Energy (BLE).
- **Live Data Display**: View real-time metrics from your connected machine, including speed, power, cadence, distance, and more.
- **Structured Training Sessions**: load and execute interval-based training sessions with support for both simple and grouped intervals (unit/group model).
- **Session Progress Tracking**: Visual progress bar and detailed feedback during workouts, including interval targets and completion status.

For build, test, and usage instructions, see the rest of this README.

## Features I'm thinking about

- Control the machine resistance. I tried to implement this but for some reason it doesn't work. I'm still digging into it.
- Training session editor (for the moment, the training sessions are manually defined files in `lib/training-sessions/`)
- Generate FIT files for upload to Strava or other fitness platforms.
- User preferences: FTP, max heart rate, etc

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.6.0 or newer recommended)
- Java 21 for Android builds
- Android Studio and/or Xcode for mobile builds (I'm on a Mac M4, I don't really know if it works on other platforms)
- Bluetooth activated on your device

### Install Dependencies
```zsh
flutter pub get
```

### Build and Run

#### Android (on a test phone)
1. Connect your Android device via USB and enable developer mode.
2. Build and install the APK:
   ```zsh
   flutter build apk --release
   flutter install
   flutter run -d <device_id>
   ```

#### macOS
```zsh
flutter run -d macos
```

## Running Tests
```zsh
flutter test
```

## Static Analysis
```zsh
flutter analyze
```

## Continuous Integration
CI is set up with GitHub Actions: see `.github/workflows/flutter_ci.yml` for build, analyze, and test jobs.

## Training Sessions
- Training sessions are defined as JSON files in `lib/training-sessions/`.
- Supports nested intervals (unit/group) and custom targets.

## Permissions
- **Android:** Requires Bluetooth and location permissions (see `AndroidManifest.xml`).
- **macOS/iOS:** Requires Bluetooth permissions in Info.plist.

## License
It's free to fork and use, but please don't use it for commercial purposes without asking me first.
