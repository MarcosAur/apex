import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/categories/data/category_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.initialize();
    repository = CategoryRepository(database);
  });

  tearDown(() => database.close());

  test('Lista seed e executa cadastro, edição e exclusão', () async {
    expect((await repository.watchAll().first).length, 3);
    final id = await repository.create('  Mobilidade  ');
    expect((await repository.watchAll().first).first.name, 'Legs');
    await repository.update(id, 'Alongamento');
    expect(
      (await repository.watchAll().first).any(
        (item) => item.name == 'Alongamento',
      ),
      isTrue,
    );
    await repository.delete(id);
    expect((await repository.watchAll().first).length, 3);
  });

  test('Rejeita nome vazio e duplicado', () async {
    await expectLater(repository.create(' '), throwsA(isA<ArgumentError>()));
    await expectLater(repository.create('Push'), throwsA(isA<Exception>()));
  });
}
