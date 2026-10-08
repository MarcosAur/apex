import 'dart:io';

import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/exercises/domain/measurement_unit.dart';
import 'package:apex/features/workouts/data/workout_repository.dart';
import 'package:apex/features/workouts/domain/effort_level.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> exerciseFixture(
  AppDatabase db, {
  MeasurementUnit measurementUnit = MeasurementUnit.kilograms,
  String name = 'Supino',
}) async {
  await db.initialize();
  final category = (await db.select(db.categories).get()).first;
  final muscle = (await db.select(db.muscleGroups).get()).first;
  return db
      .into(db.exercises)
      .insert(
        ExercisesCompanion.insert(
          name: name,
          categoryId: category.id,
          muscleGroupId: muscle.id,
          measurementUnit: Value(measurementUnit),
        ),
      );
}

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });
  tearDown(() => db.close());

  test(
    'Toques simultâneos retomam a mesma sessão; índice protege unicidade',
    () async {
      final ids = await Future.wait(List.generate(8, (_) => repo.start()));
      expect(ids.toSet().length, 1);
      expect((await db.select(db.workouts).get()).length, 1);
      await expectLater(
        db
            .into(db.workouts)
            .insert(
              WorkoutsCompanion.insert(
                performedAt: DateTime.now(),
                status: const Value('active'),
              ),
            ),
        throwsA(isA<Exception>()),
      );
    },
  );

  test(
    'Vários exercícios e séries; validação, edição, exclusão e encerramento',
    () async {
      final exercise = await exerciseFixture(db);
      final id = await repo.start();
      final a = await repo.addExercise(id, exercise);
      final b = await repo.addExercise(id, exercise);
      await repo.beginDraft(a);
      await repo.saveDraft(a, '-1', '10', 'high');
      await expectLater(repo.commitDraft(a), throwsArgumentError);
      await repo.saveDraft(a, '30', '1.5', 'high');
      await expectLater(repo.commitDraft(a), throwsArgumentError);
      await repo.saveDraft(a, 'NaN', '10', 'high');
      await expectLater(repo.commitDraft(a), throwsArgumentError);
      await repo.saveDraft(a, '30', '10', null);
      await expectLater(repo.commitDraft(a), throwsArgumentError);
      await expectLater(repo.finish(id), throwsStateError);
      await repo.saveDraft(a, '42,5', '10', 'high');
      await repo.commitDraft(a);
      await repo.beginDraft(a);
      await repo.saveDraft(a, '40', '8', 'failure_at_end');
      await repo.commitDraft(a);
      await repo.beginDraft(b);
      await repo.saveDraft(b, '20', '12', 'medium');
      await repo.commitDraft(b);
      var session = await repo.loadSession(id);
      expect(session.exercises.length, 2);
      expect(session.logs.length, 3);
      final first = session.logs.firstWhere(
        (l) => l.workoutExerciseId == a && l.setNumber == 1,
      );
      await repo.beginDraft(a, logId: first.id);
      await repo.saveDraft(a, '45', '9', 'failure_before_end');
      await repo.commitDraft(a);
      expect(
        (await repo.loadSession(id)).logs
            .firstWhere((l) => l.id == first.id)
            .measurementValue,
        45,
      );
      await repo.removeLog(first.id);
      session = await repo.loadSession(id);
      expect(
        session.logs.where((l) => l.workoutExerciseId == a).single.setNumber,
        1,
      );
      await repo.beginDraft(b);
      await repo.removeExercise(b);
      expect((await repo.loadSession(id)).drafts, isEmpty);
      await repo.finish(id);
      session = await repo.loadSession(id);
      expect(session.workout.status, 'completed');
      expect(session.workout.completedAt, isNotNull);
      expect(session.logs.single.effortLevel, EffortLevel.failureAtEnd);
      await expectLater(
        repo.updateDetails(id, notes: const Value('Mudança')),
        throwsStateError,
      );
      await expectLater(repo.addExercise(id, exercise), throwsStateError);
      await expectLater(repo.beginDraft(a), throwsStateError);
      await expectLater(
        repo.removeLog(session.logs.single.id),
        throwsStateError,
      );
      await expectLater(repo.removeExercise(a), throwsStateError);
      await expectLater(repo.finish(id), throwsStateError);
      await expectLater(
        repo.addLog(
          workoutExerciseId: a,
          setNumber: 2,
          measurementValue: 20,
          reps: 10,
          effortLevel: EffortLevel.low,
        ),
        throwsStateError,
      );
      expect(await repo.start(), isNot(id));
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );

  test(
    'Legado só retoma sem outro treino ativo e não inventa encerramento',
    () async {
      final legacy = await db
          .into(db.workouts)
          .insert(WorkoutsCompanion.insert(performedAt: DateTime(2025)));
      final active = await repo.start();
      await expectLater(repo.resumeLegacy(legacy), throwsStateError);
      await repo.finish(active);
      await repo.resumeLegacy(legacy);
      expect(await repo.start(), legacy);
      expect((await repo.loadSession(legacy)).workout.completedAt, isNull);
    },
  );

  test('Exclui treino e todos os registros vinculados em transação', () async {
    final exercise = await exerciseFixture(db);
    final preserved = await db
        .into(db.workouts)
        .insert(WorkoutsCompanion.insert(performedAt: DateTime(2024)));
    final workout = await repo.start();
    final item = await repo.addExercise(workout, exercise);
    await repo.addLog(
      workoutExerciseId: item,
      setNumber: 1,
      measurementValue: 32.5,
      reps: 10,
      effortLevel: EffortLevel.medium,
    );
    await repo.beginDraft(item);

    await repo.deleteWorkout(workout);

    expect(await db.select(db.setDrafts).get(), isEmpty);
    expect(await db.select(db.exerciseLogs).get(), isEmpty);
    expect(await db.select(db.workoutExercises).get(), isEmpty);
    expect((await db.select(db.workouts).get()).map((row) => row.id), [
      preserved,
    ]);
    expect(await repo.watchActive().first, isNull);
    expect(await repo.start(), isNot(workout));
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    await expectLater(repo.deleteWorkout(workout), throwsStateError);
  });

  test(
    'Rascunho incompleto, observações e séries sobrevivem à reabertura',
    () async {
      final directory = await Directory.systemTemp.createTemp('apex_session_');
      await db.close();
      final file = File('${directory.path}/session.sqlite');
      var disk = AppDatabase(NativeDatabase(file));
      try {
        var repository = WorkoutRepository(disk);
        final exercise = await exerciseFixture(disk);
        final id = await repository.start();
        final gym = await disk
            .into(disk.gyms)
            .insert(GymsCompanion.insert(name: 'Casa'));
        final item = await repository.addExercise(id, exercise);
        await repository.updateDetails(
          id,
          gymId: Value(gym),
          notes: const Value('Treino local'),
        );
        await repository.addLog(
          workoutExerciseId: item,
          setNumber: 1,
          measurementValue: 10,
          reps: 8,
          effortLevel: EffortLevel.low,
        );
        await repository.beginDraft(item);
        await Future.wait([
          repository.saveDraft(item, '2', '', null),
          repository.saveDraft(item, '20,', '', 'medium'),
          repository.saveDraft(item, '20,', '1', 'high'),
        ]);
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        repository = WorkoutRepository(disk);
        expect(await repository.start(), id);
        var session = await repository.loadSession(id);
        expect(session.workout.notes, 'Treino local');
        expect(session.workout.gymId, gym);
        expect(session.logs.single.reps, 8);
        expect(session.drafts.single.measurementText, '20,');
        expect(session.drafts.single.repsText, '1');
        expect(session.drafts.single.effortCode, 'high');
        await repository.discardDraft(item);
        await repository.finish(id);
        await disk.close();
        disk = AppDatabase(NativeDatabase(file));
        repository = WorkoutRepository(disk);
        session = await repository.loadSession(id);
        expect(session.workout.status, 'completed');
        expect(session.logs.length, 1);
        expect(session.drafts, isEmpty);
        expect(await repository.start(), isNot(id));
      } finally {
        await disk.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'Quilômetros persistem distância com uma repetição e preservam snapshot',
    () async {
      final exercise = await exerciseFixture(
        db,
        measurementUnit: MeasurementUnit.kilometers,
        name: 'Corrida',
      );
      final workout = await repo.start();
      final item = await repo.addExercise(workout, exercise);

      var session = await repo.loadSession(workout);
      expect(
        session.exercises.single.item.measurementUnit,
        MeasurementUnit.kilometers,
      );
      await (db.update(
        db.exercises,
      )..where((row) => row.id.equals(exercise))).write(
        const ExercisesCompanion(
          measurementUnit: Value(MeasurementUnit.kilograms),
        ),
      );
      session = await repo.loadSession(workout);
      expect(
        session.exercises.single.item.measurementUnit,
        MeasurementUnit.kilometers,
      );

      await repo.beginDraft(item);
      await repo.saveDraft(item, '5,25', '99', 'medium');
      expect((await repo.loadSession(workout)).drafts.single.repsText, isEmpty);
      await repo.commitDraft(item);
      final log = (await repo.loadSession(workout)).logs.single;
      expect(log.measurementValue, 5.25);
      expect(log.reps, 1);

      await expectLater(
        repo.addLog(
          workoutExerciseId: item,
          setNumber: 2,
          measurementValue: 1,
          reps: 2,
          effortLevel: EffortLevel.low,
        ),
        throwsArgumentError,
      );
      await expectLater(
        repo.addLog(
          workoutExerciseId: item,
          setNumber: 2,
          measurementValue: 0,
          reps: 1,
          effortLevel: EffortLevel.low,
        ),
        throwsArgumentError,
      );
    },
  );
}
