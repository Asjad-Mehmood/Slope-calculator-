# Slope Calculator

**Slope, gradient and chainage levels for surveyors and site engineers.** By Excel to KML.

<img src="assets/brand/icon-512.png" alt="" width="96">

Enter the start and end level and chainage, and get the slope %, the slope per metre, the
gradient 1 in N and the level at every chainage, with a profile, a project plate and Excel, CSV
and PDF reports. Optional tools: crossfall from the centreline, a digital level simulator with a
checked level book, and an optical level trainer. Calculations are saved to your Excel to KML
account.

> **Status: version 1.0.0 in development.** Phases 0 (setup), 1 (calculations) and 2 (look and feel) are done. See
> [docs/PLAN.md](docs/PLAN.md) for the phases and [CHANGELOG.md](CHANGELOG.md) for progress.

## One app, every platform

Written once in Flutter (Dart) and built for:

| Platform | How it ships |
| --- | --- |
| Windows 10 and 11 | `SlopeCalculator-Setup.exe`: a native program. It draws its own screens, so it does **not** need Microsoft Edge WebView2. |
| Web | `www.exceltokml.com/slope-calculation/app`, installable on phones and computers, works offline |
| Android, iPhone | later (phase 12), from the same code |

The calculations live in one place (`lib/src/calc/`, phase 1), so every platform gives the same
answer.

## For developers

### Requirements

- Flutter **3.47.7** (stable), the version CI uses
- Windows builds: Windows 10 or 11 with Visual Studio 2022 and the "Desktop development with C++" workload

### Run and check

```
flutter pub get
flutter analyze          # lints, must report no issues
dart format --output=none --set-exit-if-changed lib test
flutter test             # all tests must pass
flutter test --platform chrome test/calc   # the calculations in a browser
dart run tool/worked_examples.dart > docs/worked-examples.md
flutter run -d windows   # or: -d chrome
```

### Build

```
flutter build windows --release --dart-define=APP_VERSION=1.0.0
flutter build web --release --base-href /slope-calculation/app/ --dart-define=APP_VERSION=1.0.0
```

### Project layout

```
lib/main.dart            starts the app
lib/src/app.dart         the app's frame and themes (light, dark, follow the computer)
lib/src/brand.dart       name, version, publisher and colours
lib/src/calc/            the calculations, no screens: slope, chainage, crossfall, level book, level run
lib/src/ui/              the shared look: theme, frame, inputs, tiles, tables, profile
lib/src/screens/         calculator, results, profile, project plate, tools (phases 3-4)
lib/src/export/          Excel, CSV, PDF and print (phase 5)
lib/src/account/         sign in with Excel to KML, saved calculations (phase 6)
assets/brand/            the logo (SVG) and icons
assets/fonts/            Inter and JetBrains Mono, with their licences
reference/v28/           the V28 HTML app this rewrite replaces: the specification
docs/                    plan, decisions, worked examples and release notes
tool/worked_examples.dart  prints docs/worked-examples.md from the calculations
windows/ web/ android/ ios/   platform projects
```

### Logo and icons

`assets/brand/logo.svg` is the source. `logo-full-bleed.svg` is the square version for Android
maskable icons and iPhone. Every icon file (`windows/runner/resources/app_icon.ico`, `web/icons/`,
`web/favicon.png`, Android `mipmap-*`, iOS `AppIcon.appiconset`) is rendered from those two.

### Making a release

1. Merge the change into `main` and write the notes in `docs/releases/<tag>.md`.
2. Publish a GitHub release on `main` with a new tag, for example `v1.0.1` (v and three numbers).
3. The **Build and Release** workflow tests, builds `SlopeCalculator.exe` with the version
   stamped in, makes `SlopeCalculator-Setup.exe` and `latest.json`, attaches them to the release
   and then downloads them back the way installed copies do. If that last job fails, installed
   copies can't update: fix it first.

Installed copies read `latest.json` from
`https://github.com/Asjad-Mehmood/slope-calculator-/releases/latest/download/`, so this repository
and its releases must stay public under that name.

### Version

`pubspec.yaml` holds the version (`1.0.0+1`). A release stamps it into the app with
`--dart-define=APP_VERSION=x.y.z`; the start screen and reports show it.

## Licence

Copyright (c) 2026 Asjad Mehmood. All rights reserved. See [LICENSE](LICENSE).
