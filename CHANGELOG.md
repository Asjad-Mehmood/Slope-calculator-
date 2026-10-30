# Changelog

## 1.0.0 (in development)

### Phase 8: Windows program and GitHub build
- Installer `SlopeCalculator-Setup.exe` (NSIS): installs for the user without administrator rights
  to `%LOCALAPPDATA%\SlopeCalculator`, with Start menu and desktop shortcuts and an entry in
  Settings → Apps to uninstall. The Microsoft C++ runtime is included, so nothing else is needed.
- Self-update: a few seconds after opening, the program reads `latest.json` from the newest GitHub
  release; when a newer version is out it asks, downloads the installer, checks its SHA-256,
  installs silently and opens again.
- One window at a time: opening it again brings the open window forward.
- Build and Release workflow on a version tag (`v1.0.0`): tests, builds, makes the installer and
  `latest.json`, publishes the release with `docs/releases/<tag>.md`, then downloads it back and
  checks it the way installed copies do. Every push builds a test installer under Actions →
  Artifacts.

### Phase 6: Excel to KML account
- Sign in with the Excel to KML account, or create one: the website emails a 6-digit code to
  confirm the email, as on the website and in the other apps. Forgot the password sends the
  website's reset link.
- Sign in with the browser: a code shown in the app is confirmed at exceltokml.com/link, where
  Google sign-in works.
- Saved page: save the current calculation (the line, its settings and the project plate) to the
  account, see them all with their slope, chainages and date, open one back into the calculator,
  delete one. The same list on Windows, the web app and phones.
- The Windows program keeps its sign-in token on the device; the web app uses the website's
  sign-in. Requests say which app, platform and version they come from.
- Website side (KML-WEBSITE- repository): the slope_jobs table and its API.

### Phase 5: reports
- Export menu on the Calculator: Excel report, PDF report, Print, and the chainage levels as CSV.
  Windows asks where to save; the web app downloads. Everything is made inside the app, offline.
- Excel report like the professional template: Project Plate, Slope Summary, Chainage Levels,
  Crossfall, **Level Book** (new: the last run taken to the end on the Level page, by HI or Rise &
  Fall, with design levels, differences, adjusted levels and the checks) and the QA QC Checklist.
  Numbers are stored as numbers with the chosen decimals.
- PDF report (A4): the project plate, results, the working, the profile, the chainage levels, the
  crossfall, the level book with its checks, and Surveyed / Checked / Approved by boxes with the
  names from the project plate; page numbers and the app version on every page.
- CSV: chainage levels (the V28 columns) and, on the Level page, the level book; with the byte
  order mark Excel needs.
- File names from the project name and date, e.g. `Ring_Road_Slope_Report_2026-10-30.pdf`.

### Phase 4: optional tools
- Crossfall: centreline level, slope % and offset on each side, falling or rising away; results,
  the working written out, and a cross-section drawing. Remembered on the device.
- Digital level run along the calculator's line: a side view with the level, the barcode staff and
  the line of sight; the instrument's display (reading to 0.1 mm, distance, RL); Start / Pause,
  Step, Reset and New run; the level book filling in reading by reading, by Height of Instrument
  or Rise & Fall, with design levels and differences; and the checks at the end (ΣBS − ΣFS, HI or
  Rise & Fall check, closing error against C√K from Settings). Options: max sight, reading noise,
  collimation error, speed.
- Optical level trainer: the view through the telescope onto an E-pattern staff with the cross and
  stadia hairs. Watch mode moves the staff and shows the reading; Practise mode asks for the
  reading and marks it (within 2 mm), with a score.
- Animations stop when their page isn't on screen (V28's ran all the time).

### Phase 3: main screens
- The app remembers, on this device, the last inputs, the settings and the project plate, and
  opens where it was left (Windows: the user's AppData; web: the browser's storage).
- Profile probe: press or drag on the profile, or use the slider, to read the level at any
  chainage.
- Chainage levels: "Go to chainage" (`1+125` or `1125`) gives the level there and brings the
  nearest station into view.
- Project plate: the 16 fields of the Excel template, in a dialog on a computer and a full page on
  a phone; the header button shows the project name and how many fields are filled.
- Settings: theme (computer, light, dark), text size, stations (round chainages or from the start),
  default decimals and interval, allowable misclosure C, and reset.

### Phase 2: look and feel
- Light and dark themes in the logo's navy and survey gold; follows the computer, with a switch
  in the header. Text size 85 % to 130 % (A− / A+).
- Inter and JetBrains Mono fonts inside the app (SIL Open Font Licence), so it looks the same
  offline; figures line up in columns.
- Building blocks: numbered step cards (optional ones fold away), number tiles with their short
  name (Y1) and the chainage under them, Enter to move on, interval choices, a pick-one box, the
  slope % card, result tiles, notices, a table whose header stays in view, and the profile.
- The frame: a menu down the left on a computer, a rail on a tablet and a bar along the bottom on
  a phone; Calculator, Crossfall, Level, Saved and Settings.
- The calculator screen on the phase 1 calculations, to judge the design on real numbers.

### Phase 1: calculation engine
- Slope between two points: ΔH, ΔX, slope per metre, slope %, gradient 1 in N, rising, falling
  or level, and a plain-English summary.
- Chainage levels on round chainages (as V28) or counted from the start (as the Excel template),
  level at any chainage, chainages typed as `1+250.5` or `1250.5`.
- Crossfall from the centreline, rising or falling away on each side.
- Level book reduced by Height of Instrument or Rise & Fall, with all three arithmetic checks, the
  misclosure against C√K mm and the misclosure spread over the setups.
- Digital level run: the same readings as V28 for the same seed, now with a working max sight and
  change points added on steep slopes so every reading stays on the staff.
- Fixed from V28: max sight did nothing; steep slopes booked readings off the staff; 999.9996 m
  showed as `0+1000.000`; half-metre stations lost their decimals; tiny negatives showed as `−0.000`.
- 63 tests, run on the computer and in a browser; `docs/worked-examples.md` printed from the code.

### Phase 0: project setup
- Flutter 3.47.7 project for Windows, web, Android and iPhone.
- Name **Slope Calculator**, publisher **Excel to KML**, version 1.0.0.
- New logo: a gold graded line with stations over its rise and run, on navy, the same family as
  Excel to KML and Traverse & Level. Icons for every platform, including the Windows `.ico`.
- Windows program details: `SlopeCalculator.exe`, company Excel to KML, © 2026 Asjad Mehmood.
- Start screen with the name and version, light and dark following the computer.
- Strict lint rules, a smoke test, and a Check workflow on every push (lints, format, tests, web
  and Windows builds).
- V28 HTML app kept in `reference/v28/` as the specification, with its known problems listed.
