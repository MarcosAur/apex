import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../home/providers/clock_provider.dart';
import '../domain/meal_type.dart';
import '../domain/wellness_day.dart';

class WellnessRepository {
  WellnessRepository(this.db, {this._now = DateTime.now});

  final AppDatabase db;
  final CurrentTime _now;
  Future<void> _pending = Future.value();

  static const maxSleepMinutesPerDay = 1440;
  static const maxWaterMl = 5000;

  // Serializa as gravações, como em WorkoutRepository.
  Future<T> _write<T>(Future<T> Function() action) {
    final result = _pending.then((_) => db.transaction(action));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static DateTime _minute(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute);

  static String? _text(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _rejectFuture(DateTime time, String message) {
    if (time.isAfter(_now())) throw WellnessValidationException(message);
  }

  static void _requireChanged(int changed) {
    if (changed != 1) throw StateError('Registro não encontrado.');
  }

  // Sono ---------------------------------------------------------------------

  /// Período com horários; pertence ao dia em que se acorda.
  Future<int> saveTimedSleep({
    int? id,
    required DateTime bedTime,
    required DateTime wakeTime,
    String? notes,
  }) {
    final bed = _minute(bedTime);
    final wake = _minute(wakeTime);
    if (!wake.isAfter(bed)) {
      return Future.error(
        const WellnessValidationException(
          'O horário de acordar deve ser posterior ao de dormir.',
        ),
      );
    }
    return _saveSleep(
      id: id,
      date: dateKey(wake),
      bed: bed,
      wake: wake,
      minutes: wake.difference(bed).inMinutes,
      notes: notes,
    );
  }

  /// Período sem horários, apenas com a duração.
  Future<int> saveSleepDuration({
    int? id,
    required DateTime day,
    required int minutes,
    String? notes,
  }) => _saveSleep(
    id: id,
    date: dateKey(day),
    bed: null,
    wake: null,
    minutes: minutes,
    notes: notes,
  );

  Future<int> _saveSleep({
    required int? id,
    required String date,
    required DateTime? bed,
    required DateTime? wake,
    required int minutes,
    required String? notes,
  }) => _write(() async {
    if (minutes < 1 || minutes > maxSleepMinutesPerDay) {
      throw const WellnessValidationException(
        'A duração do sono deve ficar entre 1 minuto e 24 horas.',
      );
    }
    if (wake != null) {
      _rejectFuture(wake, 'O sono não pode terminar no futuro.');
    } else if (date.compareTo(dateKey(_now())) > 0) {
      throw const WellnessValidationException(
        'Não é possível registrar sono em um dia futuro.',
      );
    }

    if (bed != null && wake != null) {
      final overlap =
          await (db.select(db.sleepLogs)
                ..where(
                  (s) =>
                      s.bedTime.isSmallerThanValue(wake) &
                      s.wakeTime.isBiggerThanValue(bed) &
                      (id == null ? const Constant(true) : s.id.equals(id).not()),
                )
                ..limit(1))
              .getSingleOrNull();
      if (overlap != null) {
        throw const WellnessValidationException(
          'Este período se sobrepõe a outro sono registrado.',
        );
      }
    }

    final sameDay = await (db.select(
      db.sleepLogs,
    )..where((s) => s.sleepDate.equals(date))).get();
    final otherMinutes = sameDay
        .where((log) => log.id != id)
        .fold(0, (sum, log) => sum + log.durationMinutes);
    if (otherMinutes + minutes > maxSleepMinutesPerDay) {
      throw const WellnessValidationException(
        'O sono do dia não pode ultrapassar 24 horas.',
      );
    }

    final now = _now();
    final values = SleepLogsCompanion(
      sleepDate: Value(date),
      bedTime: Value(bed),
      wakeTime: Value(wake),
      durationMinutes: Value(minutes),
      notes: Value(_text(notes)),
      updatedAt: Value(now),
    );
    if (id == null) {
      return db
          .into(db.sleepLogs)
          .insert(values.copyWith(createdAt: Value(now)));
    }
    _requireChanged(
      await (db.update(
        db.sleepLogs,
      )..where((s) => s.id.equals(id))).write(values),
    );
    return id;
  });

  Future<void> deleteSleep(int id) => _write(() async {
    _requireChanged(
      await (db.delete(db.sleepLogs)..where((s) => s.id.equals(id))).go(),
    );
  });

  // Refeições ----------------------------------------------------------------

  Future<int> saveMeal({
    int? id,
    required DateTime eatenAt,
    MealType? type,
    String? notes,
    List<MealItemInput> items = const [],
  }) => _write(() async {
    final time = _minute(eatenAt);
    _rejectFuture(time, 'A refeição não pode estar no futuro.');
    final rows = <({String name, double? value, MealItemInput input})>[];
    for (final item in items) {
      final name = _text(item.name);
      if (name == null) {
        throw const WellnessValidationException('Informe o nome de cada item.');
      }
      final value = item.quantityValue;
      if ((value == null) != (item.quantityUnit == null)) {
        throw const WellnessValidationException(
          'Informe quantidade e unidade juntas.',
        );
      }
      if (value != null && (!value.isFinite || value <= 0)) {
        throw const WellnessValidationException(
          'A quantidade deve ser maior que zero.',
        );
      }
      rows.add((name: name, value: value, input: item));
    }

    final now = _now();
    final values = MealsCompanion(
      eatenAt: Value(time),
      mealType: Value(type),
      notes: Value(_text(notes)),
      updatedAt: Value(now),
    );
    final int mealId;
    if (id == null) {
      mealId = await db
          .into(db.meals)
          .insert(values.copyWith(createdAt: Value(now)));
    } else {
      _requireChanged(
        await (db.update(
          db.meals,
        )..where((m) => m.id.equals(id))).write(values),
      );
      await (db.delete(db.mealItems)..where((i) => i.mealId.equals(id))).go();
      mealId = id;
    }
    for (final (index, row) in rows.indexed) {
      await db
          .into(db.mealItems)
          .insert(
            MealItemsCompanion.insert(
              mealId: mealId,
              position: index + 1,
              name: row.name,
              quantityValue: Value(row.value),
              quantityUnit: Value(row.input.quantityUnit),
            ),
          );
    }
    return mealId;
  });

  /// Remove a refeição e seus itens na mesma transação.
  Future<void> deleteMeal(int id) => _write(() async {
    await (db.delete(db.mealItems)..where((i) => i.mealId.equals(id))).go();
    _requireChanged(
      await (db.delete(db.meals)..where((m) => m.id.equals(id))).go(),
    );
  });

  // Água ---------------------------------------------------------------------

  Future<int> saveWater({
    int? id,
    required DateTime consumedAt,
    required int amountMl,
  }) => _write(() async {
    if (amountMl < 1 || amountMl > maxWaterMl) {
      throw const WellnessValidationException(
        'Informe um volume entre 1 e 5000 ml.',
      );
    }
    final time = _minute(consumedAt);
    _rejectFuture(time, 'A ingestão de água não pode estar no futuro.');
    final now = _now();
    final values = WaterIntakesCompanion(
      consumedAt: Value(time),
      amountMl: Value(amountMl),
      updatedAt: Value(now),
    );
    if (id == null) {
      return db
          .into(db.waterIntakes)
          .insert(values.copyWith(createdAt: Value(now)));
    }
    _requireChanged(
      await (db.update(
        db.waterIntakes,
      )..where((w) => w.id.equals(id))).write(values),
    );
    return id;
  });

  Future<void> deleteWater(int id) => _write(() async {
    _requireChanged(
      await (db.delete(db.waterIntakes)..where((w) => w.id.equals(id))).go(),
    );
  });

  // Consultas ----------------------------------------------------------------

  Stream<WellnessDay> watchDay(DateTime day) => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.sleepLogs, db.meals, db.mealItems, db.waterIntakes},
      )
      .watch()
      .asyncMap((_) => loadDay(day));

