import 'package:drift/drift.dart';

import '../../../features/wellness/domain/meal_type.dart';

@TableIndex(name: 'meals_eaten_at', columns: {#eatenAt})
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get mealType => text()
      .nullable()
      .check(
        const CustomExpression<bool>(
          "meal_type IN ('breakfast', 'lunch', 'snack', 'dinner', 'supper', "
          "'pre_workout', 'post_workout', 'other')",
        ),
      )
      .map(const MealTypeConverter())();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class MealTypeConverter extends TypeConverter<MealType, String> {
  const MealTypeConverter();

  @override
  MealType fromSql(String fromDb) => MealType.fromStorage(fromDb);

  @override
  String toSql(MealType value) => value.storageValue;
}
