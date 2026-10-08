import 'package:apex/app/app.dart';
import 'package:apex/core/database/app_database.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:apex/features/exercises/domain/measurement_unit.dart';
import 'package:apex/features/workouts/data/workout_repository.dart';
import 'package:apex/features/workouts/presentation/active_workout_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workout_repository_test.dart' show exerciseFixture;

void main() {
  testWidgets('Formulário de séries cabe em tela estreita com teclado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final db = AppDatabase(NativeDatabase.memory());
    final id = await tester.runAsync(() async {
      final exercise = await exerciseFixture(db);
      final repo = WorkoutRepository(db);
      final id = await repo.start();
      final item = await repo.addExercise(id, exercise);
      await repo.beginDraft(item);
      return id;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ActiveWorkoutScreen(workoutId: id!)),
      ),
    );
    await tester.pumpAndSettle();
    final saveStatus = find.byKey(const Key('saveStatus'));
    final gymField = find.byKey(const ValueKey('gym-null'));
    expect(
      tester.getTopLeft(gymField).dy - tester.getBottomLeft(saveStatus).dy,
      greaterThanOrEqualTo(20),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('measurement-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('measurement-1')), '10');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('effort-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(db.close);
  });
  testWidgets(
    'Seleciona exercício, retoma rascunho e encerra com consulta somente leitura',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() => exerciseFixture(db));

      Future<void> openApp() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const ApexApp(),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> closeApp() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      }

      await openApp();
      await tap(find.byKey(const Key('startWorkoutButton')));
      expect(find.text('Treino em andamento'), findsOneWidget);
      await tap(find.byKey(const Key('addWorkoutExercise')));
      await tap(find.text('Supino'));
      await tap(find.text('Adicionar série'));
      await tester.enterText(
        find.byKey(const ValueKey('measurement-1')),
        '42,',
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('reps-1')), '8');
      await tester.pumpAndSettle();
      await tap(find.byKey(const ValueKey('effort-1')));
      await tap(find.text('Alto').last);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('finishWorkout')))
            .onPressed,
        isNull,
      );

      await closeApp();
      await openApp();
      expect(find.text('Continuar treino'), findsOneWidget);
      await tap(find.byKey(const Key('startWorkoutButton')));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('measurement-1')))
            .controller!
            .text,
        '42,',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('reps-1')))
            .controller!
            .text,
        '8',
      );
      await tester.enterText(
        find.byKey(const ValueKey('measurement-1')),
        '42,5',
      );
      await tester.pumpAndSettle();
      await tap(find.text('Salvar série'));
      expect(find.text('Série 1 • 42.5 kg • 8 repetições'), findsOneWidget);
      await tap(find.text('Adicionar série'));
      await tap(find.text('Salvar série'));
      expect(
        find.textContaining('Informe os valores obrigatórios corretamente.'),
        findsOneWidget,
      );
      await tap(find.text('Descartar rascunho'));
      await tap(find.text('Confirmar'));
      await tap(find.byKey(const Key('finishWorkout')));
      await tap(find.text('Cancelar'));
      expect(find.text('Treino em andamento'), findsOneWidget);
      await tap(find.byKey(const Key('finishWorkout')));
      await tap(find.text('Confirmar'));
      expect(find.text('Treino encerrado'), findsOneWidget);
      expect(find.text('Salvar série'), findsNothing);
      expect(find.text('Adicionar exercício'), findsNothing);
      expect(find.text('Alto'), findsOneWidget);
      await closeApp();
      await openApp();
      expect(find.text('Iniciar Exercício'), findsOneWidget);
      await tap(find.byKey(const Key('openHistoryButton')));
      await tap(find.text('Treino #1'));
      expect(find.text('Treino encerrado'), findsOneWidget);
      expect(find.text('Série 1 • 42.5 kg • 8 repetições'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tap(find.byKey(const ValueKey('deleteWorkout-1')));
      await tap(find.text('Cancelar'));
      expect(find.text('Treino #1'), findsOneWidget);
      await tap(find.byKey(const ValueKey('deleteWorkout-1')));
      await tap(find.byKey(const Key('confirmDeleteWorkout')));
      expect(find.text('Nenhum treino registrado.'), findsOneWidget);
      expect(find.text('Treino excluído.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Iniciar Exercício'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeApp();
      await tester.runAsync(db.close);
    },
  );

  testWidgets('Distância oculta repetições e persiste reps igual a um', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final values = await tester.runAsync(() async {
      final exercise = await exerciseFixture(
        db,
        measurementUnit: MeasurementUnit.kilometers,
        name: 'Corrida',
      );
      final repository = WorkoutRepository(db);
      final workout = await repository.start();
      final item = await repository.addExercise(workout, exercise);
      await repository.beginDraft(item);
      return (workout: workout, item: item);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: ActiveWorkoutScreen(workoutId: values!.workout),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Distância (km)'), findsOneWidget);
    expect(find.byKey(ValueKey('reps-${values.item}')), findsNothing);
    await tester.enterText(
      find.byKey(ValueKey('measurement-${values.item}')),
      '2,5',
    );
    await tester.pumpAndSettle();
    final effortField = find.byKey(ValueKey('effort-${values.item}'));
    await tester.scrollUntilVisible(
      effortField,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(effortField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Médio').last);
    await tester.pumpAndSettle();
    final saveButton = find.text('Salvar distância');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Registro 1 • 2.5 km'), findsOneWidget);
    final log = (await WorkoutRepository(db).loadSession(values.workout))
        .logs
        .single;
    expect(log.reps, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(db.close);
  });
}
