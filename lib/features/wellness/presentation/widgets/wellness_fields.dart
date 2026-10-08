import 'package:flutter/material.dart';

import '../../domain/wellness_day.dart';
import '../wellness_format.dart';

/// Seletor de horário em 24 h com textos em português.
Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initial) =>
    showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Selecione o horário',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minuto',
      errorInvalidText: 'Horário inválido',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

class TimeField extends StatelessWidget {
  const TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled
          ? () async {
              final picked = await pickTime(context, value);
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.schedule),
        ),
        child: Text(formatTimeOfDay(value)),
      ),
    );
  }
}

Future<bool> confirmDeletion(
  BuildContext context, {
  required String title,
  required String content,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirmWellnessDeletion'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ??
    false;

/// Mensagem de erro apresentável ao usuário.
String describeError(Object error) => switch (error) {
  WellnessValidationException(:final message) => message,
  StateError(:final message) => message,
  _ => 'Não foi possível salvar: $error',
};

/// Horário sugerido para novos registros do [day]: agora em hoje, 12:00 nos
/// dias anteriores.
DateTime defaultTimeFor(DateTime day, DateTime now) =>
    calendarDay(now) == day
    ? DateTime(now.year, now.month, now.day, now.hour, now.minute)
    : DateTime(day.year, day.month, day.day, 12);
