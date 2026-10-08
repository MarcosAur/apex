import 'package:drift/drift.dart';

/// Período de sono; `sleep_date` é o dia civil local em que se acorda.
@TableIndex(name: 'sleep_logs_sleep_date', columns: {#sleepDate})
class SleepLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sleepDate => text().check(
    const CustomExpression<bool>('date(sleep_date) IS sleep_date'),
  )();
  DateTimeColumn get bedTime => dateTime().nullable()();
  DateTimeColumn get wakeTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().check(
    const CustomExpression<bool>('duration_minutes BETWEEN 1 AND 1440'),
  )();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<String> get customConstraints => [
    'CHECK ((bed_time IS NULL) = (wake_time IS NULL))',
    'CHECK (wake_time IS NULL OR wake_time > bed_time)',
  ];
}
