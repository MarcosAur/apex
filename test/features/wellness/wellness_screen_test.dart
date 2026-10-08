import 'package:apex/app/app.dart';
import 'package:apex/core/database/database_provider.dart';
import 'package:apex/features/home/providers/clock_provider.dart';
import 'package:apex/features/wellness/domain/meal_type.dart';
import 'package:apex/features/wellness/domain/quantity_unit.dart';
import 'package:apex/features/wellness/domain/wellness_day.dart';
import 'package:apex/features/wellness/presentation/wellness_screen.dart';
import 'package:apex/features/wellness/providers/wellness_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testNow = DateTime(2026, 10, 3, 20);

  Future<void> tearDownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Widget createSubject({Widget? child}) {
    return ProviderScope(
      overrides: [
        databaseConnectionProvider.overrideWithValue(NativeDatabase.memory()),
        clockProvider.overrideWithValue(() => testNow),
      ],
      child: MaterialApp(home: child ?? const WellnessScreen()),
    );
  }

  testWidgets('Abre Bem-estar pelo drawer da Home e exibe seções', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseConnectionProvider.overrideWithValue(NativeDatabase.memory()),
          clockProvider.overrideWithValue(() => testNow),
        ],
        child: const ApexApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Abre drawer
    await tester.tap(find.byKey(const Key('openNavigationDrawerButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wellnessDrawerDestination')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wellnessDrawerDestination')));
    await tester.pumpAndSettle();

    expect(find.text('Bem-estar'), findsOneWidget);
    expect(find.text('Sono'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Água'), findsOneWidget);
    expect(find.text('Hoje · 03/10/2026'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('nextDayButton')))
          .onPressed,
      isNull,
    );

    await tearDownTree(tester);
  });

  testWidgets('Navega entre dias e volta para hoje', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Hoje · 03/10/2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('previousDayButton')));
    await tester.pumpAndSettle();

    expect(find.text('02/10/2026'), findsOneWidget);
    expect(find.byKey(const Key('todayButton')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('nextDayButton')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('todayButton')));
    await tester.pumpAndSettle();

    expect(find.text('Hoje · 03/10/2026'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('Registra sono por duração e depois por horários', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // 1. Duração
    await tester.tap(find.byKey(const Key('addSleepButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sleepModeDuration')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('sleepHoursField')), '7');
    await tester.enterText(find.byKey(const Key('sleepMinutesField')), '30');
    await tester.enterText(
      find.byKey(const Key('sleepNotesField')),
      'dormi direto',
    );
    await tester.tap(find.byKey(const Key('saveSleepButton')));
    await tester.pumpAndSettle();

    expect(find.text('7 h 30 min'), findsWidgets);
    expect(find.text('dormi direto'), findsOneWidget);

    // 2. Horários (cochilo)
    await tester.tap(find.byKey(const Key('addSleepButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sleepModeDuration')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sleepHoursField')), '0');
    await tester.enterText(find.byKey(const Key('sleepMinutesField')), '45');
    await tester.tap(find.byKey(const Key('saveSleepButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sleepTotalText')), findsOneWidget);
    expect(find.text('8 h 15 min'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('Registra refeição apenas com horário e outra com itens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Refeição 1: somente horário
    await tester.tap(find.byKey(const Key('addMealButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveMealButton')));
    await tester.pumpAndSettle();

    expect(find.text('1 refeição'), findsOneWidget);

    // Refeição 2: com tipo, notas e item
    await tester.tap(find.byKey(const Key('addMealButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mealTypeField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Almoço').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('mealNotesField')),
      'comi rápido',
    );

    await tester.tap(find.byKey(const Key('addMealItemButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('mealItemNameField_0')),
      'Arroz',
    );
    await tester.enterText(
      find.byKey(const Key('mealItemQuantityField_0')),
      '150',
    );

    await tester.tap(find.byKey(const Key('saveMealButton')));
    await tester.pumpAndSettle();

    expect(find.text('2 refeições'), findsOneWidget);
    expect(find.textContaining('Almoço'), findsOneWidget);
    expect(find.textContaining('Arroz (150 g)'), findsOneWidget);
    expect(find.text('comi rápido'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('Registra água por atalho rápido e por folha personalizada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Botão rápido +250
    await tester.tap(find.byKey(const Key('quickAddWater250Button')));
    await tester.pumpAndSettle();

    expect(find.text('+250 ml registrado.'), findsOneWidget);
    expect(find.text('250 ml'), findsWidgets);

    // Botão rápido +500
    await tester.tap(find.byKey(const Key('quickAddWater500Button')));
    await tester.pumpAndSettle();

    expect(find.text('750 ml'), findsWidgets);

    // Folha personalizada
    await tester.tap(find.byKey(const Key('addWaterButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('waterAmountField')), '300');
    await tester.tap(find.byKey(const Key('saveWaterButton')));
    await tester.pumpAndSettle();

    expect(find.text('1.050 ml'), findsWidgets);

    await tearDownTree(tester);
  });

  testWidgets('Exclui item com confirmação', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quickAddWater250Button')));
    await tester.pumpAndSettle();

    expect(find.text('250 ml'), findsWidgets);

    // Clica na lixeira da água
    final deleteButtons = find.byTooltip('Excluir');
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Excluir registro de água?'), findsOneWidget);

    // Cancela primeiro
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsWidgets);

    // Repete e confirma
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmWellnessDeletion')));
    await tester.pumpAndSettle();

    expect(find.text('0 ml'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('Abre histórico e navega para a data selecionada', (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseConnectionProvider.overrideWithValue(NativeDatabase.memory()),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    addTearDown(container.dispose);

    // Popula dados em um dia anterior
    final repo = container.read(wellnessRepositoryProvider);
    await repo.saveSleepDuration(day: DateTime(2026, 10, 1), minutes: 420);
    await repo.saveMeal(
      eatenAt: DateTime(2026, 10, 1, 12),
      type: MealType.lunch,
      items: const [
        MealItemInput(
          name: 'Frango',
          quantityValue: 200,
          quantityUnit: QuantityUnit.grams,
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WellnessScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openWellnessHistoryButton')));
    await tester.pumpAndSettle();

    expect(find.text('Histórico de bem-estar'), findsOneWidget);
    expect(
      find.byKey(const Key('wellnessHistoryItem_2026-10-01')),
      findsOneWidget,
    );
    expect(find.textContaining('Sono: 7 h'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wellnessHistoryItem_2026-10-01')));
    await tester.pumpAndSettle();

    // Voltou para a tela principal no dia 01/10/2026
    expect(find.text('01/10/2026'), findsOneWidget);
    expect(find.text('7 h'), findsWidgets);
    expect(find.text('1 refeição'), findsOneWidget);

    await tearDownTree(tester);
  });

  testWidgets('Não apresenta overflow em tela estreita de 320x640', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('addSleepButton')), findsOneWidget);
    expect(find.byKey(const Key('addMealButton')), findsOneWidget);
    expect(find.byKey(const Key('addWaterButton')), findsOneWidget);

    await tearDownTree(tester);
  });
}
