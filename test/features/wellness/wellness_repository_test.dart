import 'dart:io';

import 'package:apex/core/database/app_database.dart';
import 'package:apex/features/wellness/data/wellness_repository.dart';
import 'package:apex/features/wellness/domain/meal_type.dart';
import 'package:apex/features/wellness/domain/quantity_unit.dart';
import 'package:apex/features/wellness/domain/wellness_day.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WellnessRepository repository;
  var now = DateTime(2026, 10, 3, 22);

  setUp(() {
    now = DateTime(2026, 10, 3, 22);
    db = AppDatabase(NativeDatabase.memory());
    repository = WellnessRepository(db, now: () => now);
  });

  tearDown(() => db.close());

  Matcher rejects(String message) => throwsA(
    isA<WellnessValidationException>().having(
      (e) => e.message,
      'message',
      contains(message),
    ),
  );

  final oct3 = DateTime(2026, 10, 3);

  group('Sono', () {
    test('Noite atravessando a meia-noite conta para o dia em que se acorda '
        'e soma cochilos', () async {
      await repository.saveTimedSleep(
        bedTime: DateTime(2026, 10, 2, 23, 40),
        wakeTime: DateTime(2026, 10, 3, 6, 25),
        notes: '  acordei com calor  ',
      );
      await repository.saveSleepDuration(day: oct3, minutes: 30);

      final day = await repository.loadDay(oct3);
      expect(day.sleep.map((s) => s.durationMinutes), [30, 405]);
      expect(day.sleepMinutes, 435);
      expect(day.sleep.last.sleepDate, '2026-10-03');
      expect(day.sleep.last.notes, 'acordei com calor');
      expect((await repository.loadDay(DateTime(2026, 10, 2))).sleep, isEmpty);
    });

    test('Rejeita sobreposição, mas permite editar o próprio período', () async {
      final id = await repository.saveTimedSleep(
        bedTime: DateTime(2026, 10, 2, 23),
        wakeTime: DateTime(2026, 10, 3, 7),
      );
      await expectLater(
        repository.saveTimedSleep(
          bedTime: DateTime(2026, 10, 3, 6, 59),
          wakeTime: DateTime(2026, 10, 3, 8),
        ),
        rejects('sobrepõe'),
      );
      // Períodos encostados não se sobrepõem.
      await repository.saveTimedSleep(
        bedTime: DateTime(2026, 10, 3, 7),
        wakeTime: DateTime(2026, 10, 3, 7, 30),
      );
      await repository.saveTimedSleep(
        id: id,
        bedTime: DateTime(2026, 10, 2, 22),
        wakeTime: DateTime(2026, 10, 3, 6),
      );
      final day = await repository.loadDay(oct3);
      expect(day.sleepMinutes, 480 + 30);
    });

    test('Limita duração e soma diária a 24 horas', () async {
      await expectLater(
        repository.saveSleepDuration(day: oct3, minutes: 0),
        rejects('entre 1 minuto e 24 horas'),
      );
      await expectLater(
        repository.saveSleepDuration(day: oct3, minutes: 1441),
        rejects('entre 1 minuto e 24 horas'),
      );
      final id = await repository.saveSleepDuration(day: oct3, minutes: 1400);
      await expectLater(
        repository.saveSleepDuration(day: oct3, minutes: 41),
        rejects('ultrapassar 24 horas'),
      );
      await repository.saveSleepDuration(day: oct3, minutes: 40);
      // A edição desconsidera o valor anterior do próprio registro.
      await repository.saveSleepDuration(id: id, day: oct3, minutes: 1300);
      expect((await repository.loadDay(oct3)).sleepMinutes, 1340);
    });

    test('Rejeita horário invertido e sono no futuro', () async {
      await expectLater(
        repository.saveTimedSleep(
          bedTime: DateTime(2026, 10, 3, 7),
          wakeTime: DateTime(2026, 10, 3, 7),
        ),
        rejects('posterior ao de dormir'),
      );
      await expectLater(
        repository.saveTimedSleep(
          bedTime: DateTime(2026, 10, 3, 21),
          wakeTime: DateTime(2026, 10, 3, 22, 1),
        ),
        rejects('futuro'),
      );
      await expectLater(
        repository.saveSleepDuration(day: DateTime(2026, 10, 4), minutes: 60),
        rejects('dia futuro'),
      );
    });
  });

  group('Refeições', () {
    test('Aceita só o horário e separa os dias na meia-noite', () async {
      await repository.saveMeal(eatenAt: DateTime(2026, 10, 2, 23, 59));
      await repository.saveMeal(eatenAt: DateTime(2026, 10, 3, 0, 0));
      await repository.saveMeal(eatenAt: DateTime(2026, 10, 3, 12, 30, 45));

      final day = await repository.loadDay(oct3);
      expect(day.mealCount, 2);
      expect(day.meals.map((m) => m.meal.eatenAt), [
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 3, 12, 30),
      ]);
      expect(day.meals.first.meal.mealType, isNull);
      expect((await repository.loadDay(DateTime(2026, 10, 2))).mealCount, 1);
    });

    test('Edição substitui itens em ordem e preserva a criação', () async {
      final id = await repository.saveMeal(
        eatenAt: DateTime(2026, 10, 3, 12, 30),
        type: MealType.lunch,
        items: const [
          MealItemInput(
            name: 'Arroz',
            quantityValue: 150,
            quantityUnit: QuantityUnit.grams,
          ),
          MealItemInput(name: 'Salada'),
        ],
      );
      final created = (await repository.loadDay(oct3)).meals.single.meal;

      now = DateTime(2026, 10, 3, 23);
      await repository.saveMeal(
        id: id,
        eatenAt: DateTime(2026, 10, 3, 13),
        type: MealType.lunch,
        notes: ' comi com pressa ',
        items: const [
          MealItemInput(name: 'Salada'),
          MealItemInput(
            name: ' Frango ',
            quantityValue: 1.5,
            quantityUnit: QuantityUnit.units,
          ),
        ],
      );

      final entry = (await repository.loadDay(oct3)).meals.single;
      expect(entry.meal.notes, 'comi com pressa');
      expect(entry.meal.createdAt, created.createdAt);
      expect(entry.meal.updatedAt, DateTime(2026, 10, 3, 23));
      expect(entry.items.map((i) => (i.position, i.name, i.quantityValue)), [
        (1, 'Salada', null),
        (2, 'Frango', 1.5),
      ]);
      expect(await db.select(db.mealItems).get(), hasLength(2));
    });

    test('Valida itens e refeição no futuro', () async {
      final at = DateTime(2026, 10, 3, 12);
      await expectLater(
        repository.saveMeal(
          eatenAt: at,
          items: const [MealItemInput(name: '   ')],
        ),
        rejects('nome'),
      );
      await expectLater(
        repository.saveMeal(
          eatenAt: at,
          items: const [MealItemInput(name: 'Pão', quantityValue: 2)],
        ),
        rejects('juntas'),
      );
      for (final value in [0.0, -1.0, double.nan, double.infinity]) {
        await expectLater(
          repository.saveMeal(
            eatenAt: at,
            items: [
              MealItemInput(
                name: 'Pão',
                quantityValue: value,
                quantityUnit: QuantityUnit.units,
              ),
            ],
          ),
          rejects('maior que zero'),
        );
      }
      await expectLater(
        repository.saveMeal(eatenAt: DateTime(2026, 10, 3, 22, 1)),
        rejects('futuro'),
      );
      expect(await db.select(db.meals).get(), isEmpty);
    });

    test('Excluir refeição remove seus itens e preserva as demais', () async {
      final id = await repository.saveMeal(
        eatenAt: DateTime(2026, 10, 3, 8),
        items: const [MealItemInput(name: 'Ovos')],
      );
      final kept = await repository.saveMeal(
        eatenAt: DateTime(2026, 10, 3, 9),
        items: const [MealItemInput(name: 'Café')],
      );
      await repository.deleteMeal(id);
      expect((await db.select(db.meals).get()).map((m) => m.id), [kept]);
      expect((await db.select(db.mealItems).get()).map((i) => i.name), [
        'Café',
      ]);
      await expectLater(repository.deleteMeal(id), throwsStateError);
    });
  });

  group('Água', () {
    test('Soma o dia e valida o volume', () async {
      await repository.saveWater(
        consumedAt: DateTime(2026, 10, 3, 8),
        amountMl: 1,
      );
      final id = await repository.saveWater(
        consumedAt: DateTime(2026, 10, 3, 10),
        amountMl: 250,
      );
      await repository.saveWater(id: id, consumedAt: DateTime(2026, 10, 3, 10), amountMl: 5000);
      expect((await repository.loadDay(oct3)).waterMl, 5001);
      for (final amount in [0, 5001]) {
        await expectLater(
          repository.saveWater(consumedAt: DateTime(2026, 10, 3), amountMl: amount),
          rejects('entre 1 e 5000'),
        );
      }
      await repository.deleteWater(id);
      expect((await repository.loadDay(oct3)).waterMl, 1);
    });
  });

  test('Histórico agrega por dia e distingue ausência de zero', () async {
    await repository.saveSleepDuration(day: oct3, minutes: 420);
    await repository.saveWater(
      consumedAt: DateTime(2026, 10, 3, 9),
      amountMl: 500,
    );
    await repository.saveWater(
      consumedAt: DateTime(2026, 10, 3, 15),
      amountMl: 250,
    );
    await repository.saveMeal(eatenAt: DateTime(2026, 10, 1, 23, 59));
    await repository.saveMeal(eatenAt: DateTime(2026, 10, 1, 12));

    final history = await repository.loadHistory();
    expect(
      history.map((d) => (d.date, d.sleepMinutes, d.mealCount, d.waterMl)),
      [(oct3, 420, 0, 750), (DateTime(2026, 10, 1), null, 2, null)],
    );
  });

  test('Restrições do banco rejeitam dados inválidos diretos', () async {
    const stamp = 1790000000;
    for (final sql in [
      "INSERT INTO sleep_logs (sleep_date, duration_minutes, created_at, updated_at) VALUES ('2026-02-30', 60, $stamp, $stamp)",
      "INSERT INTO sleep_logs (sleep_date, duration_minutes, created_at, updated_at) VALUES ('ontem', 60, $stamp, $stamp)",
      "INSERT INTO sleep_logs (sleep_date, duration_minutes, created_at, updated_at) VALUES ('2026-10-03', 1441, $stamp, $stamp)",
      "INSERT INTO sleep_logs (sleep_date, bed_time, duration_minutes, created_at, updated_at) VALUES ('2026-10-03', $stamp, 60, $stamp, $stamp)",
      "INSERT INTO sleep_logs (sleep_date, bed_time, wake_time, duration_minutes, created_at, updated_at) VALUES ('2026-10-03', $stamp, $stamp, 60, $stamp, $stamp)",
      "INSERT INTO meals (eaten_at, meal_type, created_at, updated_at) VALUES ($stamp, 'brunch', $stamp, $stamp)",
      'INSERT INTO water_intakes (consumed_at, amount_ml, created_at, updated_at) VALUES ($stamp, 0, $stamp, $stamp)',
    ]) {
      await expectLater(db.customStatement(sql), throwsA(anything), reason: sql);
    }

    await db.customStatement(
      'INSERT INTO meals (id, eaten_at, created_at, updated_at) VALUES (1, $stamp, $stamp, $stamp)',
    );
    for (final sql in [
      "INSERT INTO meal_items (meal_id, position, name, quantity_value) VALUES (1, 1, 'Pão', 2)",
      "INSERT INTO meal_items (meal_id, position, name, quantity_unit) VALUES (1, 1, 'Pão', 'g')",
      "INSERT INTO meal_items (meal_id, position, name, quantity_value, quantity_unit) VALUES (1, 1, 'Pão', 2, 'kg')",
      "INSERT INTO meal_items (meal_id, position, name) VALUES (1, 0, 'Pão')",
      "INSERT INTO meal_items (meal_id, position, name) VALUES (1, 1, '  ')",
      "INSERT INTO meal_items (meal_id, position, name) VALUES (99, 1, 'Pão')",
    ]) {
      await expectLater(db.customStatement(sql), throwsA(anything), reason: sql);
    }
    await db.customStatement(
      "INSERT INTO meal_items (meal_id, position, name) VALUES (1, 1, 'Pão')",
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO meal_items (meal_id, position, name) VALUES (1, 1, 'Café')",
      ),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement('DELETE FROM meals WHERE id = 1'),
      throwsA(anything),
    );
  });

  test('Migra banco v4 para v5 preservando treinos e persiste registros', () async {
    final directory = await Directory.systemTemp.createTemp('apex_wellness_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/apex.sqlite');

    // Fixture v4: esquema atual sem as tabelas de bem-estar.
    final v4 = AppDatabase(NativeDatabase(file));
    await v4.initialize();
    await v4.into(v4.workouts).insert(
      WorkoutsCompanion.insert(performedAt: DateTime(2026, 9, 1, 18)),
    );
    await v4.customStatement('''
DROP TABLE meal_items; DROP TABLE meals; DROP TABLE sleep_logs;
DROP TABLE water_intakes; PRAGMA user_version = 4;
''');
    await v4.close();

    final migrated = AppDatabase(NativeDatabase(file));
    await migrated.initialize();
    expect(
      (await migrated.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      5,
    );
    expect(await migrated.select(migrated.workouts).get(), hasLength(1));
    final indexes = await migrated
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name IN ('sleep_logs_sleep_date', 'meals_eaten_at', "
          "'water_intakes_consumed_at')",
        )
        .get();
    expect(indexes, hasLength(3));
    final migratedRepository = WellnessRepository(migrated, now: () => now);
    await migratedRepository.saveSleepDuration(day: oct3, minutes: 450);
    await migratedRepository.saveMeal(
      eatenAt: DateTime(2026, 10, 3, 7),
      items: const [MealItemInput(name: 'Pão')],
    );
    await migratedRepository.saveWater(
      consumedAt: DateTime(2026, 10, 3, 7),
      amountMl: 300,
    );
    await migrated.close();

    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);
    final day = await WellnessRepository(reopened).loadDay(oct3);
    expect(
      (day.sleepMinutes, day.mealCount, day.meals.single.items.single.name, day.waterMl),
      (450, 1, 'Pão', 300),
    );
  });
}
