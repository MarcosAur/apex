import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../exercises/domain/measurement_unit.dart';
import '../domain/effort_level.dart';

class SessionExercise {
  const SessionExercise(this.item, this.exercise, this.category, this.muscle);
  final WorkoutExercise item;
  final Exercise exercise;
  final String category;
  final String muscle;
}

class WorkoutSession {
  const WorkoutSession(this.workout, this.exercises, this.logs, this.drafts);
  final Workout workout;
  final List<SessionExercise> exercises;
  final List<ExerciseLog> logs;
  final List<SetDraft> drafts;
}

class WorkoutRepository {
  WorkoutRepository(this.db);
  final AppDatabase db;
  Future<void> _pending = Future.value();

  // Preserve input order even when several fields change before SQLite replies.
  Future<T> _write<T>(Future<T> Function() action) {
    final result = _pending.then((_) => db.transaction(action));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Workout> _active(int id) async {
    final workout = await (db.select(
      db.workouts,
    )..where((w) => w.id.equals(id))).getSingle();
    if (workout.status != 'active') {
      throw StateError('Este treino não está ativo.');
    }
    return workout;
  }

  Future<WorkoutExercise> _activeItem(int id) async {
    final item = await (db.select(
      db.workoutExercises,
    )..where((e) => e.id.equals(id))).getSingle();
    await _active(item.workoutId);
    return item;
  }

  Stream<List<Workout>> watchAll() => (db.select(
    db.workouts,
  )..orderBy([(w) => OrderingTerm.desc(w.performedAt)])).watch();

  Stream<Workout?> watchActive() => (db.select(
    db.workouts,
  )..where((w) => w.status.equals('active'))).watchSingleOrNull();

  Future<int> start({DateTime? performedAt}) => _write(() async {
    final active = await (db.select(
      db.workouts,
    )..where((w) => w.status.equals('active'))).getSingleOrNull();
    if (active != null) return active.id;
    return db
        .into(db.workouts)
        .insert(
          WorkoutsCompanion.insert(
            performedAt: performedAt ?? DateTime.now(),
            status: const Value('active'),
          ),
        );
  });

  Future<void> resumeLegacy(int id) => _write(() async {
    final current = await (db.select(
      db.workouts,
    )..where((w) => w.status.equals('active'))).getSingleOrNull();
    if (current != null) {
      throw StateError('Encerre o treino ativo antes de retomar este.');
    }
    final changed =
        await (db.update(db.workouts)
              ..where((w) => w.id.equals(id) & w.status.equals('legacy')))
            .write(const WorkoutsCompanion(status: Value('active')));
    if (changed != 1) throw StateError('Este treino não pode ser retomado.');
  });

  Future<void> updateDetails(
    int id, {
    Value<int?> gymId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> evaluation = const Value.absent(),
    Value<DateTime> performedAt = const Value.absent(),
  }) => _write(() async {
    await _active(id);
    await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
      WorkoutsCompanion(
        gymId: gymId,
        notes: notes,
        title: title,
        evaluation: evaluation,
        performedAt: performedAt,
      ),
    );
  });

