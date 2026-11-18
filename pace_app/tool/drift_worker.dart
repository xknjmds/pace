// Source of web/drift_worker.js, the worker drift uses to run SQLite on the
// web. Compiled from the drift version in pubspec.lock so they always match.
// Rebuild after upgrading drift (see tool/build_web_db.sh).
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
