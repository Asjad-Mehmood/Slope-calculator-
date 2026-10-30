# Reference: the V28 HTML app

`v28/` holds the last version of the HTML prototype that Slope Calculator replaces. It is the
specification for what the app does. It is **not** part of the app and is never built or shipped.

| File | What it is |
| --- | --- |
| `Slope_Calculation_Application_V28.html` | V28, with one fix: the Project Plate was hidden behind the header's old backdrop (`.app-sticky-top::after`) |
| `Slope_Calculation_Professional_Excel_Template.xlsx` | The Excel report layout to match |
| `Slope_Calculation_V24_Installation_and_User_Manual.pdf` | The old manual (V24) |
| `READ-ME-FIRST.txt` | The V28 package notes |

## Known problems in V28 (each is fixed in the rewrite, with a test)

1. **Max sight does nothing.** The input and the drawing's sight line share the id `dlSight`, so the code reads the line, not the input.
2. **Impossible staff readings on steep slopes.** 100 → 60 m over 100 m books BS −2.40 m and FS 5.60 m on a 4 m staff; no change points are added between stations.
3. **The manual link is broken.** It points to `Slope_Calculation_Application_User_Manual.pdf`, which is not in the package.
4. **The installable web app could not install.** No manifest link, no service worker registration, no icons.
5. **Excel export needed internet.** The Excel library was loaded from jsDelivr.
6. **The optical simulator never stopped.** It redrew every 0.12 s, even when closed or hidden.
7. **The Excel report had no level book.** Only a separate CSV.
8. **The account was a local demo**, not the Excel to KML account.

## Results to match (checked in V28)

| Input | Result |
| --- | --- |
| Y1 102.5, Y2 98.75, X1 1000, X2 1250, interval 20 | −1.500 %, ΔH −3.750 m, M −0.01500, 1 in 66.7, 14 stations (1+000 … 1+240, 1+250.000) |
| Same, digital level, max sight 50, noise 0.3 mm | 3 setups, 16 readings, ΣBS − ΣFS = last RL − first RL, allowable 12√K = 6.0 mm |
