import 'package:apex/app/app.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cadastra, edita e exclui grupo muscular pela interface', (
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
    await tester.ensureVisible(find.byKey(const Key('openMuscleGroupsButton')));
    await tester.tap(find.byKey(const Key('openMuscleGroupsButton')));
    await tester.pumpAndSettle();
    expect(find.text('Core'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addMuscleGroupButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('muscleGroupNameField')),
      'Antebraços',
    );
    await tester.tap(find.byKey(const Key('saveMuscleGroupButton')));
    await tester.pumpAndSettle();
    expect(find.text('Antebraços'), findsOneWidget);

    await tester.tap(find.text('Antebraços'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('muscleGroupNameField')),
      'Antebraço',
    );
    await tester.tap(find.byKey(const Key('saveMuscleGroupButton')));
    await tester.pumpAndSettle();
    expect(find.text('Antebraço'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir Antebraço'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Antebraço'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
