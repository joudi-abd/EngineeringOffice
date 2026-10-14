# أفق إمبريوم · UFUQ Imperium — mobile

Native Flutter app that mirrors the public website (no dashboard, no WebView).
Arabic (RTL) and English, black / gold identity, data from the Laravel public API.

## Run (Debug)

Dart ships inside the Flutter SDK (`<flutter>/bin/cache/dart-sdk`), so there is nothing extra to install.

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd mobile
flutter pub get
flutter run                                                  # production API
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api   # local API from the Android emulator
```

### Android Studio

1. `Settings → Plugins` → install **Flutter** (it pulls in **Dart**), restart.
2. `Settings → Languages & Frameworks → Flutter` → SDK path: the Flutter folder (e.g. `~/development/flutter`).
3. `File → Open…` → select the `mobile/` folder.
4. Pick a device / emulator and press **Debug** (`main.dart`).
   To point at a different API: *Run → Edit Configurations → Additional run args* → `--dart-define=API_URL=...`.

## Checks

```bash
flutter analyze
flutter test
```

## Build

```bash
tool/build_release.sh              # dist/UFUQ-<version>.apk (universal), version + signature verified
tool/build_release.sh --apk --aab  # APK plus dist/UFUQ-<version>.aab for Google Play
```

The plain `flutter build apk --release` / `appbundle --release` still work; they produce `app-release.*` under `build/`.

### Versioning

Release versions (`1.0.x` + an always-rising versionCode) are managed with `dart tool/version.dart show | next | set | dry-run`.
Debug builds never change the version; `tool/build_release.sh` only reads it. Full guide: [`tool/README.md`](tool/README.md).

## Architecture — feature-driven

```
lib/
  main.dart                    entry: orientation, edge-to-edge, runApp
  app/                         composition root
    app.dart                   MaterialApp, theme, locale, root switcher (loading / error / shell)
    app_providers.dart         every repository + controller is wired here (Provider)
    site_bootstrap.dart        first load of all features, LoadState
  core/                        shared, feature-agnostic (never imports features/)
    config/                    AppConfig (API url, …)
    network/                   ApiClient, ApiException
    localization/              Copy (ar/en strings), Translator, LocaleController
    state/                     LocalizedController base (reacts to language changes)
    theme/                     brand tokens + typography
    utils/                     json helpers, external links
    widgets/                   brand, fields, grain, reveal, states, page blocks…
  features/
    <feature>/
      data/                    models + repository (API access)
      state/                   ChangeNotifier controller + localizers
      presentation/            screens and feature widgets
    home · about · services · projects · team · settings · contact · shell
assets/                        brand logos, fonts (Bukra, Neue Power), images/hero.svg (home hero drawing)
test/                          mirrors lib/ (core, features, app)
```

Rules:

- `core` never imports `features`; features may use `core`, and only the `app` layer wires features together.
- Screens talk to controllers / repositories through `Provider`, never to `ApiClient` directly.
- Adding a feature = new `features/<name>/{data,state,presentation}` folder + register it in `app_providers.dart` (and in `site_bootstrap.dart` if it loads on start).
- The shell (`features/shell`) receives its pages from `app/app.dart`, so it knows nothing about other features.

## Notes

- External links (phone, mail, WhatsApp, social, YouTube/Vimeo) open in the phone's own apps.
- Uploaded project videos play natively with `video_player`.
- Day / night: `core/theme/tokens.dart` holds two `Palette`s (night = black/gold, day = Magical Moonlight beige).
  Widgets read colours with `context.pal`; `Brand.*` constants are only for surfaces that are always dark
  (photo overlays, gallery viewer, video tile). `ThemeController` follows the phone (`ThemeMode.system`)
  until the visitor taps the sun/moon button; that choice is saved under `ufuq-theme`.
- App icon: sources are in `icon/` (`app-icon.svg` + 1024 px PNGs, a dark variant, and the adaptive foreground).
  After changing them, run `dart run flutter_launcher_icons` to regenerate the Android and iOS icons.
