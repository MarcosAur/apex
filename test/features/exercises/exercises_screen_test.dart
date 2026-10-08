import 'package:apex/app/app.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Executa o CRUD com seletores relacionais', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseConnectionProvider.overrideWithValue(NativeDatabase.memory()),
        ],
        child: const ApexApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('openExercisesButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openExercisesButton')));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum exercício cadastrado.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addExerciseButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveExerciseButton')));
    await tester.pump();
    expect(find.text('Informe o nome do exercício.'), findsOneWidget);
    expect(find.text('Selecione uma categoria.'), findsOneWidget);
    expect(find.text('Selecione um grupo muscular.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('exerciseNameField')),
      'Supino reto',
    );
    await tester.tap(find.byKey(const Key('exerciseCategoryField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exerciseMuscleGroupField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Peitoral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveExerciseButton')));
    await tester.pumpAndSettle();
    expect(find.text('Supino reto'), findsOneWidget);
    expect(find.text('Push • Peitoral • kg'), findsOneWidget);

    await tester.tap(find.text('Supino reto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exerciseNameField')),
      'Supino inclinado',
    );
    await tester.tap(find.byKey(const Key('exerciseMeasurementUnitField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quilômetros (km)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveExerciseButton')));
    await tester.pumpAndSettle();
    expect(find.text('Supino inclinado'), findsOneWidget);
    expect(find.text('Push • Peitoral • km'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir Supino inclinado'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Supino inclinado'), findsNothing);
    expect(find.text('Nenhum exercício cadastrado.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
