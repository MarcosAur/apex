import 'package:drift/drift.dart';

import 'workout_exercises.dart';

class SetDrafts extends Table {
  IntColumn get workoutExerciseId =>
      integer().references(WorkoutExercises, #id)();
  IntColumn get editingLogId => integer().nullable()();
  TextColumn get measurementText => text().withDefault(const Constant(''))();
  TextColumn get repsText => text().withDefault(const Constant(''))();
  TextColumn get effortCode => text().nullable()();
  TextColumn get paceText => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {workoutExerciseId};
}
