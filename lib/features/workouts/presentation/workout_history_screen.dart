import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/workout_providers.dart';
import 'active_workout_screen.dart';
import '../../wellness/presentation/wellness_format.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  final Set<int> _deleting = {};

  Future<void> _delete(int id) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir treino?'),
            content: const Text(
              'O treino, seus exercícios, séries e rascunhos serão apagados '
              'permanentemente do dispositivo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('confirmDeleteWorkout'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _deleting.add(id));
    try {
      await ref.read(workoutRepositoryProvider).deleteWorkout(id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Treino excluído.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir o treino: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: state.when(
        data: (rows) => rows.isEmpty
            ? const Center(child: Text('Nenhum treino registrado.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final workout = rows[index];
                  final deleting = _deleting.contains(workout.id);
                  return ListTile(
                    title: Text(workout.title?.isNotEmpty == true ? workout.title! : 'Treino'),
                    subtitle: Text(
                      '${formatDate(workout.performedAt)} • ${formatWeekday(workout.performedAt)}\n'
                      '${workout.status == 'active'
                          ? 'Em andamento'
                          : workout.status == 'completed'
                          ? 'Encerrado'
                          : 'Legado'}',
                    ),
                    isThreeLine: true,
                    trailing: deleting
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            key: ValueKey('deleteWorkout-${workout.id}'),
                            tooltip: 'Excluir treino #${workout.id}',
                            onPressed: () => _delete(workout.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                    onTap: deleting
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActiveWorkoutScreen(workoutId: workout.id),
                            ),
                          ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
