import 'dart:io';

import 'package:apex/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File databaseFile;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('apex_database_test_');
    databaseFile = File('${directory.path}/apex_workout.sqlite');
  });

  tearDown(() async {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });

  test('Cria o arquivo e preserva dados após fechar e reabrir', () async {
    final firstDatabase = AppDatabase(NativeDatabase(databaseFile));
    await firstDatabase.initialize();
    await firstDatabase
        .into(firstDatabase.gyms)
        .insert(GymsCompanion.insert(name: 'Academia persistente'));
    await firstDatabase.close();

    expect(databaseFile.existsSync(), isTrue);

    final reopenedDatabase = AppDatabase(NativeDatabase(databaseFile));
    await reopenedDatabase.initialize();
    final gyms = await reopenedDatabase.select(reopenedDatabase.gyms).get();
    final categories = await reopenedDatabase
        .select(reopenedDatabase.categories)
        .get();
    final muscleGroups = await reopenedDatabase
        .select(reopenedDatabase.muscleGroups)
        .get();
    final foreignKeys = await reopenedDatabase
        .customSelect('PRAGMA foreign_keys')
        .getSingle();

    expect(gyms.single.name, 'Academia persistente');
    expect(categories.length, AppDatabase.initialCategories.length);
    expect(muscleGroups.length, AppDatabase.initialMuscleGroups.length);
    expect(foreignKeys.read<int>('foreign_keys'), 1);

    await reopenedDatabase.close();
  });
}
