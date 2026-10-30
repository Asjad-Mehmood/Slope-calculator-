# Worked examples

Printed by `dart run tool/worked_examples.dart` from the same code the app uses. Check
them against your own calculation; each one is also an automatic test.

## 1. Slope and chainage levels (the V28 example)

Y1 = 102.500 m, Y2 = 98.750 m, X1 = 1+000.000, X2 = 1+250.000, interval 20 m

| | Result |
| --- | --- |
| ΔH = Y2 − Y1 | −3.750 m |
| ΔX = X2 − X1 | 250.000 m |
| M = ΔH ÷ ΔX | −0.01500 m per m |
| Slope | −1.500 % |
| Gradient | 1 in 66.7 |

| Chainage | Distance (m) | Level (m) | Change (m) |
| --- | ---: | ---: | ---: |
| 1+000 | 0.000 | 102.500 | 0.000 |
| 1+020 | 20.000 | 102.200 | −0.300 |
| 1+040 | 40.000 | 101.900 | −0.600 |
| 1+060 | 60.000 | 101.600 | −0.900 |
| 1+080 | 80.000 | 101.300 | −1.200 |
| 1+100 | 100.000 | 101.000 | −1.500 |
| 1+120 | 120.000 | 100.700 | −1.800 |
| 1+140 | 140.000 | 100.400 | −2.100 |
| 1+160 | 160.000 | 100.100 | −2.400 |
| 1+180 | 180.000 | 99.800 | −2.700 |
| 1+200 | 200.000 | 99.500 | −3.000 |
| 1+220 | 220.000 | 99.200 | −3.300 |
| 1+240 | 240.000 | 98.900 | −3.600 |
| 1+250.000 | 250.000 | 98.750 | −3.750 |

14 stations. The ground falls 3.750 m over 250.000 m, a gradient of about 1 in 66.7 (−1.500 %).

## 2. The Excel template example

Y1 = 1.900 m, Y2 = 0.600 m, X1 = 0+000.000, X2 = 0+379.290, interval 20 m

| | Result |
| --- | --- |
| ΔH = Y2 − Y1 | −1.300 m |
| ΔX = X2 − X1 | 379.290 m |
| M = ΔH ÷ ΔX | −0.00343 m per m |
| Slope | −0.343 % |
| Gradient | 1 in 291.8 |

| Chainage | Distance (m) | Level (m) | Change (m) |
| --- | ---: | ---: | ---: |
| 0+000 | 0.000 | 1.900 | 0.000 |
| 0+020 | 20.000 | 1.831 | −0.069 |
| 0+040 | 40.000 | 1.763 | −0.137 |
| 0+060 | 60.000 | 1.694 | −0.206 |
| 0+080 | 80.000 | 1.626 | −0.274 |
| 0+100 | 100.000 | 1.557 | −0.343 |
| … | | | |
| 0+360 | 360.000 | 0.666 | −1.234 |
| 0+379.290 | 379.290 | 0.600 | −1.300 |

20 stations. The ground falls 1.300 m over 379.290 m, a gradient of about 1 in 291.8 (−0.343 %).

## 3. Crossfall (the Excel template example)

Centreline 10.000 m. Level = CL + direction × distance × |slope %| ÷ 100.

| Side | Slope | Offset | Direction | Level | Difference |
| --- | ---: | ---: | --- | ---: | ---: |
| Left | 2.0 % | 3.500 m | falls away | 9.9300 m | −0.0700 m |
| Right | 2.5 % | 3.500 m | falls away | 9.9125 m | −0.0875 m |

## 4. Level book: Height of Instrument and Rise & Fall

Opening benchmark 100.000 m, closing on a known 99.700 m, 100 m of levelling.

| Line | BS | IS | FS | HI | Rise | Fall | RL | Adjusted RL | Remark |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | 1.585 |  |  | 101.585 |  |  | 100.000 | 100.0000 | BM |
| 2 |  | 1.950 |  |  |  | 0.365 | 99.635 | 99.6325 |  |
| 3 | 0.875 |  | 2.105 | 100.355 |  | 0.155 | 99.480 | 99.4775 | CP |
| 4 |  | 1.225 |  |  |  | 0.350 | 99.130 | 99.1250 |  |
| 5 |  |  | 0.650 |  | 0.575 |  | 99.705 | 99.7000 |  |

- ΣBS − ΣFS = 2.460 − 2.755 = −0.295; last RL − first RL = −0.295 ✓
- ΣRise − ΣFall = 0.575 − 0.870 = −0.295 ✓
- HI check: ΣIS + ΣFS + Σ(RL except the first) = Σ(HI × readings from it) ✓
- Misclosure +5.0 mm; allowable 12√K = 3.8 mm: outside tolerance. Spread equally over the 2 setups.

## 5. Digital level on a steep slope (the V28 bug)

100.000 m to 60.000 m over 0+000 to 0+100 (−40.0 %), every 20 m; perfect readings, max sight 50 m, instrument 1.600 m above the ground, readings kept between 0.350 m and 3.900 m on a 4 m staff.

V28 booked a backsight of −2.400 m and a foresight of 5.600 m: impossible on a 4 m staff. Now 15 change points are added between the stations, in 20 setups:

| Chainage | BS | IS | FS | RL | Remark |
| --- | ---: | ---: | ---: | ---: | --- |
| 0+000.000 | 0.375 |  |  | 100.000 | BM |
| 0+006.125 | 0.375 |  | 2.825 | 97.550 | CP (added) |
| 0+012.250 | 0.375 |  | 2.825 | 95.100 | CP (added) |
| 0+018.375 | 1.275 |  | 2.825 | 92.650 | CP (added) |
| 0+020.000 | 0.375 |  | 1.925 | 92.000 | CP |
| 0+026.125 | 0.375 |  | 2.825 | 89.550 | CP (added) |
| 0+032.250 | 0.375 |  | 2.825 | 87.100 | CP (added) |
| 0+038.375 | 1.275 |  | 2.825 | 84.650 | CP (added) |
| 0+040.000 | 0.375 |  | 1.925 | 84.000 | CP |
| … | | | | | |

Lowest reading 0.375 m, highest 2.825 m. Closing error 0.0 mm; arithmetic check ✓.