  Future<WellnessDay> loadDay(DateTime day) => db.transaction(() async {
    final start = calendarDay(day);
    final end = DateTime(start.year, start.month, start.day + 1);
    final sleep =
        await (db.select(db.sleepLogs)
              ..where((s) => s.sleepDate.equals(dateKey(start)))
              ..orderBy([
                (s) => OrderingTerm.asc(s.bedTime),
                (s) => OrderingTerm.asc(s.id),
              ]))
            .get();
    final meals =
        await (db.select(db.meals)
              ..where(
                (m) =>
                    m.eatenAt.isBiggerOrEqualValue(start) &
                    m.eatenAt.isSmallerThanValue(end),
              )
              ..orderBy([
                (m) => OrderingTerm.asc(m.eatenAt),
                (m) => OrderingTerm.asc(m.id),
              ]))
            .get();
    final items = meals.isEmpty
        ? const <MealItem>[]
        : await (db.select(db.mealItems)
                ..where((i) => i.mealId.isIn(meals.map((m) => m.id)))
                ..orderBy([(i) => OrderingTerm.asc(i.position)]))
              .get();
    final water =
        await (db.select(db.waterIntakes)
              ..where(
                (w) =>
                    w.consumedAt.isBiggerOrEqualValue(start) &
                    w.consumedAt.isSmallerThanValue(end),
              )
              ..orderBy([
                (w) => OrderingTerm.asc(w.consumedAt),
                (w) => OrderingTerm.asc(w.id),
              ]))
            .get();
    return WellnessDay(
      date: start,
      sleep: sleep,
      meals: [
        for (final meal in meals)
          MealEntry(meal, [
            for (final item in items)
              if (item.mealId == meal.id) item,
          ]),
      ],
      water: water,
    );
  });