  Future<int> addExercise(int workoutId, int exerciseId) => _write(() async {
    await _active(workoutId);
    final exercise = await (db.select(
      db.exercises,
    )..where((row) => row.id.equals(exerciseId))).getSingle();
    return db
        .into(db.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            workoutId: workoutId,
            exerciseId: exerciseId,
            measurementUnit: Value(exercise.measurementUnit),
          ),
        );
  });

  Future<void> removeExercise(int itemId) => _write(() async {
    await _activeItem(itemId);
    await (db.delete(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.equals(itemId))).go();
    await (db.delete(
      db.exerciseLogs,
    )..where((l) => l.workoutExerciseId.equals(itemId))).go();
    await (db.delete(
      db.workoutExercises,
    )..where((e) => e.id.equals(itemId))).go();
  });

  void _validate({
    required MeasurementUnit unit,
    required double measurementValue,
    required int reps,
  }) {
    if (!measurementValue.isFinite) {
      throw ArgumentError('Informe um valor de medida válido.');
    }
    switch (unit) {
      case MeasurementUnit.kilograms:
        if (measurementValue < 0) {
          throw ArgumentError(
            'Informe uma carga válida, maior ou igual a zero.',
          );
        }
        if (reps <= 0) {
          throw ArgumentError('Informe repetições inteiras maiores que zero.');
        }
        break;
      case MeasurementUnit.kilometers:
        if (measurementValue <= 0) {
          throw ArgumentError('Informe uma distância maior que zero.');
        }
        if (reps != 1) {
          throw ArgumentError(
            'Registros em quilômetros devem ter uma repetição.',
          );
        }
        break;
    }
  }

  Future<int> _nextSet(int itemId) async {
    final rows = await (db.select(
      db.exerciseLogs,
    )..where((l) => l.workoutExerciseId.equals(itemId))).get();
    return rows.fold<int>(
          0,
          (max, l) => l.setNumber > max ? l.setNumber : max,
        ) +
        1;
  }

  Future<int> addLog({
    required int workoutExerciseId,
    required int setNumber,
    required double measurementValue,
    required int reps,
    required EffortLevel effortLevel,
  }) => _write(() async {
    final item = await _activeItem(workoutExerciseId);
    _validate(
      unit: item.measurementUnit,
      measurementValue: measurementValue,
      reps: reps,
    );
    if (setNumber != await _nextSet(workoutExerciseId)) {
      throw ArgumentError('Número de série inválido.');
    }
    return db
        .into(db.exerciseLogs)
        .insert(
          ExerciseLogsCompanion.insert(
            workoutExerciseId: workoutExerciseId,
            setNumber: setNumber,
            measurementValue: measurementValue,
            reps: reps,
            effortLevel: Value(effortLevel),
          ),
        );
  });
  double? _parsePace(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length != 2) return null;
      final minutes = double.tryParse(parts[0]);
      final seconds = double.tryParse(parts[1]);
      if (minutes == null || seconds == null) return null;
      return minutes + (seconds / 60.0);
    }
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  String _formatPace(double pace) {
    final minutes = pace.truncate();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> beginDraft(int itemId, {int? logId}) => _write(() async {
    final item = await _activeItem(itemId);
    final existing = await (db.select(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.equals(itemId))).getSingleOrNull();
    if (existing != null) {
      throw StateError('Conclua ou descarte o rascunho deste exercício.');
    }
    ExerciseLog? log;
    if (logId != null) {
      log =
          await (db.select(db.exerciseLogs)..where(
                (l) => l.id.equals(logId) & l.workoutExerciseId.equals(itemId),
              ))
              .getSingle();
    }
    await db
        .into(db.setDrafts)
        .insert(
          SetDraftsCompanion.insert(
            workoutExerciseId: Value(itemId),
            editingLogId: Value(logId),
            measurementText: Value(log?.measurementValue.toString() ?? ''),
            repsText: Value(
              item.measurementUnit.requiresUserReps
                  ? log?.reps.toString() ?? ''
                  : '',
            ),
            effortCode: Value(log?.effortLevel?.storageValue),
            paceText: Value(log?.pace != null ? _formatPace(log!.pace) : ''),
          ),
        );
  });
  Future<void> saveDraft(
    int itemId,
    String measurementValue,
    String reps,
    String? effort,
    String pace,
  ) => _write(() async {
    final item = await _activeItem(itemId);
    if (effort != null &&
        !EffortLevel.values.any((e) => e.storageValue == effort)) {
      throw ArgumentError('Esforço inválido.');
    }
    final count =
        await (db.update(
          db.setDrafts,
        )..where((d) => d.workoutExerciseId.equals(itemId))).write(
          SetDraftsCompanion(
            measurementText: Value(measurementValue),
            repsText: Value(item.measurementUnit.requiresUserReps ? reps : ''),
            effortCode: Value(effort),
            paceText: Value(pace),
          ),
        );
    if (count == 0) throw StateError('Rascunho não encontrado.');
  });

  Future<void> discardDraft(int itemId) => _write(() async {
    await _activeItem(itemId);
    await (db.delete(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.equals(itemId))).go();
  });

  Future<void> commitDraft(int itemId) => _write(() async {
    final item = await _activeItem(itemId);
    final draft = await (db.select(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.equals(itemId))).getSingle();
    final measurementValue = double.tryParse(
      draft.measurementText.trim().replaceAll(',', '.'),
    );
    final reps = item.measurementUnit.requiresUserReps
        ? int.tryParse(draft.repsText.trim())
        : 1;
    if (measurementValue == null || reps == null) {
      throw ArgumentError('Informe os valores obrigatórios corretamente.');
    }
    _validate(
      unit: item.measurementUnit,
      measurementValue: measurementValue,
      reps: reps,
    );
    if (draft.effortCode == null) {
      throw ArgumentError('Selecione o nível de esforço.');
    }
    final effort = EffortLevel.values.firstWhere(
      (e) => e.storageValue == draft.effortCode,
    );
    if (draft.editingLogId == null) {
      await db
          .into(db.exerciseLogs)
          .insert(
            ExerciseLogsCompanion.insert(
              workoutExerciseId: itemId,
              setNumber: await _nextSet(itemId),
              measurementValue: measurementValue,
              reps: reps,
              pace: Value(_parsePace(draft.paceText)),
              effortLevel: Value(effort),
            ),
          );
    } else {
      final changed =
          await (db.update(db.exerciseLogs)..where(
                (l) =>
                    l.id.equals(draft.editingLogId!) &
                    l.workoutExerciseId.equals(itemId),
              ))
              .write(
                ExerciseLogsCompanion(
                  measurementValue: Value(measurementValue),
                  reps: Value(reps),
                  pace: Value(_parsePace(draft.paceText)),
                  effortLevel: Value(effort),
                ),
              );
      if (changed != 1) throw StateError('Série não encontrada.');
    }
    await (db.delete(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.equals(itemId))).go();
  });

  Future<void> removeLog(int id) => _write(() async {
    final log = await (db.select(
      db.exerciseLogs,
    )..where((l) => l.id.equals(id))).getSingle();
    await _activeItem(log.workoutExerciseId);
    final drafts = await (db.select(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.equals(log.workoutExerciseId))).get();
    if (drafts.isNotEmpty) {
      throw StateError('Conclua ou descarte o rascunho primeiro.');
    }
    await (db.delete(db.exerciseLogs)..where((l) => l.id.equals(id))).go();
    final remaining =
        await (db.select(db.exerciseLogs)
              ..where((l) => l.workoutExerciseId.equals(log.workoutExerciseId))
              ..orderBy([(l) => OrderingTerm.asc(l.setNumber)]))
            .get();
    for (var i = 0; i < remaining.length; i++) {
      await (db.update(db.exerciseLogs)
            ..where((l) => l.id.equals(remaining[i].id)))
          .write(ExerciseLogsCompanion(setNumber: Value(i + 1)));
    }
  });

  Future<void> finish(int id, {DateTime? completedAt}) => _write(() async {
    final workout = await _active(id);
    final drafts = await db
        .customSelect(
          'SELECT d.workout_exercise_id FROM set_drafts d JOIN workout_exercises e ON e.id = d.workout_exercise_id WHERE e.workout_id = ?',
          variables: [Variable(id)],
        )
        .get();
    if (drafts.isNotEmpty) {
      throw StateError('Conclua ou descarte os rascunhos antes de encerrar.');
    }
    final end = completedAt ?? DateTime.now();
    if (end.isBefore(workout.performedAt)) {
      throw ArgumentError('Encerramento anterior ao início.');
    }
    await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
      WorkoutsCompanion(
        status: const Value('completed'),
        completedAt: Value(end),
      ),
    );
  });

  Future<void> deleteWorkout(int id) => _write(() async {
    final exists = await (db.select(
      db.workouts,
    )..where((workout) => workout.id.equals(id))).getSingleOrNull();
    if (exists == null) {
      throw StateError('Treino não encontrado.');
    }

    await db.customStatement(
      'DELETE FROM set_drafts WHERE workout_exercise_id IN '
      '(SELECT id FROM workout_exercises WHERE workout_id = ?)',
      [id],
    );
    await db.customStatement(
      'DELETE FROM exercise_logs WHERE workout_exercise_id IN '
      '(SELECT id FROM workout_exercises WHERE workout_id = ?)',
      [id],
    );
    await (db.delete(
      db.workoutExercises,
    )..where((item) => item.workoutId.equals(id))).go();
    final deleted = await (db.delete(
      db.workouts,
    )..where((workout) => workout.id.equals(id))).go();
    if (deleted != 1) {
      throw StateError('Não foi possível excluir o treino.');
    }
  });

  Stream<WorkoutSession> watchSession(int id) => db
      .customSelect(
        'SELECT id FROM workouts WHERE id = ?',
        variables: [Variable(id)],
        readsFrom: {
          db.workouts,
          db.workoutExercises,
          db.exercises,
          db.categories,
          db.muscleGroups,
          db.exerciseLogs,
          db.setDrafts,
        },
      )
      .watch()
      .asyncMap((_) => loadSession(id));

  Future<WorkoutSession> loadSession(int id) => db.transaction(() async {
    final workout = await (db.select(
      db.workouts,
    )..where((w) => w.id.equals(id))).getSingle();
    final rows =
        await (db.select(db.workoutExercises).join([
                innerJoin(
                  db.exercises,
                  db.exercises.id.equalsExp(db.workoutExercises.exerciseId),
                ),
                innerJoin(
                  db.categories,
                  db.categories.id.equalsExp(db.exercises.categoryId),
                ),
                innerJoin(
                  db.muscleGroups,
                  db.muscleGroups.id.equalsExp(db.exercises.muscleGroupId),
                ),
              ])
              ..where(db.workoutExercises.workoutId.equals(id))
              ..orderBy([OrderingTerm.asc(db.workoutExercises.id)]))
            .get();
    final items = rows
        .map(
          (r) => SessionExercise(
            r.readTable(db.workoutExercises),
            r.readTable(db.exercises),
            r.readTable(db.categories).name,
            r.readTable(db.muscleGroups).name,
          ),
        )
        .toList();
    final ids = items.map((e) => e.item.id).toList();
    final logs =
        await (db.select(db.exerciseLogs)
              ..where((l) => l.workoutExerciseId.isIn(ids))
              ..orderBy([(l) => OrderingTerm.asc(l.setNumber)]))
            .get();
    final drafts = await (db.select(
      db.setDrafts,
    )..where((d) => d.workoutExerciseId.isIn(ids))).get();
    return WorkoutSession(workout, items, logs, drafts);
  });
}
