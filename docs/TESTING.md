# Testing

What is checked, where, and what is left for a person with real devices.

## On every push and pull request (Actions → Check)

| What | How | Where |
| --- | --- | --- |
| Calculations | 63 cases incl. the V28 examples and the Excel template; also run in Chrome | `test/calc` |
| The app | sign-in first, calculator, tools, saved calculations, offline saving, updates | `test/` (171 tests) |
| Every page fits | 5 sizes (small phone 360×640 → 1920×1080) × system text 100 / 150 / 200 % × light and dark; every page, the optical trainer and the project plate, scrolled to the end; fails with the page and source line of any overflow | `test/screens_matrix_test.dart` |
| Web app in browsers | Chromium, Firefox and WebKit (Safari's engine), wide and phone-sized: sign-in first, wrong password, calculator, every page, straight in when signed in on the website, offline after the first visit (Chromium) | `e2e/` (Playwright) |
| Worked examples | the published numbers match the code | `tool/worked_examples.dart` |
| Windows program | built, installer made, then **installed silently, opened, its window checked and screenshot taken, a second start leaves one copy, uninstalled and checked clean**, on GitHub's Windows Server machines, which have **no graphics card** | `tool/windows_smoke.ps1`; screenshot under the run's Artifacts |

Before a release, also run `tool/check_exports.sh` (needs LibreOffice and poppler-utils): it opens
both Excel reports in LibreOffice (all six sheets, printed to PDF, the levels, slope and gradient
read back), opens the CSV files, and checks the PDF is A4 with readable, searchable text and
embedded fonts.

## Found and fixed in phase 9

- The system text size (Windows accessibility, a phone's font size) was ignored: the app's own
  A− / A+ now applies on top of it, up to 200 %.
- With large text: the menu, rail and bottom bar, the page header, card headers, Settings rows,
  the probe's level, the Project plate button and the plate's footer ran off the edge. Each now
  wraps, moves under, grows or shrinks to fit.
- The plate's footer still said "With an account (phase 6) …".
- Excel cells held binary arithmetic noise (−0.299999999999997 for −0.3) that showed when a
  value was copied or used in a formula. Numbers are now stored clean.
- A screen reader announced the whole sign-in card as the name of the email-code box. Each field
  is now named by its label alone.

## Known gaps in the automatic tests

- **Typing in WebKit**: Playwright's Linux build of WebKit doesn't pass typing on to Flutter's
  text boxes, so the two sign-in tests that type are marked "fixme" there. Opening the app,
  signing in through the website and every page are tested in WebKit; typing in Safari is in the
  checklist below.
- **Touch screens**: the phone tests use phone-sized windows with a mouse; in touch emulation
  Flutter's accessibility tree, which the tests read, only turns on with a real tap.
- **Display scaling** on Windows (125 / 150 / 200 %) is covered by the text-size matrix for
  layout, not on a real Windows display.

## Checklist for a person, before a release

Tick each on a real device; note the device and version.

- [ ] Windows 11 PC: download from exceltokml.com/slope-calculation, SmartScreen (More info → Run
      anyway), install, sign in, calculate, export Excel and PDF, uninstall from Settings → Apps
- [ ] Windows 10 PC: the same
- [ ] Windows display scaling at 125 %, 150 % and 200 %, and Accessibility → Text size at 150 %
- [ ] A PC without a graphics card or with an old one (or a virtual machine)
- [ ] Remote Desktop into a PC running the program
- [ ] Self-update: with the previous version installed, open it online; it offers the new one,
      installs it and opens again
- [ ] Microsoft Excel: open the Excel report, every sheet, print preview
- [ ] Adobe Acrobat Reader: open the PDF report, print preview
- [ ] iPhone, Safari: open the web app, **type** email and password, sign in, calculate, Add to
      Home Screen, open it again in flight mode
- [ ] Mac, Safari: sign in by typing, calculate, export
- [ ] Android, Chrome: sign in, calculate, Install app, open it again offline
- [ ] Create an account with the emailed code, end to end on the live site
- [ ] Sign in with Google through the browser (the code on /link), end to end
- [ ] Save a calculation offline, go back online, see it under Saved on another device
