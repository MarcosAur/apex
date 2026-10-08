import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../exercises/domain/measurement_unit.dart';
import '../../domain/effort_level.dart';

class SetDraftForm extends StatefulWidget {
  const SetDraftForm({
    super.key,
    required this.draft,
    required this.measurementUnit,
    required this.persist,
    required this.commit,
    required this.discard,
  });
  final SetDraft draft;
  final MeasurementUnit measurementUnit;
  final Future<bool> Function(String, String, String?, String) persist;
  final Future<bool> Function() commit;
  final Future<bool> Function() discard;
  @override
  State<SetDraftForm> createState() => _SetDraftFormState();
}

class _SetDraftFormState extends State<SetDraftForm> {
  late final _measurement = TextEditingController(
    text: widget.draft.measurementText,
  );
  late final _reps = TextEditingController(text: widget.draft.repsText);
  late final _pace = TextEditingController(text: widget.draft.paceText);
  bool _busy = false;
  Future<bool> _save() =>
      widget.persist(_measurement.text, _reps.text, _effort, _pace.text);

  @override
  void dispose() {
    _measurement.dispose();
    _reps.dispose();
    _pace.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.draft.editingLogId == null
            ? 'Novo registro • rascunho'
            : 'Editar registro • rascunho',
      ),
      const SizedBox(height: 12),
      TextField(
        key: ValueKey('measurement-${widget.draft.workoutExerciseId}'),
        controller: _measurement,
        enabled: !_busy,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText:
              '${widget.measurementUnit.fieldLabel} (${widget.measurementUnit.symbol})',
        ),
        onChanged: (_) => _save(),
      ),
      if (widget.measurementUnit.requiresUserReps) ...[
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('reps-${widget.draft.workoutExerciseId}'),
          controller: _reps,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Repetições'),
          onChanged: (_) => _save(),
        ),
      ] else ...[
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('pace-${widget.draft.workoutExerciseId}'),
          controller: _pace,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Pace (min/km, ex: 5:30 ou 5.5)'),
          onChanged: (_) => _save(),
        ),
      ],
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey('effort-${widget.draft.workoutExerciseId}'),
        initialValue: _effort,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Nível de esforço'),
        items: EffortLevel.values
            .map(
              (e) =>
                  DropdownMenuItem(value: e.storageValue, child: Text(e.label)),
            )
            .toList(),
        onChanged: _busy
            ? null
            : (value) {
                setState(() => _effort = value);
                _save();
              },
      ),
      Wrap(
        spacing: 8,
        children: [
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    if (await _save()) await widget.commit();
                    if (mounted) setState(() => _busy = false);
                  },
            child: Text(
              widget.measurementUnit.requiresUserReps
                  ? 'Salvar série'
                  : 'Salvar distância',
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await widget.discard();
                    if (mounted) setState(() => _busy = false);
                  },
            child: const Text('Descartar rascunho'),
          ),
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Salvar rascunho'),
          ),
        ],
      ),
    ],
  );
}
