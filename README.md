# QML Predictive Back Demo

Android 13+ predictive back gesture support in Qt 6 / QML.

## Features

- **Exit-to-home switch** — toggle whether the back gesture exits the app or is handled internally
- **Edge highlight** — glowing gradient bar on the swipe edge, grows with gesture progress
- **Touch-point orb** — follows your finger along the edge
- **Progress indicator** — live percentage pill and progress bar
- **Success animation** — expanding rings + canvas particle burst + checkmark on gesture commit

## Requirements

| Component | Version |
|-----------|---------|
| Qt        | 6.5+    |
| Android SDK target | 34 (Android 14) |
| Android SDK minimum | 33 (Android 13) |
| NDK       | 26.x    |

`OnBackAnimationCallback` (per-frame progress + touch position) requires Android 14 (API 34).
On Android 13 (API 33) the gesture commits or cancels without intermediate progress updates.

## Build

```bash
# Using Qt's cmake wrapper (adjust path to your Qt installation)
/path/to/Qt/6.7.3/android_arm64_v8a/bin/qt-cmake \
  -S . -B build \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-33 \
  -DQT_HOST_PATH=/path/to/Qt/6.7.3/gcc_64

cmake --build build --parallel
```

The resulting APK is at `build/android-build/build/outputs/apk/debug/`.

## Architecture

```
main.cpp                    — creates BackGestureHandler, loads QML
BackGestureHandler.h/.cpp   — QObject singleton; JNI bridge to Java
android/
  AndroidManifest.xml       — enableOnBackInvokedCallback="true"
  src/.../MainActivity.java — registers OnBackAnimationCallback
Main.qml                    — root window, switch, status card
EdgeHighlight.qml           — animated edge glow + orb
SuccessAnimation.qml        — rings + particles + checkmark
```

## How it works

1. `AndroidManifest.xml` sets `android:enableOnBackInvokedCallback="true"` — this opts the app into the new predictive-back system and disables the legacy `onBackPressed`.
2. `MainActivity.java` registers an `OnBackAnimationCallback` (API 34) or `OnBackInvokedCallback` (API 33) with the window's `OnBackInvokedDispatcher`.
3. Each gesture event calls a `native` method that routes through JNI into `BackGestureHandler.cpp` (queued to the Qt thread).
4. `BackGestureHandler` emits Qt signals consumed by QML via a `Connections` block.
5. The QML switch calls `BackGestureHandler.exitOnBack = <bool>` which triggers re-registration of the Java callback on the Android UI thread.
