# Changelog

## 1.0.0 (in development)

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
