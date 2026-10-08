import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class CategoryRepository {
  CategoryRepository(this._database);
  final AppDatabase _database;

  Stream<List<Category>> watchAll() {
    final query = _database.select(_database.categories)
      ..orderBy([(row) => OrderingTerm.asc(row.name)]);
    return query.watch();
  }

  Future<int> create(String name) async => _database
      .into(_database.categories)
      .insert(CategoriesCompanion.insert(name: _normalize(name)));

  Future<void> update(int id, String name) async {
    final count =
        await (_database.update(_database.categories)
              ..where((row) => row.id.equals(id)))
            .write(CategoriesCompanion(name: Value(_normalize(name))));
    if (count == 0) throw StateError('Categoria não encontrada.');
  }

  Future<void> delete(int id) async {
    final count = await (_database.delete(
      _database.categories,
    )..where((row) => row.id.equals(id))).go();
    if (count == 0) throw StateError('Categoria não encontrada.');
  }

  String _normalize(String name) {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Informe o nome da categoria.');
    return value;
  }
}
