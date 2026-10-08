import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/named_entity_form_screen.dart';
import '../providers/muscle_group_providers.dart';

class MuscleGroupFormScreen extends ConsumerWidget {
  const MuscleGroupFormScreen({super.key, this.muscleGroup});
  final MuscleGroup? muscleGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NamedEntityFormScreen(
      title: muscleGroup == null
          ? 'Novo grupo muscular'
          : 'Editar grupo muscular',
      entityName: 'um grupo muscular',
      fieldKey: 'muscleGroupNameField',
      saveButtonKey: 'saveMuscleGroupButton',
      initialName: muscleGroup?.name,
      onSave: (name) => muscleGroup == null
          ? ref.read(muscleGroupRepositoryProvider).create(name).then((_) {})
          : ref
                .read(muscleGroupRepositoryProvider)
                .update(muscleGroup!.id, name),
    );
  }
}
