import 'package:apex/app/app.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cadastra, edita e exclui categoria pela interface', (
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
    await tester.tap(find.byKey(const Key('openCategoriesButton')));
    await tester.pumpAndSettle();
    expect(find.text('Push'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addCategoryButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveCategoryButton')));
    await tester.pump();
    expect(find.text('Informe um nome.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('categoryNameField')), 'Push');
    await tester.tap(find.byKey(const Key('saveCategoryButton')));
    await tester.pumpAndSettle();
    expect(find.text('Já existe uma categoria com esse nome.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      'Mobilidade',
    );
    await tester.tap(find.byKey(const Key('saveCategoryButton')));
    await tester.pumpAndSettle();
    expect(find.text('Mobilidade'), findsOneWidget);

    await tester.tap(find.text('Mobilidade'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      'Alongamento',
    );
    await tester.tap(find.byKey(const Key('saveCategoryButton')));
    await tester.pumpAndSettle();
    expect(find.text('Alongamento'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir Alongamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Alongamento'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
