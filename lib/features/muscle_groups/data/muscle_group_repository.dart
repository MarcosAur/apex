import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class MuscleGroupRepository {
  MuscleGroupRepository(this._database);
  final AppDatabase _database;

  Stream<List<MuscleGroup>> watchAll() {
    final query = _database.select(_database.muscleGroups)
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.watch();
  }

  Future<int> create(String name) async => _database
      .into(_database.muscleGroups)
      .insert(MuscleGroupsCompanion.insert(name: _normalize(name)));

  Future<void> update(int id, String name) async {
    final count =
        await (_database.update(_database.muscleGroups)
              ..where((row) => row.id.equals(id)))
            .write(MuscleGroupsCompanion(name: Value(_normalize(name))));
    if (count == 0) throw StateError('Grupo muscular não encontrado.');
  }

  Future<void> delete(int id) async {
    final count = await (_database.delete(
      _database.muscleGroups,
    )..where((row) => row.id.equals(id))).go();
    if (count == 0) throw StateError('Grupo muscular não encontrado.');
  }

  String _normalize(String name) {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Informe o nome do grupo muscular.');
    return value;
  }
}
