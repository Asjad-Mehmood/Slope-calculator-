#!/usr/bin/env bash
# Opens the app's reports in other programs the way people do, and checks what they read:
# LibreOffice Calc (the Excel reports, every sheet, and the CSV files) and poppler (the PDF).
# Needs LibreOffice and poppler-utils:  tool/check_exports.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }
ok() { echo "ok  $*"; }

cd "$ROOT"
SAMPLE_DIR="$OUT" flutter test test/export/sample_files_test.dart >/dev/null
cd "$OUT"

# Excel reports: LibreOffice opens them and reads the numbers the app wrote
for x in report-hi.xlsx report-rise-and-fall.xlsx; do
  mkdir -p "lo-${x%.xlsx}"
  soffice --headless --norestore --convert-to \
    'csv:Text - txt - csv (StarCalc):44,34,76,1,,0,false,true,false,false,false,-1' \
    --outdir "lo-${x%.xlsx}" "$x" >/dev/null 2>&1
  n=$(ls "lo-${x%.xlsx}" | wc -l)
  [ "$n" -eq 6 ] || fail "$x: LibreOffice read $n sheets, not 6"
  ok "$x: LibreOffice opens all 6 sheets"
  soffice --headless --norestore --convert-to pdf --outdir "lo-${x%.xlsx}" "$x" >/dev/null 2>&1
  [ -s "lo-${x%.xlsx}/${x%.xlsx}.pdf" ] || fail "$x: LibreOffice could not print it to PDF"
  ok "$x: LibreOffice prints it"
done
L="lo-report-hi"
grep -q '^1+120,120,100.7,-1.8$' "$L/report-hi-Chainage Levels.csv" || fail 'Chainage Levels: 1+120 is not 100.7 (−1.8)'
grep -q '^1+250.000,250,98.75,-3.75$' "$L/report-hi-Chainage Levels.csv" || fail 'Chainage Levels: the end is not 98.75'
ok 'Chainage Levels: the levels LibreOffice reads match the calculation'
grep -q '^Slope percentage,-1.5,%$' "$L/report-hi-Slope Summary.csv" || fail 'Slope Summary: slope is not −1.5 %'
grep -q '^Gradient,1 in 66.667,Ratio$' "$L/report-hi-Slope Summary.csv" || fail 'Slope Summary: gradient is not 1 in 66.667'
ok 'Slope Summary: slope and gradient'
if grep -qE '[0-9]\.[0-9]{10,}' "$L"/*.csv lo-report-rise-and-fall/*.csv; then fail 'a sheet holds a number with arithmetic noise'; fi
ok 'no number carries arithmetic noise (like 0.299999999999997)'
grep -q '^LEVEL BOOK · RISE AND FALL\|^LEVEL BOOK · RISE & FALL' lo-report-rise-and-fall/*Level\ Book.csv || fail 'the Rise & Fall report does not say Rise & Fall'
ok 'the Rise & Fall report is booked by Rise & Fall'

# CSV: starts with the byte-order mark (Excel then reads ± and − right) and LibreOffice reads it
for c in chainage-levels.csv level-book.csv; do
  [ "$(head -c3 "$c" | od -An -tx1 | tr -d ' ')" = efbbbf ] || fail "$c has no UTF-8 byte-order mark"
  soffice --headless --norestore --infilter='Text - txt - csv (StarCalc):44,34,76' --convert-to xlsx --outdir lo-csv "$c" >/dev/null 2>&1
  [ -s "lo-csv/${c%.csv}.xlsx" ] || fail "LibreOffice could not open $c"
  ok "$c: UTF-8 with a byte-order mark, opens in LibreOffice"
done

# PDF: a valid A4 file whose text a reader (and a search) finds
pdfinfo report.pdf | grep -q 'Page size:.*595.* x 841.*A4' || fail 'the PDF is not A4'
pages=$(pdfinfo report.pdf | awk '/^Pages:/ {print $2}')
[ "$pages" -ge 1 ] || fail 'the PDF has no pages'
txt=$(pdftotext -layout report.pdf -)
for t in 'Ring Road, Phase 2' '−1.500 %' '1 in 66.7' 'Falling' 'CHAINAGE LEVELS' 'LEVEL BOOK'; do
  grep -qF "$t" <<<"$txt" || fail "the PDF text has no \"$t\""
done
ok "report.pdf: A4, $pages pages, text readable and searchable"
pdffonts report.pdf | awk 'NR>2 && $0 ~ /Inter|JetBrains/ && $(NF-4) != "yes" {exit 1}' || fail 'a font is not embedded'
ok 'report.pdf: its fonts are embedded'
# The Excel template: LibreOffice recalculates its formulas and gets the app's numbers
(cd "$ROOT" && dart run tool/excel_template.dart "$OUT/t1/template.xlsx" >/dev/null && \
  dart run tool/excel_template.dart "$OUT/t2/template.xlsx" --example2 >/dev/null)
for t in t1 t2; do
  (cd "$t" && soffice --headless --norestore --convert-to 'csv:Text - txt - csv (StarCalc):44,34,76,1,,0,false,true,false,false,false,-1' template.xlsx >/dev/null 2>&1)
done
T1="$(ls t1/*.csv)"; T2="$(ls t2/*.csv)"
grep -q '^Slope %,-1.5,' "$T1" && grep -q '^Stations,14,' "$T1" && grep -q '^1120,1+120.000,120,100.7,-1.8,' "$T1" \
  && grep -q '^1250,1+250.000,250,98.75,-3.75,' "$T1" || fail 'template: the V28 example does not give the app levels'
grep -q ',Level,9.93,9.9125$' "$T1" || fail 'template: the crossfall levels are not 9.930 and 9.9125'
ok 'Excel template: the V28 example gives the app slope, 14 stations and levels, and crossfall'
grep -q '^Stations,20,' "$T2" && grep -q '^379.29,0+379.290,379.29,0.6,-1.3,' "$T2" || fail 'template: the template example does not end at 0+379.290, 0.600'
lvl=$(awk -F, '$1=="360" {printf "%.3f", $4}' "$T2")
[ "$lvl" = 0.666 ] || fail "template: the level at 0+360 is $lvl, the app says 0.666"
ok 'Excel template: the template example gives 20 stations and the app level at 0+360 (0.666)'

echo 'Reports open and read correctly in LibreOffice and the PDF tools'
