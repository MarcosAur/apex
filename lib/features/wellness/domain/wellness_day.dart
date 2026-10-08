import '../../../core/database/app_database.dart';
import 'quantity_unit.dart';

/// Meia-noite local do dia civil de [time].
DateTime calendarDay(DateTime time) =>
    DateTime(time.year, time.month, time.day);

/// Chave `YYYY-MM-DD` do dia civil local de [time].
String dateKey(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-'
    '${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Regra de negócio violada; [message] é apresentável ao usuário.
class WellnessValidationException implements Exception {
  const WellnessValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MealItemInput {
  const MealItemInput({
    required this.name,
    this.quantityValue,
    this.quantityUnit,
  });

  final String name;
  final double? quantityValue;
  final QuantityUnit? quantityUnit;
}

class MealEntry {
  const MealEntry(this.meal, this.items);
  final Meal meal;
  final List<MealItem> items;
}

class WellnessDay {
  const WellnessDay({
    required this.date,
    required this.sleep,
    required this.meals,
    required this.water,
  });

  final DateTime date;
  final List<SleepLog> sleep;
  final List<MealEntry> meals;
  final List<WaterIntake> water;

  int get sleepMinutes => sleep.fold(0, (sum, log) => sum + log.durationMinutes);
  int get mealCount => meals.length;
  int get waterMl => water.fold(0, (sum, intake) => sum + intake.amountMl);
}

class WellnessDaySummary {
  const WellnessDaySummary({
    required this.date,
    required this.sleepMinutes,
    required this.mealCount,
    required this.waterMl,
  });

  final DateTime date;

  /// `null` quando o dia não tem sono registrado.
  final int? sleepMinutes;
  final int mealCount;

  /// `null` quando o dia não tem água registrada.
  final int? waterMl;
}
