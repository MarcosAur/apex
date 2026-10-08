import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/exercises/domain/measurement_unit.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final performedAt = DateTime(2026, 9, 12, 18, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertWorkout() async {
    final gymId = await db
        .into(db.gyms)
        .insert(
          GymsCompanion.insert(
            name: 'Academia',
            location: const Value('Centro'),
          ),
        );
    final categoryId = await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: 'Força'));
    final muscleGroupId = await db
        .into(db.muscleGroups)
        .insert(MuscleGroupsCompanion.insert(name: 'Trapézio'));
    final exerciseId = await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: 'Supino',
            categoryId: categoryId,
            muscleGroupId: muscleGroupId,
          ),
        );
    final workoutId = await db
        .into(db.workouts)
        .insert(
          WorkoutsCompanion.insert(
            gymId: Value(gymId),
            performedAt: performedAt,
            notes: const Value('Treino de força'),
          ),
        );
    final workoutExerciseId = await db
        .into(db.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            workoutId: workoutId,
            exerciseId: exerciseId,
          ),
        );
    for (var set = 1; set <= 2; set++) {
      await db
          .into(db.exerciseLogs)
          .insert(
            ExerciseLogsCompanion.insert(
              workoutExerciseId: workoutExerciseId,
              setNumber: set,
              measurementValue: 42.5,
              reps: 10 - set,
            ),
          );
    }
  }

  test('Cria as tabelas e ativa a integridade referencial', () async {
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    expect(
      tables.map((row) => row.read<String>('name')),
      unorderedEquals([
        'gyms',
        'categories',
        'muscle_groups',
        'exercises',
        'workouts',
        'workout_exercises',
        'exercise_logs',
        'set_drafts',
        'sleep_logs',
        'meals',
        'meal_items',
        'water_intakes',
      ]),
    );
    final pragma = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(pragma.read<int>('foreign_keys'), 1);
  });

  test(
    'Grava e recupera um treino completo com séries e carga decimal',
    () async {
      await insertWorkout();
      final workout = await db.select(db.workouts).getSingle();
      final gym = await db.select(db.gyms).getSingle();
      final exercise = await db.select(db.exercises).getSingle();
      final category = await (db.select(
        db.categories,
      )..where((row) => row.id.equals(exercise.categoryId))).getSingle();
      final muscleGroup = await (db.select(
        db.muscleGroups,
      )..where((row) => row.id.equals(exercise.muscleGroupId))).getSingle();
      final item = await db.select(db.workoutExercises).getSingle();
      final logs = await (db.select(
        db.exerciseLogs,
      )..orderBy([(row) => OrderingTerm.asc(row.setNumber)])).get();

      expect(gym.name, 'Academia');
      expect(gym.location, 'Centro');
      expect(category.name, 'Força');
      expect(muscleGroup.name, 'Trapézio');
      expect(exercise.name, 'Supino');
      expect(exercise.categoryId, category.id);
      expect(exercise.muscleGroupId, muscleGroup.id);
      expect(exercise.measurementUnit, MeasurementUnit.kilograms);
      expect(item.measurementUnit, MeasurementUnit.kilograms);
      expect(workout.gymId, gym.id);
      expect(workout.performedAt, performedAt);
      expect(workout.notes, 'Treino de força');
      expect(item.workoutId, workout.id);
      expect(item.exerciseId, exercise.id);
      expect(logs.map((log) => log.setNumber), [1, 2]);
      expect(logs.map((log) => log.reps), [9, 8]);
      expect(
        logs.every(
          (log) =>
              log.workoutExerciseId == item.id && log.measurementValue == 42.5,
        ),
        isTrue,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );

  test(
    'Aceita academia sem localização e treino sem academia ou notas',
    () async {
      await db.into(db.gyms).insert(GymsCompanion.insert(name: 'Casa'));
      await db
          .into(db.workouts)
          .insert(WorkoutsCompanion.insert(performedAt: performedAt));
      expect((await db.select(db.gyms).getSingle()).location, isNull);
      final workout = await db.select(db.workouts).getSingle();
      expect(workout.gymId, isNull);
      expect(workout.notes, isNull);
    },
  );

  test('Gera IDs sem reutilizar o último ID excluído', () async {
    final first = await db
        .into(db.gyms)
        .insert(GymsCompanion.insert(name: 'Academia A'));
    await db.delete(db.gyms).go();
    final second = await db
        .into(db.gyms)
        .insert(GymsCompanion.insert(name: 'Academia B'));
    expect(first, greaterThan(0));
    expect(second, greaterThan(first));
  });

  test('Insere os dados iniciais uma única vez', () async {
    await db.initialize();
    await db.ensureSeedData();
    await db.ensureSeedData();
    final categories = await db.select(db.categories).get();
    final muscleGroups = await db.select(db.muscleGroups).get();
    expect(
      categories.map((category) => category.name),
      unorderedEquals(AppDatabase.initialCategories),
    );
    expect(
      muscleGroups.map((group) => group.name),
      unorderedEquals(AppDatabase.initialMuscleGroups),
    );
  });

  final references = [
    ('exercises', 'category_id', 'categories'),
    ('exercises', 'muscle_group_id', 'muscle_groups'),
    ('workouts', 'gym_id', 'gyms'),
    ('workout_exercises', 'workout_id', 'workouts'),
    ('workout_exercises', 'exercise_id', 'exercises'),
    ('exercise_logs', 'workout_exercise_id', 'workout_exercises'),
  ];

  for (final (table, column, parent) in references) {
    test(
      'Rejeita referência inválida em $table.$column e exclusão de $parent',
      () async {
        await insertWorkout();
        final foreignKeyError = throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'mensagem',
            contains('FOREIGN KEY'),
          ),
        );
        await expectLater(
          db.customStatement('UPDATE $table SET $column = 99999'),
          foreignKeyError,
        );
        await expectLater(
          db.customStatement('DELETE FROM $parent'),
          foreignKeyError,
        );
      },
    );
  }

  test('Rejeita inserção de exercício com referências inexistentes', () async {
    await expectLater(
      db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              name: 'Supino',
              categoryId: 999,
              muscleGroupId: 999,
            ),
          ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'mensagem',
          contains('FOREIGN KEY'),
        ),
      ),
    );
    expect(await db.select(db.exercises).get(), isEmpty);
  });

  test('SQLite rejeita nulos em todos os campos obrigatórios', () async {
    await insertWorkout();
    const requiredColumns = {
      'gyms': ['name'],
      'categories': ['name'],
      'muscle_groups': ['name'],
      'exercises': ['name', 'category_id', 'muscle_group_id'],
      'workouts': ['performed_at'],
      'workout_exercises': ['workout_id', 'exercise_id'],
      'exercise_logs': [
        'workout_exercise_id',
        'set_number',
        'measurement_value',
        'reps',
      ],
    };
    for (final entry in requiredColumns.entries) {
      for (final column in entry.value) {
        await expectLater(
          db.customStatement('UPDATE ${entry.key} SET $column = NULL'),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'mensagem',
              contains('NOT NULL'),
            ),
          ),
          reason: '${entry.key}.$column deve ser obrigatório',
        );
      }
    }
  });
}
