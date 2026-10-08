import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

const appDatabaseName = 'apex_workout';

/// Abre apex_workout.sqlite na área de documentos privada do aplicativo.
QueryExecutor openAppDatabaseConnection() {
  return driftDatabase(
    name: appDatabaseName,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
