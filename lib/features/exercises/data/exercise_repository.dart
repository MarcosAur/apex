import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/measurement_unit.dart';
import 'exercise_list_item.dart';

class ExerciseRepository {
  ExerciseRepository(this._database);
  final AppDatabase _database;

  Stream<List<ExerciseListItem>> watchAll() {
    final query = _database.select(_database.exercises).join([
      innerJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.exercises.categoryId),
      ),
      innerJoin(
        _database.muscleGroups,
        _database.muscleGroups.id.equalsExp(_database.exercises.muscleGroupId),
      ),
    ])..orderBy([OrderingTerm.asc(_database.exercises.name)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ExerciseListItem(
              exercise: row.readTable(_database.exercises),
              categoryName: row.readTable(_database.categories).name,
              muscleGroupName: row.readTable(_database.muscleGroups).name,
            ),
          )
          .toList(),
    );
  }

  Future<int> create({
    required String name,
    required int categoryId,
    required int muscleGroupId,
    required MeasurementUnit measurementUnit,
  }) async {
    return _database
        .into(_database.exercises)
        .insert(
          ExercisesCompanion.insert(
            name: _normalizeName(name),
            categoryId: categoryId,
            muscleGroupId: muscleGroupId,
            measurementUnit: Value(measurementUnit),
          ),
        );
  }

  Future<void> update({
    required int id,
    required String name,
    required int categoryId,
    required int muscleGroupId,
    required MeasurementUnit measurementUnit,
  }) async {
    final count =
        await (_database.update(
          _database.exercises,
        )..where((row) => row.id.equals(id))).write(
          ExercisesCompanion(
            name: Value(_normalizeName(name)),
            categoryId: Value(categoryId),
            muscleGroupId: Value(muscleGroupId),
            measurementUnit: Value(measurementUnit),
          ),
        );
    if (count == 0) throw StateError('Exercício não encontrado.');
  }

  Future<void> delete(int id) async {
    final count = await (_database.delete(
      _database.exercises,
    )..where((row) => row.id.equals(id))).go();
    if (count == 0) throw StateError('Exercício não encontrado.');
  }

  String _normalizeName(String name) {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Informe o nome do exercício.');
    return value;
  }
}
