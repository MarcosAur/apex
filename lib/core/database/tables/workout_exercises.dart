import 'package:drift/drift.dart';

import 'exercises.dart' show Exercises, MeasurementUnitConverter;
import 'workouts.dart';

class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  TextColumn get measurementUnit => text()
      .withDefault(const Constant('kg'))
      .check(const CustomExpression<bool>("measurement_unit IN ('kg', 'km')"))
      .map(const MeasurementUnitConverter())();
}
