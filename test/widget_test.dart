import 'package:apex/app/app.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Inicialização exibe a tela provisória do Apex Workout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseConnectionProvider.overrideWithValue(NativeDatabase.memory()),
        ],
        child: const ApexApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APEX WORKOUT'), findsOneWidget);
    expect(find.text('Iniciar Exercício'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
