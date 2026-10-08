import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../home/providers/clock_provider.dart';
import '../providers/wellness_providers.dart';
import 'wellness_format.dart';
import 'widgets/wellness_fields.dart';

Future<bool?> showWaterFormSheet(
  BuildContext context, {
  required DateTime day,
  WaterIntake? initial,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _WaterFormSheet(day: day, initial: initial),
);

class _WaterFormSheet extends ConsumerStatefulWidget {
  const _WaterFormSheet({required this.day, this.initial});

  final DateTime day;
  final WaterIntake? initial;

  @override
  ConsumerState<_WaterFormSheet> createState() => _WaterFormSheetState();
}

class _WaterFormSheetState extends ConsumerState<_WaterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _time;
  late final TextEditingController _amount;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _time = TimeOfDay.fromDateTime(initial.consumedAt);
      _amount = TextEditingController(text: '${initial.amountMl}');
    } else {
      final now = ref.read(clockProvider)();
      _time = TimeOfDay.fromDateTime(defaultTimeFor(widget.day, now));
      _amount = TextEditingController(text: '250');
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  DateTime get _consumedAt => atTime(widget.day, _time);

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(wellnessRepositoryProvider)
          .saveWater(
            id: widget.initial?.id,
            consumedAt: _consumedAt,
            amountMl: int.parse(_amount.text.trim()),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = describeError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initial == null
                      ? 'Registrar água'
                      : 'Editar ingestão de água',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _saving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TimeField(
              key: const Key('waterTimeField'),
              label: 'Horário',
              value: _time,
              enabled: !_saving,
              onChanged: (value) => setState(() => _time = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('waterAmountField'),
              controller: _amount,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Volume (ml)',
                suffixText: 'ml',
              ),
              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 1 || parsed > 5000) {
                  return 'Informe um volume entre 1 e 5000 ml.';
                }
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const Key('waterSheetErrorText'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('saveWaterButton'),
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
    );
  }
}
