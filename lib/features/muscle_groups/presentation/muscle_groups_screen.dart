import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/named_entities_screen.dart';
import '../providers/muscle_group_providers.dart';
import 'muscle_group_form_screen.dart';

class MuscleGroupsScreen extends ConsumerWidget {
  const MuscleGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NamedEntitiesScreen(
      title: 'Grupos musculares',
      items: ref.watch(muscleGroupsProvider),
      idOf: (group) => group.id,
      nameOf: (group) => group.name,
      formBuilder: (group) => MuscleGroupFormScreen(muscleGroup: group),
      onDelete: ref.read(muscleGroupRepositoryProvider).delete,
      emptyMessage: 'Nenhum grupo muscular cadastrado.',
      addButtonKey: 'addMuscleGroupButton',
      itemKeyPrefix: 'muscleGroupTile_',
      deleteKeyPrefix: 'deleteMuscleGroup_',
      deleteTitle: 'Excluir grupo muscular?',
      deleteDescription: (name) =>
          'O grupo muscular “$name” será removido permanentemente.',
      createdMessage: 'Grupo muscular cadastrado.',
      updatedMessage: 'Grupo muscular atualizado.',
      deletedMessage: 'Grupo muscular excluído.',
      linkedErrorMessage: 'Não foi possível excluir. O grupo pode estar vinculado a um exercício.',
    );
  }
}
