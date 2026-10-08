import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_list_item.dart';
import '../providers/exercise_providers.dart';
import 'exercise_form_screen.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  Future<void> _openForm(BuildContext context, [ExerciseListItem? item]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExerciseFormScreen(exercise: item?.exercise),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? 'Exercício cadastrado.' : 'Exercício atualizado.',
          ),
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ExerciseListItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir exercício?'),
        content: Text(
          'O exercício “${item.exercise.name}” será removido permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(exerciseRepositoryProvider).delete(item.exercise.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Exercício excluído.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível excluir. O exercício pode estar vinculado '
              'a um treino.\n$error',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      body: exercises.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Não foi possível carregar os exercícios.\n$error'),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nenhum exercício cadastrado.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    key: Key('exerciseTile_${item.exercise.id}'),
                    title: Text(item.exercise.name),
                    subtitle: Text(
                      '${item.categoryName} • ${item.muscleGroupName} • '
                      '${item.exercise.measurementUnit.symbol}',
                    ),
                    onTap: () => _openForm(context, item),
                    trailing: IconButton(
                      tooltip: 'Excluir ${item.exercise.name}',
                      onPressed: () => _delete(context, ref, item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addExerciseButton'),
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
