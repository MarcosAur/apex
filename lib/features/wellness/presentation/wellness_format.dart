import 'package:flutter/material.dart';

const _weekdays = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

String _two(int value) => value.toString().padLeft(2, '0');

String formatDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';

String formatWeekday(DateTime date) => _weekdays[date.weekday - 1];

String formatTime(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

String formatTimeOfDay(TimeOfDay time) =>
    '${_two(time.hour)}:${_two(time.minute)}';

String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}

/// Inteiro com separador de milhar: `2.250 ml`.
String formatMl(int ml) {
  final digits = ml.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$buffer ml';
}

/// Número decimal com vírgula e sem zeros finais: `1,5`, `150`.
String formatQuantity(double value) {
  var text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return text.replaceAll('.', ',');
}

/// Aceita vírgula ou ponto; `null` para texto inválido.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

DateTime atTime(DateTime day, TimeOfDay time) =>
    DateTime(day.year, day.month, day.day, time.hour, time.minute);
