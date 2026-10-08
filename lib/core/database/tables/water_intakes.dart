import 'package:drift/drift.dart';

@TableIndex(name: 'water_intakes_consumed_at', columns: {#consumedAt})
class WaterIntakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get consumedAt => dateTime()();
  IntColumn get amountMl => integer().check(
    const CustomExpression<bool>('amount_ml BETWEEN 1 AND 5000'),
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
