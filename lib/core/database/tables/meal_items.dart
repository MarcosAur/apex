import 'package:drift/drift.dart';

import '../../../features/wellness/domain/quantity_unit.dart';
import 'meals.dart';

class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId => integer().references(Meals, #id)();
  IntColumn get position =>
      integer().check(const CustomExpression<bool>('position >= 1'))();
  TextColumn get name =>
      text().check(const CustomExpression<bool>('length(trim(name)) > 0'))();
  RealColumn get quantityValue => real().nullable().check(
    const CustomExpression<bool>('quantity_value > 0'),
  )();
  TextColumn get quantityUnit => text()
      .nullable()
      .check(
        const CustomExpression<bool>("quantity_unit IN ('g', 'ml', 'unit')"),
      )
      .map(const QuantityUnitConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [
    {mealId, position},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK ((quantity_value IS NULL) = (quantity_unit IS NULL))',
  ];
}

class QuantityUnitConverter extends TypeConverter<QuantityUnit, String> {
  const QuantityUnitConverter();

  @override
  QuantityUnit fromSql(String fromDb) => QuantityUnit.fromStorage(fromDb);

  @override
  String toSql(QuantityUnit value) => value.storageValue;
}
