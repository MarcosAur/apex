import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/apex_colors.dart';
import '../../home/providers/clock_provider.dart';
import '../domain/wellness_day.dart';
import '../providers/wellness_providers.dart';
import 'wellness_format.dart';
import 'widgets/wellness_fields.dart';

enum _SleepMode { times, duration }

/// Registra um período de sono do [day] (dia em que se acorda).
class SleepFormScreen extends ConsumerStatefulWidget {
  const SleepFormScreen({required this.day, super.key, this.initial});

  final DateTime day;
  final SleepLog? initial;

  @override
  ConsumerState<SleepFormScreen> createState() => _SleepFormScreenState();
}

class _SleepFormScreenState extends ConsumerState<SleepFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late _SleepMode _mode;
  late TimeOfDay _bed;
  late TimeOfDay _wake;
  late final TextEditingController _hours;
  late final TextEditingController _minutes;
  late final TextEditingController _notes;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final bed = initial?.bedTime;
    final wake = initial?.wakeTime;
    _mode = initial != null && bed == null ? _SleepMode.duration : _SleepMode.times;
    if (bed != null && wake != null) {
      _bed = TimeOfDay.fromDateTime(bed);
      _wake = TimeOfDay.fromDateTime(wake);
    } else {
      final now = ref.read(clockProvider)();
      final isToday = calendarDay(now) == widget.day;
      _wake = isToday && now.hour < 7
          ? TimeOfDay.fromDateTime(now)
          : const TimeOfDay(hour: 7, minute: 0);
      _bed = const TimeOfDay(hour: 23, minute: 0);
    }
    final minutes = initial?.durationMinutes ?? 480;
    _hours = TextEditingController(text: '${minutes ~/ 60}');
    _minutes = TextEditingController(text: '${minutes % 60}');
    _notes = TextEditingController(text: initial?.notes);
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  DateTime get _wakeAt => atTime(widget.day, _wake);

  /// Horário de dormir igual ou posterior ao de acordar pertence à véspera.
  DateTime get _bedAt {
    final sameDay = atTime(widget.day, _bed);
    if (sameDay.isBefore(_wakeAt)) return sameDay;
    final eve = DateTime(widget.day.year, widget.day.month, widget.day.day - 1);
    return atTime(eve, _bed);
  }

  int? get _durationMinutes {
    final hours = int.tryParse(_hours.text.trim());
    final minutes = int.tryParse(_minutes.text.trim());
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repository = ref.read(wellnessRepositoryProvider);
    try {
      if (_mode == _SleepMode.times) {
        await repository.saveTimedSleep(
          id: widget.initial?.id,
          bedTime: _bedAt,
          wakeTime: _wakeAt,
          notes: _notes.text,
        );
      } else {
        await repository.saveSleepDuration(
          id: widget.initial?.id,
          day: widget.day,
          minutes: _durationMinutes!,
          notes: _notes.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  String? _validateHours(String? value) {
    final hours = int.tryParse(value?.trim() ?? '');
    if (hours == null || hours < 0 || hours > 24) return 'De 0 a 24.';
    return null;
  }

  String? _validateMinutes(String? value) {
    final minutes = int.tryParse(value?.trim() ?? '');
    if (minutes == null || minutes < 0 || minutes > 59) return 'De 0 a 59.';
    final total = _durationMinutes;
    if (total != null && (total < 1 || total > 1440)) {
      return 'Total entre 1 min e 24 h.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bedAt = _bedAt;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Registrar sono' : 'Editar sono'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Sono de ${formatWeekday(widget.day)}, ${formatDate(widget.day)}',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'O sono conta para o dia em que você acordou.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SegmentedButton<_SleepMode>(
                segments: const [
                  ButtonSegment(
                    value: _SleepMode.times,
                    label: Text('Horários', key: Key('sleepModeTimes')),
                    icon: Icon(Icons.schedule),
                  ),
                  ButtonSegment(
                    value: _SleepMode.duration,
                    label: Text('Duração', key: Key('sleepModeDuration')),
                    icon: Icon(Icons.timelapse),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() => _mode = selection.single),
              ),
              const SizedBox(height: 20),
              if (_mode == _SleepMode.times) ...[
                TimeField(
                  key: const Key('sleepBedTimeField'),
                  label: 'Dormiu às',
                  value: _bed,
                  enabled: !_saving,
                  onChanged: (value) => setState(() => _bed = value),
                ),
                const SizedBox(height: 16),
                TimeField(
                  key: const Key('sleepWakeTimeField'),
                  label: 'Acordou às',
                  value: _wake,
                  enabled: !_saving,
                  onChanged: (value) => setState(() => _wake = value),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dormiu em ${formatDate(bedAt)} às ${formatTime(bedAt)} · '
                  '${formatDuration(_wakeAt.difference(bedAt).inMinutes)}',
                  key: const Key('sleepComputedDuration'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: ApexColors.secondaryEmerald,
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('sleepHoursField'),
                        controller: _hours,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Horas'),
                        validator: _validateHours,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('sleepMinutesField'),
                        controller: _minutes,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minutos'),
                        validator: _validateMinutes,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('sleepNotesField'),
                controller: _notes,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('saveSleepButton'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
