import 'package:apex/app/app.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Executa cadastro, validação, edição e exclusão pela interface', (
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

    await tester.tap(find.byKey(const Key('openGymsButton')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Nenhuma academia cadastrada.\n'
        'Use o botão + para adicionar a primeira.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('addGymButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveGymButton')));
    await tester.pump();
    expect(find.text('Informe o nome da academia.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('gymNameField')),
      'Academia Central',
    );
    await tester.enterText(find.byKey(const Key('gymLocationField')), 'Centro');
    await tester.tap(find.byKey(const Key('saveGymButton')));
    await tester.pumpAndSettle();
    expect(find.text('Academia Central'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.text('Editar academia'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('gymNameField')),
      'Academia Norte',
    );
    await tester.enterText(find.byKey(const Key('gymLocationField')), '');
    await tester.tap(find.byKey(const Key('saveGymButton')));
    await tester.pumpAndSettle();
    expect(find.text('Academia Norte'), findsOneWidget);
    expect(find.text('Centro'), findsNothing);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Excluir academia?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Academia Norte'), findsNothing);
    expect(find.textContaining('Nenhuma academia cadastrada.'), findsOneWidget);

    // Desmonta o ProviderScope e processa a limpeza assíncrona do stream Drift.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
