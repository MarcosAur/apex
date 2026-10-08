import 'package:drift/drift.dart';

import 'gyms.dart';

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gymId => integer().nullable().references(Gyms, #id)();
  DateTimeColumn get performedAt => dateTime()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text()
      .withDefault(const Constant('legacy'))
      .check(
        const CustomExpression<bool>(
          "status IN ('legacy', 'active', 'completed')",
        ),
      )();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get evaluation => text().nullable()();
}