  /// Dias com algum registro, do mais recente ao mais antigo.
  Stream<List<WellnessDaySummary>> watchHistory() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.sleepLogs, db.meals, db.waterIntakes},
      )
      .watch()
      .asyncMap((_) => loadHistory());

  // O agrupamento por dia local fica em Dart: SQLite no navegador não
  // garante o mesmo fuso do dispositivo.
  Future<List<WellnessDaySummary>> loadHistory() => db.transaction(() async {
    final sleep = <String, int>{};
    final meals = <String, int>{};
    final water = <String, int>{};

    final sleepRows = await (db.selectOnly(
      db.sleepLogs,
    )..addColumns([db.sleepLogs.sleepDate, db.sleepLogs.durationMinutes])).get();
    for (final row in sleepRows) {
      final key = row.read(db.sleepLogs.sleepDate)!;
      sleep[key] = (sleep[key] ?? 0) + row.read(db.sleepLogs.durationMinutes)!;
    }
    final mealRows = await (db.selectOnly(
      db.meals,
    )..addColumns([db.meals.eatenAt])).get();
    for (final row in mealRows) {
      final key = dateKey(row.read(db.meals.eatenAt)!);
      meals[key] = (meals[key] ?? 0) + 1;
    }
    final waterRows = await (db.selectOnly(db.waterIntakes)
          ..addColumns([db.waterIntakes.consumedAt, db.waterIntakes.amountMl]))
        .get();
    for (final row in waterRows) {
      final key = dateKey(row.read(db.waterIntakes.consumedAt)!);
      water[key] = (water[key] ?? 0) + row.read(db.waterIntakes.amountMl)!;
    }

    final keys = {...sleep.keys, ...meals.keys, ...water.keys}.toList()
      ..sort((a, b) => b.compareTo(a));
    return [
      for (final key in keys)
        WellnessDaySummary(
          date: parseDateKey(key),
          sleepMinutes: sleep[key],
          mealCount: meals[key] ?? 0,
          waterMl: water[key],
        ),
    ];
  });
}
