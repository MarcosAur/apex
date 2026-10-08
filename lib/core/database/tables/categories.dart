import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}
