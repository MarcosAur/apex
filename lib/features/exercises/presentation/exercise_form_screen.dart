import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../categories/providers/category_providers.dart';
import '../../muscle_groups/providers/muscle_group_providers.dart';
import '../domain/measurement_unit.dart';
import '../providers/exercise_providers.dart';

class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.exercise});
  final Exercise? exercise;

  @override
  ConsumerState<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  int? _categoryId;
  int? _muscleGroupId;
  late MeasurementUnit _measurementUnit;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name);
    _categoryId = widget.exercise?.categoryId;
    _muscleGroupId = widget.exercise?.muscleGroupId;
    _measurementUnit =
        widget.exercise?.measurementUnit ?? MeasurementUnit.kilograms;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      if (widget.exercise case final exercise?) {
        await repository.update(
          id: exercise.id,
          name: _nameController.text,
          categoryId: _categoryId!,
          muscleGroupId: _muscleGroupId!,
          measurementUnit: _measurementUnit,
        );
      } else {
        await repository.create(
          name: _nameController.text,
          categoryId: _categoryId!,
          muscleGroupId: _muscleGroupId!,
          measurementUnit: _measurementUnit,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final muscleGroups = ref.watch(muscleGroupsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exercise == null ? 'Novo exercício' : 'Editar exercício',
        ),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro nas categorias: $error')),
        data: (categoryItems) => muscleGroups.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Erro nos grupos musculares: $error')),
          data: (muscleItems) => SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (categoryItems.isEmpty || muscleItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Cadastre ao menos uma categoria e um grupo muscular.',
                      ),
                    ),
                  TextFormField(
                    key: const Key('exerciseNameField'),
                    controller: _nameController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o nome do exercício.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MeasurementUnit>(
                    key: const Key('exerciseMeasurementUnitField'),
                    initialValue: _measurementUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidade de medida',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final unit in MeasurementUnit.values)
                        DropdownMenuItem(
                          value: unit,
                          child: Text('${unit.label} (${unit.symbol})'),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _measurementUnit = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: const Key('exerciseCategoryField'),
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in categoryItems)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Selecione uma categoria.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: const Key('exerciseMuscleGroupField'),
                    initialValue: _muscleGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Grupo muscular',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final group in muscleItems)
                        DropdownMenuItem(
                          value: group.id,
                          child: Text(group.name),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _muscleGroupId = value),
                    validator: (value) =>
                        value == null ? 'Selecione um grupo muscular.' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('saveExerciseButton'),
                    onPressed:
                        _isSaving ||
                            categoryItems.isEmpty ||
                            muscleItems.isEmpty
                        ? null
                        : _save,
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
