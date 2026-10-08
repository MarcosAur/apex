import 'package:apex/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Inicializa uma única instância e a fecha com o container', () async {
    final container = ProviderContainer(
      overrides: [
        databaseConnectionProvider.overrideWithValue(NativeDatabase.memory()),
      ],
    );

    final database = container.read(databaseProvider);
    expect(identical(database, container.read(databaseProvider)), isTrue);
    await container.read(databaseInitializationProvider.future);
    expect(await database.select(database.categories).get(), isNotEmpty);

    container.dispose();
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
  });
}
