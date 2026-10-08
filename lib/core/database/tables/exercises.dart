import 'package:drift/drift.dart';

import '../../../features/exercises/domain/measurement_unit.dart';
import 'categories.dart';
import 'muscle_groups.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get muscleGroupId => integer().references(MuscleGroups, #id)();
  TextColumn get measurementUnit => text()
      .withDefault(const Constant('kg'))
      .check(const CustomExpression<bool>("measurement_unit IN ('kg', 'km')"))
      .map(const MeasurementUnitConverter())();
}

class MeasurementUnitConverter extends TypeConverter<MeasurementUnit, String> {
  const MeasurementUnitConverter();

  @override
  MeasurementUnit fromSql(String fromDb) => MeasurementUnit.fromStorage(fromDb);

  @override
  String toSql(MeasurementUnit value) => value.storageValue;
}
