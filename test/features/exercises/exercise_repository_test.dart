import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/exercises/data/exercise_repository.dart';
import 'package:apex/features/exercises/domain/measurement_unit.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ExerciseRepository repository;
  late int pushId;
  late int pullId;
  late int chestId;
  late int backId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.initialize();
    repository = ExerciseRepository(database);
    pushId = (await (database.select(
      database.categories,
    )..where((row) => row.name.equals('Push'))).getSingle()).id;
    pullId = (await (database.select(
      database.categories,
    )..where((row) => row.name.equals('Pull'))).getSingle()).id;
    chestId = (await (database.select(
      database.muscleGroups,
    )..where((row) => row.name.equals('Peitoral'))).getSingle()).id;
    backId = (await (database.select(
      database.muscleGroups,
    )..where((row) => row.name.equals('Costas'))).getSingle()).id;
  });

  tearDown(() => database.close());

  test('Cadastra, lista com relações, edita e exclui', () async {
    final id = await repository.create(
      name: '  Supino reto  ',
      categoryId: pushId,
      muscleGroupId: chestId,
      measurementUnit: MeasurementUnit.kilograms,
    );
    var item = (await repository.watchAll().first).single;
    expect(item.exercise.name, 'Supino reto');
    expect(item.categoryName, 'Push');
    expect(item.muscleGroupName, 'Peitoral');

    await repository.update(
      id: id,
      name: 'Remada',
      categoryId: pullId,
      muscleGroupId: backId,
      measurementUnit: MeasurementUnit.kilometers,
    );
    item = (await repository.watchAll().first).single;
    expect(item.exercise.name, 'Remada');
    expect(item.exercise.measurementUnit, MeasurementUnit.kilometers);
    expect(item.categoryName, 'Pull');
    expect(item.muscleGroupName, 'Costas');

    await repository.delete(id);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('Rejeita nome vazio e referências inexistentes', () async {
    await expectLater(
      repository.create(
        name: ' ',
        categoryId: pushId,
        muscleGroupId: chestId,
        measurementUnit: MeasurementUnit.kilograms,
      ),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.create(
        name: 'Inválido',
        categoryId: 99999,
        muscleGroupId: 99999,
        measurementUnit: MeasurementUnit.kilograms,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('Impede exclusão de exercício usado em treino', () async {
    final exerciseId = await repository.create(
      name: 'Supino',
      categoryId: pushId,
      muscleGroupId: chestId,
      measurementUnit: MeasurementUnit.kilograms,
    );
    final workoutId = await database
        .into(database.workouts)
        .insert(WorkoutsCompanion.insert(performedAt: DateTime(2026, 9, 12)));
    await database
        .into(database.workoutExercises)
        .insert(
          WorkoutExercisesCompanion.insert(
            workoutId: workoutId,
            exerciseId: exerciseId,
          ),
        );
    await expectLater(repository.delete(exerciseId), throwsA(isA<Exception>()));
    expect((await repository.watchAll().first).single.exercise.id, exerciseId);
  });
}
