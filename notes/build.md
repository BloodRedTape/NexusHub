# Android build

## How to build

```
flutter build apk --release
```

Requires Flutter 3.47+ and JDK 17. The SDK and JDK paths are set globally via
`flutter config`, so no environment variables are needed:

```
flutter config --android-sdk <path to android sdk>
flutter config --jdk-dir <path to jdk 17>
```

Output: `build\app\outputs\flutter-apk\app-release.apk`.

## Why 3.47 and not 3.16

The build script used to call an old Flutter 3.16 SDK, and the build failed with
`Build failed due to use of deprecated Android v1 embedding`.

The message is misleading: this project is a proper v2 one (`MainActivity`
extends `io.flutter.embedding.android.FlutterActivity`, the manifest declares
`flutterEmbedding=2`). The real cause is that the Gradle config here uses the
Kotlin DSL (`build.gradle.kts`, `settings.gradle.kts`), while 3.16 can only read
Groovy `build.gradle`. Failing to find those, it falls back to the v1 heuristic,
looks for `android/AndroidManifest.xml` (the old layout) and gives up.

Building this project with 3.16 is impossible without converting Gradle back to
Groovy. `local.properties` and AGP 8.x were already configured for 3.47 anyway.

## Impeller was a red herring

The build script carried a `--no-enable-impeller` flag and the manifest had
`EnableImpeller=false`. Neither ever did anything:

- `--no-enable-impeller` is not an option of `flutter build apk` in any version
  (it belongs to `flutter run`), so the build never even started with it;
- in 3.16 (November 2023) Impeller was not yet used on Android — there was
  nothing to disable, so both the flag and the meta-data were no-ops.

So the startup crash on the tablet (Android 7, API 25) has some other cause.
Diagnose it with `adb logcat`.

Note for later: on 3.47 Impeller is the only renderer on Android and can no
longer be turned off. If the crash turns out to be rendering-related,
`--enable-software-rendering` is available to test that hypothesis.

## Toolchain bumps

Flutter 3.47 requires a newer toolchain. The versions were raised one by one —
each error only surfaced after the previous one was fixed:

| What | From | To | Reason |
|---|---|---|---|
| JDK | 25 | 17 | Gradle 8.x is incompatible with JDK 25 (would need Gradle 9.1+) |
| Gradle | 8.10.2 | 8.14.3 | Flutter 3.47 requires at least 8.14.0 |
| AGP | 8.7.0 | 8.11.1 | Flutter 3.47 requires at least 8.11.1 |
| Kotlin | 1.8.22 | 2.2.20 | Flutter 3.47 requires at least 2.2.20 |
| NDK | 27.0.12077973 | 30.0.16138531 | pinned to what is actually installed |

The `android-34` platform is downloaded by Gradle automatically.

## Icon packages removed

`weather_icons` and `material_design_icons_flutter` do not compile against
current Flutter: both extend `IconData`, which is now a `final` class. No updates
exist — the packages are abandoned.

21 icons were replaced with built-in `Icons.*` from Material across 5 files
(`cards/humidifier.dart`, `cards/printer.dart`, `clients/open_meteo/provider.dart`,
`dashboard/bedroom.dart`, `dashboard/master.dart`).

The replacements were picked by meaning and **have not been checked visually** —
some are not exact matches (e.g. `MdiIcons.printer3D` → `Icons.print`,
`MdiIcons.ledStripVariant` → `Icons.linear_scale`). Worth a look on the device.

Also `CardTheme` → `CardThemeData` in `main.dart` (the API changed in 3.47).

## Known log noise

- `IllegalArgumentException: this and base files have different roots` from the
  Kotlin incremental compiler — happens when the project and the pub cache live
  on different drives, as its path cache cannot compute a relative path across
  them. Does not affect the result.
- `flutter doctor` complains about missing `cmdline-tools` and unaccepted
  licenses — neither blocks the build.
