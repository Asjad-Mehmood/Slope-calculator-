# Plan

Each phase ends with something that can be checked. ✅ done · 🔜 next · ⬜ to do

## ✅ Phase 0: setup
Repository, Flutter project for every platform, name, version, logo and icons, Windows program
details, lint rules, smoke test, Check workflow, V28 kept as the specification.

## ✅ Phase 1: calculation engine (`lib/src/calc/`, no screens)
- Slope between two points: ΔH, ΔX, slope per metre, slope %, 1 in N, rising / falling / level; input checks.
- Chainage levels: start, every multiple of the interval, end; level and change from start; level at any chainage; chainage format `k+mmm.mmm`, negatives included.
- Crossfall from the centreline: left and right levels, up or down.
- Level book: setups within the max sight, staff readings kept on a 4 m staff (0.3 to 3.9 m), extra change points on steep slopes, HI and Rise & Fall, arithmetic check, closing error against C√K mm.
- 63 tested cases, including the V28 examples and the Excel template, run on the computer and in a browser.
- [Worked examples](worked-examples.md) to check by hand.

## ✅ Phase 2: look and feel (approved)
Colours, bundled fonts, inputs, tiles, tables, cards, foldable optional sections, wide and phone
layouts, keyboard and screen-reader use, text size. Screenshots for approval.

## ✅ Phase 3: main screens
Calculator with remembered inputs, results, profile with a probe, chainage levels with "Go to
chainage", project plate, settings (theme, text size, stations, decimals, interval, allowable C).
The calculator is the start screen; recent calculations come with accounts in phase 6.

## ✅ Phase 4: optional tools
Crossfall with a cross-section drawing; digital level run (step or play, instrument display, level
book by HI or Rise & Fall, checks and closing error); optical level trainer with an E-pattern
staff, watch and practise modes. Animations run only while their page is on screen.

## ✅ Phase 5: reports (offline)
Excel (Project Plate, Slope Summary, Chainage Levels, Crossfall, Level Book, QA QC Checklist), CSV
(chainage levels, level book), PDF with the profile and sign-off boxes, print. Save As on Windows,
download in the browser. KML needs coordinates the app doesn't ask for yet: left for later.

## ✅ Phase 6: account and saved calculations
Website (KML-WEBSITE-): `slope_jobs` table, `GET /api/slope/jobs`, `PUT`/`DELETE /api/slope/jobs/[id]`,
`GET /api/admin/slope`. App: sign in, create an account with the emailed code, sign in through the
browser (Google), Saved page to save, open and delete. Still to do: an admin page on the website
for the figures, and saving while offline (now it says it can't reach the site).

## 🔜 Phase 7: web version and product page
Web build at `/slope-calculation/app`, installable, offline; product page, menu, sitemap, home
page "New" badge, download counts.

## ⬜ Phase 8: Windows program
NSIS installer, self-update from `latest.json`, single instance, release workflow on a version
tag; code signing when the certificate is ready.

## ⬜ Phase 9: testing
Windows 10 and 11, display scaling, a PC with no graphics card, Remote Desktop; browsers and
phones; exports in Excel, LibreOffice and Adobe Reader; accounts and offline.

## ⬜ Phase 10: manual and documents
New manual (PDF and web page), worked examples, updated Excel template, release notes.

## ⬜ Phase 11: release 1.0.0
Beta for testing, fixes, release, product page live, optional announcement email.

## ⬜ Phase 12: Android and iPhone
## ⬜ Phase 13: after launch
