import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exercises/providers/exercise_providers.dart';
import '../../exercises/presentation/exercises_screen.dart';
import '../../gyms/providers/gym_providers.dart';
import '../data/workout_repository.dart';
import '../providers/workout_providers.dart';
import 'widgets/set_draft_form.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.workoutId});
  final int workoutId;
  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  final _notes = TextEditingController();
  bool _loadedNotes = false;
  int _pending = 0;
  final Map<String, String> _errors = {};
  WorkoutRepository get repository => ref.read(workoutRepositoryProvider);
  String _formatPace(double pace) {
    final minutes = pace.truncate();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool> _run(String key, Future<void> Function() action) async {
    setState(() => _pending++);
    try {
      await action();
      if (mounted) setState(() => _errors.remove(key));
      return true;
    } catch (error) {
      if (mounted) setState(() => _errors[key] = error.toString());
      return false;
    } finally {
      if (mounted) setState(() => _pending--);
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _chooseExercise() async {
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ExercisePicker(),
    );
    if (id != null && mounted) {
      await _run('action', () async {
        await repository.addExercise(widget.workoutId, id);
      });
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutSessionProvider(widget.workoutId));
    return Scaffold(
      appBar: AppBar(title: const Text('Treino')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Não foi possível abrir o treino: $e')),
        data: (session) {
          final workout = session.workout;
          final active = workout.status == 'active';
          if (!_loadedNotes) {
            _notes.text = workout.notes ?? '';
            _loadedNotes = true;
          }
          final gyms = ref.watch(gymsProvider);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                active
                    ? 'Treino em andamento'
                    : workout.status == 'legacy'
                    ? 'Treino legado'
                    : 'Treino encerrado',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('Início: ${_date(workout.performedAt)}'),
              if (workout.completedAt != null)
                Text('Encerramento: ${_date(workout.completedAt!)}'),
              const SizedBox(height: 16),
              if (active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _pending > 0
                                    ? Icons.sync
                                    : _errors.isEmpty
                                    ? Icons.cloud_done_outlined
                                    : Icons.error_outline,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _pending > 0
                                      ? 'Salvando…'
                                      : _errors.isEmpty
                                      ? 'Salvo no dispositivo'
                                      : 'Há alterações ou ações pendentes',
                                  key: const Key('saveStatus'),
                                ),
                              ),
                            ],
                          ),
                          for (final error in _errors.entries)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                error.value,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          if (_errors.containsKey('notes'))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton(
                                onPressed: () => _run(
                                  'notes',
                                  () => repository.updateDetails(
                                    workout.id,
                                    notes: Value(_notes.text),
                                  ),
                                ),
                                child: const Text(
                                  'Tentar salvar observações novamente',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              gyms.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) =>
                    Text('Não foi possível carregar academias: $e'),
                data: (rows) => active
                    ? DropdownButtonFormField<int>(
                        key: ValueKey('gym-${workout.gymId}'),
                        initialValue: workout.gymId ?? 0,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Academia (opcional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Sem academia'),
                          ),
                          ...rows.map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            ),
                          ),
                        ],
                        onChanged: (id) => _run(
                          'gym',
                          () => repository.updateDetails(
                            workout.id,
                            gymId: Value(id == 0 ? null : id),
                          ),
                        ),
                      )
                    : Text(
                        'Academia: ${rows.where((g) => g.id == workout.gymId).firstOrNull?.name ?? 'Não informada'}',
                      ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('workoutNotes'),
                controller: _notes,
                readOnly: !active,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
                onChanged: (value) => _run(
                  'notes',
                  () =>
                      repository.updateDetails(workout.id, notes: Value(value)),
                ),
              ),
              const SizedBox(height: 20),
              if (workout.status == 'legacy') ...[
                const Text(
                  'Este registro é anterior ao controle de encerramento. Você pode retomá-lo se não houver outro treino ativo.',
                ),
                if (_errors.containsKey('action')) Text(_errors['action']!),
                OutlinedButton(
                  onPressed: _pending > 0
                      ? null
                      : () => _run(
                          'action',
                          () => repository.resumeLegacy(workout.id),
                        ),
                  child: const Text('Retomar este treino'),
                ),
              ],
              if (session.exercises.isEmpty)
                const Text('Nenhum exercício adicionado.'),
              for (final exercise in session.exercises)
                _exerciseCard(session, exercise, active),
              if (active) ...[
                FilledButton.icon(
                  key: const Key('addWorkoutExercise'),
                  onPressed: _pending > 0 ? null : _chooseExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar exercício'),
                ),
                const SizedBox(height: 20),
                if (session.drafts.isNotEmpty)
                  const Text('Conclua ou descarte os rascunhos para encerrar.'),
                OutlinedButton.icon(
                  key: const Key('finishWorkout'),
                  onPressed:
                      _pending > 0 ||
                          session.drafts.isNotEmpty ||
                          _errors.keys.any((k) => k != 'action')
                      ? null
                      : () async {
                          if (await _confirm(
                                'Encerrar treino?',
                                'O treino ficará disponível para consulta e não poderá mais ser editado.',
                              ) &&
                              mounted) {
                            final avaliar = await _confirm(
                              'Avaliação do treino',
                              'Deseja fazer uma avaliação de desempenho deste treino?',
                            );
                            if (!mounted) return;
                            String? evaluationText;
                            if (avaliar) {
                              final controller = TextEditingController();
                              evaluationText = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Avaliação do desempenho'),
                                  content: TextField(
                                    controller: controller,
                                    maxLines: 4,
                                    decoration: const InputDecoration(hintText: 'Escreva como foi o desempenho...'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, controller.text),
                                      child: const Text('Salvar'),
                                    ),
                                  ],
                                ),
                              );
                              controller.dispose();
                              if (evaluationText == null && mounted) return; // Cancelled evaluation
                            }
                            if (!mounted) return;
                            await _run(
                              'action',
                              () async {
                                if (evaluationText != null) {
                                  await repository.updateDetails(workout.id, evaluation: Value(evaluationText));
                                }
                                await repository.finish(workout.id);
                              }
                            );
                          }
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Encerrar treino'),
                ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _exerciseCard(
    WorkoutSession session,
    SessionExercise exercise,
    bool active,
  ) {
    final id = exercise.item.id;
    final draft = session.drafts
        .where((d) => d.workoutExerciseId == id)
        .firstOrNull;
    final logs = session.logs.where((l) => l.workoutExerciseId == id);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              exercise.exercise.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('${exercise.category} • ${exercise.muscle}'),
            if (active)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Remover ${exercise.exercise.name}',
                  onPressed: _pending > 0
                      ? null
                      : () async {
                          if (await _confirm(
                                'Remover exercício?',
                                'Todas as séries e o rascunho deste exercício serão removidos.',
                              ) &&
                              mounted) {
                            final ok = await _run(
                              'draft-$id',
                              () => repository.removeExercise(id),
                            );
                            if (ok && mounted) {
                              setState(() => _errors.remove('action'));
                            }
                          }
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            for (final log in logs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.item.measurementUnit.requiresUserReps
                          ? 'Série ${log.setNumber} • ${log.measurementValue} ${exercise.item.measurementUnit.symbol} • ${log.reps} repetições'
                          : 'Registro ${log.setNumber} • ${log.measurementValue} ${exercise.item.measurementUnit.symbol}'
                              '${log.pace != null ? ' @ ${_formatPace(log.pace!)} min/km' : ''}',
                    ),
                    Text(log.effortLevel?.label ?? 'Esforço não informado'),
                    if (active && draft == null)
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: _pending > 0
                                ? null
                                : () => _run(
                                    'action',
                                    () => repository.beginDraft(
                                      id,
                                      logId: log.id,
                                    ),
                                  ),
                            child: Text(
                              exercise.item.measurementUnit.requiresUserReps
                                  ? 'Editar série'
                                  : 'Editar distância',
                            ),
                          ),
                          TextButton(
                            onPressed: _pending > 0
                                ? null
                                : () async {
                                    if (await _confirm(
                                          'Excluir série?',
                                          'A série será removida e as seguintes serão renumeradas.',
                                        ) &&
                                        mounted) {
                                      await _run(
                                        'action',
                                        () => repository.removeLog(log.id),
                                      );
                                    }
                                  },
                            child: Text(
                              exercise.item.measurementUnit.requiresUserReps
                                  ? 'Excluir série'
                                  : 'Excluir distância',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (active && draft != null)
              SetDraftForm(
                key: ValueKey('draft-$id-${draft.editingLogId}'),
                measurementUnit: exercise.item.measurementUnit,
                persist: (measurement, reps, effort, pace) => _run(
                  'draft-$id',
                  () => repository.saveDraft(
                    id,
                    measurement,
                    reps,
                    effort,
                    pace,
                  ),
                ),
                commit: () =>
                    _run('draft-$id', () => repository.commitDraft(id)),
                discard: () async {
                  if (await _confirm(
                        'Descartar rascunho?',
                        'Os campos em preenchimento serão descartados.',
                      ) &&
                      mounted) {
                    return _run('draft-$id', () => repository.discardDraft(id));
                  }
                  return false;
                },
              ),
            if (active && draft == null)
              TextButton.icon(
                key: ValueKey('addSet-$id'),
                onPressed: _pending > 0
                    ? null
                    : () => _run('action', () => repository.beginDraft(id)),
                icon: const Icon(Icons.add),
                label: Text(
                  exercise.item.measurementUnit.requiresUserReps
                      ? 'Adicionar série'
                      : 'Adicionar distância',
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _ExercisePicker extends ConsumerStatefulWidget {
  const _ExercisePicker();
  @override
  ConsumerState<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends ConsumerState<_ExercisePicker> {
  String query = '';
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .85,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        children: [
          Text(
            'Selecionar exercício',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Buscar exercício'),
            onChanged: (s) => setState(() => query = s.trim().toLowerCase()),
          ),
          Expanded(
            child: ref
                .watch(exercisesProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (rows) {
                    final filtered = rows
                        .where(
                          (e) => e.exercise.name.toLowerCase().contains(query),
                        )
                        .toList();
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum exercício encontrado. Cadastre um exercício abaixo.',
                        ),
                      );
                    }
                    return ListView(
                      children: filtered
                          .map(
                            (e) => ListTile(
                              title: Text(e.exercise.name),
                              subtitle: Text(
                                '${e.categoryName} • ${e.muscleGroupName} • '
                                '${e.exercise.measurementUnit.symbol}',
                              ),
                              onTap: () =>
                                  Navigator.pop(context, e.exercise.id),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExercisesScreen()),
            ),
            child: const Text('Gerenciar exercícios'),
          ),
        ],
      ),
    ),
  );
}
