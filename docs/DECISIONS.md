# Decisions

Agreed before the rewrite started (phase 0). Change them here when they change.

| Topic | Decision |
| --- | --- |
| Name | **Slope Calculator**, by Excel to KML |
| Version | Starts at **1.0.0**. V24 to V28 were the HTML prototype. |
| Language and toolkit | **Flutter (Dart)**, one codebase for Windows, web, Android and iPhone |
| Windows program | Native Flutter build. **No WebView2**, no Edge, no web page in a window. NSIS installer per user, no administrator rights, self-update from GitHub releases, as Excel to KML and Traverse & Level. |
| Publisher details | Company "Excel to KML"; copyright "© 2026 Asjad Mehmood", as the other programs |
| Account | The **Excel to KML account** through the website's APIs: the same sign-up with the emailed code, sign-in and Google sign-in as the other apps. The calculator works signed out; saving to the dashboard needs an account. |
| App language | English, in the same plain wording as Excel to KML and Traverse & Level |
| Themes | Light and dark, following the computer by default. Navy and Cream from V28 are dropped. |
| Logo | New, made for this app: a gold graded line with three stations over its rise and run, on navy |
| Web address | `www.exceltokml.com/slope-calculation/app`, product page `www.exceltokml.com/slope-calculation` |
| Flutter version | 3.47.7 stable, pinned in CI. Upgrade on purpose, not by accident. |

## Not carried over from V28

- "LIVE SYSTEM – READY", "SYSTEM ACTIVE", the "ACTIVE" chip, the clock and "Welcome, guest" chips
- The local demo sign-in gate and its "XSurvey" text (replaced by the real account)
- The Leica brand mention and the red "laser" on the optical level
- The Excel library loaded from jsDelivr (exports will work offline)
- The stacked CSS overrides, duplicate functions and the duplicate `dlSight` id
- The V24 HTML file and the V24 manual from the release package
