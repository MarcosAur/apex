import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/muscle_groups/data/muscle_group_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MuscleGroupRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.initialize();
    repository = MuscleGroupRepository(database);
  });

  tearDown(() => database.close());

  test('Lista seed e executa cadastro, edição e exclusão', () async {
    expect((await repository.watchAll().first).length, 10);
    final id = await repository.create('  Antebraços  ');
    await repository.update(id, 'Antebraço');
    expect(
      (await repository.watchAll().first).any(
        (item) => item.name == 'Antebraço',
      ),
      isTrue,
    );
    await repository.delete(id);
    expect((await repository.watchAll().first).length, 10);
  });

  test('Rejeita nome vazio e duplicado', () async {
    await expectLater(repository.create(' '), throwsA(isA<ArgumentError>()));
    await expectLater(repository.create('Core'), throwsA(isA<Exception>()));
  });
}
