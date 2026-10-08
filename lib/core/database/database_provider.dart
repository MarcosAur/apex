import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_connection.dart';

final databaseConnectionProvider = Provider<QueryExecutor>((ref) {
  return openAppDatabaseConnection();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(ref.watch(databaseConnectionProvider));
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final databaseInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(databaseProvider).initialize();
});
