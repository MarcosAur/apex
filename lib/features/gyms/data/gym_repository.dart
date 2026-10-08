import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class GymRepository {
  GymRepository(this._database);

  final AppDatabase _database;

  Stream<List<Gym>> watchAll() {
    final query = _database.select(_database.gyms)
      ..orderBy([(gym) => OrderingTerm.asc(gym.name)]);
    return query.watch();
  }

  Future<int> create({required String name, String? location}) async {
    return _database
        .into(_database.gyms)
        .insert(
          GymsCompanion.insert(
            name: _normalizeName(name),
            location: Value(_normalizeLocation(location)),
          ),
        );
  }

  Future<void> update({
    required int id,
    required String name,
    String? location,
  }) async {
    final changedRows =
        await (_database.update(
          _database.gyms,
        )..where((gym) => gym.id.equals(id))).write(
          GymsCompanion(
            name: Value(_normalizeName(name)),
            location: Value(_normalizeLocation(location)),
          ),
        );
    if (changedRows == 0) {
      throw StateError('Academia não encontrada.');
    }
  }

  Future<void> delete(int id) async {
    final deletedRows = await (_database.delete(
      _database.gyms,
    )..where((gym) => gym.id.equals(id))).go();
    if (deletedRows == 0) {
      throw StateError('Academia não encontrada.');
    }
  }

  String _normalizeName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'name', 'Informe o nome da academia.');
    }
    return normalized;
  }

  String? _normalizeLocation(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
