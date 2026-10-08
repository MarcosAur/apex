import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/apex_colors.dart';
import '../../../core/theme/apex_shapes.dart';
import '../../home/providers/clock_provider.dart';
import '../domain/meal_type.dart';
import '../domain/quantity_unit.dart';
import '../domain/wellness_day.dart';
import '../providers/wellness_providers.dart';
import 'wellness_format.dart';
import 'widgets/wellness_fields.dart';

class MealFormScreen extends ConsumerStatefulWidget {
  const MealFormScreen({required this.day, super.key, this.initial});

  final DateTime day;
  final MealEntry? initial;

  @override
  ConsumerState<MealFormScreen> createState() => _MealFormScreenState();
}

class _ItemRow {
  _ItemRow({String name = '', String quantity = '', QuantityUnit? unit})
    : name = TextEditingController(text: name),
      quantity = TextEditingController(text: quantity),
      unit = unit ?? QuantityUnit.grams;

  final TextEditingController name;
  final TextEditingController quantity;
  QuantityUnit unit;

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class _MealFormScreenState extends ConsumerState<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _time;
  MealType? _type;
  late final TextEditingController _notes;
  final List<_ItemRow> _items = [];
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _time = TimeOfDay.fromDateTime(initial.meal.eatenAt);
      _type = initial.meal.mealType;
      _notes = TextEditingController(text: initial.meal.notes);
      for (final item in initial.items) {
        _items.add(
          _ItemRow(
            name: item.name,
            quantity: item.quantityValue != null
                ? formatQuantity(item.quantityValue!)
                : '',
            unit: item.quantityUnit,
          ),
        );
      }
    } else {
      final now = ref.read(clockProvider)();
      _time = TimeOfDay.fromDateTime(defaultTimeFor(widget.day, now));
      _notes = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  DateTime get _eatenAt => atTime(widget.day, _time);

  void _addItem() => setState(() => _items.add(_ItemRow()));

  void _removeItem(int index) =>
      setState(() => _items.removeAt(index).dispose());

  void _moveItem(int from, int to) {
    if (to < 0 || to >= _items.length) return;
    setState(() {
      final item = _items.removeAt(from);
      _items.insert(to, item);
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final inputs = <MealItemInput>[];
    for (final row in _items) {
      final name = row.name.text.trim();
      final qtyText = row.quantity.text.trim();
      final qty = qtyText.isEmpty ? null : parseDecimal(qtyText);
      inputs.add(
        MealItemInput(
          name: name,
          quantityValue: qty,
          quantityUnit: qty != null ? row.unit : null,
        ),
      );
    }
    try {
      await ref
          .read(wellnessRepositoryProvider)
          .saveMeal(
            id: widget.initial?.meal.id,
            eatenAt: _eatenAt,
            type: _type,
            notes: _notes.text,
            items: inputs,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Registrar refeição' : 'Editar refeição',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Refeição de ${formatWeekday(widget.day)}, ${formatDate(widget.day)}',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TimeField(
                key: const Key('mealTimeField'),
                label: 'Horário da refeição',
                value: _time,
                enabled: !_saving,
                onChanged: (value) => setState(() => _time = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MealType?>(
                key: const Key('mealTypeField'),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de refeição (opcional)',
                ),
                items: [
                  const DropdownMenuItem<MealType?>(
                    value: null,
                    child: Text('Não informado'),
                  ),
                  for (final type in MealType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: _saving ? null : (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('mealNotesField'),
                controller: _notes,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Itens (opcional)', style: textTheme.titleSmall),
                  TextButton.icon(
                    key: const Key('addMealItemButton'),
                    onPressed: _saving ? null : _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar item'),
                  ),
                ],
              ),
              if (_items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhum item adicionado. A refeição pode ser salva apenas com o horário.',
                    style: textTheme.bodySmall,
                  ),
                ),
              for (var i = 0; i < _items.length; i++) ...[
                const SizedBox(height: 8),
                _MealItemCard(
                  key: ValueKey(_items[i]),
                  index: i,
                  total: _items.length,
                  item: _items[i],
                  enabled: !_saving,
                  onRemove: () => _removeItem(i),
                  onMoveUp: () => _moveItem(i, i - 1),
                  onMoveDown: () => _moveItem(i, i + 1),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                key: const Key('saveMealButton'),
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

class _MealItemCard extends StatelessWidget {
  const _MealItemCard({
    required this.index,
    required this.total,
    required this.item,
    required this.enabled,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final int index;
  final int total;
  final _ItemRow item;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: ApexColors.surfaceLow,
        borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: Key('mealItemNameField_$index'),
                  controller: item.name,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Alimento',
                    isDense: true,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
                ),
              ),
              IconButton(
                key: Key('removeMealItemButton_$index'),
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Remover item',
                onPressed: enabled ? onRemove : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  key: Key('mealItemQuantityField_$index'),
                  controller: item.quantity,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Qtd. (opcional)',
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = parseDecimal(value);
                    if (parsed == null || !parsed.isFinite || parsed <= 0) {
                      return 'Inválida.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: DropdownButtonFormField<QuantityUnit>(
                  key: Key('mealItemUnitField_$index'),
                  initialValue: item.unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    isDense: true,
                  ),
                  items: [
                    for (final unit in QuantityUnit.values)
                      DropdownMenuItem(
                        value: unit,
                        child: Text(unit.symbol),
                      ),
                  ],
                  onChanged: enabled
                      ? (value) {
                          if (value != null) item.unit = value;
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: Key('moveMealItemUpButton_$index'),
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: 'Mover para cima',
                onPressed: enabled && index > 0 ? onMoveUp : null,
              ),
              IconButton(
                key: Key('moveMealItemDownButton_$index'),
                icon: const Icon(Icons.arrow_downward, size: 18),
                tooltip: 'Mover para baixo',
                onPressed: enabled && index < total - 1 ? onMoveDown : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
