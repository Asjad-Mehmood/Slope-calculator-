#!/usr/bin/env bash
# Builds the web app for exceltokml.com/slope-calculation/app, ready to copy into the website's
# public/slope-calculation/app:
#   tool/web_build.sh 1.0.0
# CanvasKit is bundled (no Google CDN), so the app runs offline; the files only a WebAssembly
# build or debugging needs are removed; sw.js is written with every file to keep for offline use.
set -euo pipefail
VERSION="${1:-$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)}"
BASE="${BASE_HREF:-/slope-calculation/app/}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

flutter build web --release --base-href "$BASE" --no-web-resources-cdn --dart-define=APP_VERSION="$VERSION"

cd build/web
rm -f flutter_service_worker.js .last_build_id canvaskit/*.symbols canvaskit/*/*.symbols
rm -rf canvaskit/skwasm* canvaskit/wimp* canvaskit/webparagraph
python3 - "$VERSION" "$ROOT/tool/sw.template.js" <<'PY'
import hashlib, json, os, sys
files = sorted(
    os.path.relpath(os.path.join(d, f), '.').replace(os.sep, '/')
    for d, _, fs in os.walk('.') for f in fs if f != 'sw.js'
)
h = hashlib.sha256(open(sys.argv[2], 'rb').read())
for f in files:
    h.update(f.encode())
    h.update(open(f, 'rb').read())
cache = f'slope-{sys.argv[1]}-{h.hexdigest()[:12]}'
keep = [f for f in files if f != 'index.html']
template = open(sys.argv[2]).read()
open('sw.js', 'w').write(template.replace('__CACHE__', cache).replace('__FILES__', json.dumps(keep)))
print(f'sw.js: {cache}, {len(files)} files')
PY
du -sh .
