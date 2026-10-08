import 'dart:io';

import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/exercises/domain/measurement_unit.dart';
import 'package:apex/features/workouts/data/workout_repository.dart';
import 'package:apex/features/workouts/domain/effort_level.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final version in [0, 1, 2]) {
    final legacy = version > 0;
    test(
      'Persiste esforços e protege valores (versão de origem: $version)',
      () async {
        final directory = await Directory.systemTemp.createTemp('apex_effort_');
        final file = File('${directory.path}/test.sqlite');
        final db = AppDatabase(
          NativeDatabase(
            file,
            setup: (sqlite) {
              if (!legacy) return;
              // Fixture independente do esquema v2: estrutura original da versão 1.
              sqlite.execute('''
CREATE TABLE gyms (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, location TEXT);
CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE);
CREATE TABLE muscle_groups (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE);
CREATE TABLE exercises (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category_id INTEGER NOT NULL REFERENCES categories(id), muscle_group_id INTEGER NOT NULL REFERENCES muscle_groups(id));
CREATE TABLE workouts (id INTEGER PRIMARY KEY AUTOINCREMENT, gym_id INTEGER REFERENCES gyms(id), performed_at INTEGER NOT NULL, notes TEXT);
CREATE TABLE workout_exercises (id INTEGER PRIMARY KEY AUTOINCREMENT, workout_id INTEGER NOT NULL REFERENCES workouts(id), exercise_id INTEGER NOT NULL REFERENCES exercises(id));
CREATE TABLE exercise_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, workout_exercise_id INTEGER NOT NULL REFERENCES workout_exercises(id), set_number INTEGER NOT NULL, weight REAL NOT NULL, reps INTEGER NOT NULL);
INSERT INTO categories VALUES (1, 'Push');
INSERT INTO muscle_groups VALUES (1, 'Peitoral');
INSERT INTO exercises VALUES (1, 'Supino', 1, 1);
INSERT INTO workouts VALUES (1, NULL, 1700000000, 'Legado');
INSERT INTO workout_exercises VALUES (1, 1, 1);
INSERT INTO exercise_logs VALUES (1, 1, 1, 42.5, 8);
PRAGMA user_version = 1;
''');
              if (version == 2) {
                sqlite.execute(
                  "ALTER TABLE exercise_logs ADD COLUMN effort_level TEXT CHECK (effort_level IN ('very_low', 'low', 'medium', 'high', 'failure_at_end', 'failure_before_end')); PRAGMA user_version = 2;",
                );
              }
            },
          ),
        );
        AppDatabase? reopened;
        try {
          await db.initialize();
          final repository = WorkoutRepository(db);
          int itemId;
          if (legacy) {
            final old = await db.select(db.exerciseLogs).getSingle();
            expect(old.id, 1);
            expect(old.effortLevel, isNull);
            expect(old.measurementValue, 42.5);
            expect(old.reps, 8);
            expect(old.setNumber, 1);
            expect((await db.select(db.workouts).getSingle()).notes, 'Legado');
            itemId = old.workoutExerciseId;
            await repository.resumeLegacy(1);
          } else {
            final category = (await db.select(db.categories).get()).first;
            final muscle = (await db.select(db.muscleGroups).get()).first;
            final exerciseId = await db
                .into(db.exercises)
                .insert(
                  ExercisesCompanion.insert(
                    name: 'Supino',
                    categoryId: category.id,
                    muscleGroupId: muscle.id,
                  ),
                );
            itemId = await repository.addExercise(
              await repository.start(),
              exerciseId,
            );
          }
          expect(
            (await db.select(db.workoutExercises).getSingle()).measurementUnit,
            MeasurementUnit.kilograms,
          );
          for (final level in EffortLevel.values) {
            await repository.addLog(
              workoutExerciseId: itemId,
              setNumber: level.index + (legacy ? 2 : 1),
              measurementValue: 30,
              reps: 10,
              effortLevel: level,
            );
          }
          final raw = await db
              .customSelect(
                'SELECT effort_level FROM exercise_logs WHERE effort_level IS NOT NULL ORDER BY id',
              )
              .get();
          expect(raw.map((row) => row.read<String>('effort_level')), [
            'very_low',
            'low',
            'medium',
            'high',
            'failure_at_end',
            'failure_before_end',
          ]);
          await expectLater(
            db.customStatement(
              "UPDATE exercise_logs SET effort_level = 'invalid'",
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'constraint',
                contains('CHECK'),
              ),
            ),
          );
          expect(
            await db.customSelect('PRAGMA foreign_key_check').get(),
            isEmpty,
          );
          expect(
            (await db.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version'),
            5,
          );
          await db.close();
          reopened = AppDatabase(NativeDatabase(file));
          final logs = await reopened.select(reopened.exerciseLogs).get();
          expect(
            logs
                .where((log) => log.effortLevel != null)
                .map((log) => log.effortLevel),
            unorderedEquals(EffortLevel.values),
          );
          expect(logs.length, legacy ? 7 : 6);
          if (legacy) {
            expect(logs.singleWhere((log) => log.id == 1).effortLevel, isNull);
          }
        } finally {
          await db.close();
          await reopened?.close();
          await directory.delete(recursive: true);
        }
      },
    );
  }
}
