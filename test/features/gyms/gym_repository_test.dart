import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/gyms/data/gym_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GymRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.initialize();
    repository = GymRepository(database);
  });

  tearDown(() => database.close());

  test('Cadastra, ordena, edita e exclui academias', () async {
    final secondId = await repository.create(
      name: '  Zona Sul  ',
      location: '  Aldeota  ',
    );
    await repository.create(name: 'Academia Central', location: '   ');

    var gyms = await repository.watchAll().first;
    expect(gyms.map((gym) => gym.name), ['Academia Central', 'Zona Sul']);
    expect(gyms.first.location, isNull);
    expect(gyms.last.location, 'Aldeota');

    await repository.update(
      id: secondId,
      name: '  Academia Norte ',
      location: '',
    );
    gyms = await repository.watchAll().first;
    expect(gyms.map((gym) => gym.name), ['Academia Central', 'Academia Norte']);
    expect(gyms.last.location, isNull);

    await repository.delete(secondId);
    gyms = await repository.watchAll().first;
    expect(gyms.single.name, 'Academia Central');
  });

  test('Rejeita nome vazio no cadastro e na edição', () async {
    await expectLater(
      repository.create(name: '   '),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      repository.update(id: 1, name: '\n'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('Impede exclusão de academia vinculada a treino', () async {
    final gymId = await repository.create(name: 'Academia vinculada');
    await database
        .into(database.workouts)
        .insert(
          WorkoutsCompanion.insert(
            gymId: Value(gymId),
            performedAt: DateTime(2026, 9, 12),
          ),
        );

    await expectLater(repository.delete(gymId), throwsA(isA<Exception>()));
    expect((await repository.watchAll().first).single.id, gymId);
  });
}
