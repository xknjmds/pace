#!/bin/bash
# Regenerates the two files drift needs to run SQLite in the browser.
# Run from pace_app/ after upgrading drift or sqlite3.
set -euo pipefail
cd "$(dirname "$0")/.."
SQLITE3=$(awk '$0=="  sqlite3:"{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
curl -fsSL -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE3}/sqlite3.wasm"
dart compile js -O4 -o web/drift_worker.js tool/drift_worker.dart
rm -f web/drift_worker.js.deps web/drift_worker.js.map
echo "web/sqlite3.wasm (sqlite3 ${SQLITE3}) and web/drift_worker.js updated"
