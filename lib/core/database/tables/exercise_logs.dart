import 'package:drift/drift.dart';

import '../../../features/workouts/domain/effort_level.dart';

import 'workout_exercises.dart';

class ExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId =>
      integer().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  RealColumn get measurementValue => real()();
  IntColumn get reps => integer()();
  TextColumn get effortLevel => text()
      .nullable()
      .customConstraint(
        "CHECK (effort_level IN ('very_low', 'low', 'medium', 'high', "
        "'failure_at_end', 'failure_before_end'))",
      )
      .map(const EffortLevelConverter())();
  RealColumn get pace => real().nullable()();
}

class EffortLevelConverter extends TypeConverter<EffortLevel, String> {
  const EffortLevelConverter();
  @override
  EffortLevel fromSql(String fromDb) =>
      EffortLevel.values.firstWhere((level) => level.storageValue == fromDb);
  @override
  String toSql(EffortLevel value) => value.storageValue;
}
