import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/apex_colors.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../exercises/presentation/exercises_screen.dart';
import '../../gyms/presentation/gyms_screen.dart';
import '../../muscle_groups/presentation/muscle_groups_screen.dart';
import '../providers/clock_provider.dart';
import 'widgets/apex_navigation_drawer.dart';
import 'widgets/management_shortcut.dart';
import 'widgets/start_workout_button.dart';
import '../../workouts/providers/workout_providers.dart';
import '../../workouts/presentation/active_workout_screen.dart';
import '../../workouts/presentation/workout_history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _opening = false;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final greeting = greetingFor(ref.watch(clockProvider)());
    final active = ref.watch(activeWorkoutProvider);
    return Scaffold(
      drawer: const ApexNavigationDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Brand(),
                        const SizedBox(height: 44),
                        Text(
                          greeting,
                          key: const Key('greetingText'),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pronto para superar seu último treino?',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: ApexColors.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        StartWorkoutButton(
                          label: active.value != null
                              ? 'Continuar treino'
                              : 'Iniciar Exercício',
                          onPressed:
                              _opening || active.isLoading || active.hasError
                              ? null
                              : () async {
                                  setState(() => _opening = true);
                                  try {
                                    final id = await ref
                                        .read(workoutRepositoryProvider)
                                        .start(
                                          performedAt: ref.read(
                                            clockProvider,
                                          )(),
                                        );
                                    if (context.mounted) {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ActiveWorkoutScreen(
                                            workoutId: id,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Não foi possível abrir o treino: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _opening = false);
                                    }
                                  }
                                },
                        ),
                        if (active.hasError)
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(activeWorkoutProvider),
                            child: const Text(
                              'Erro ao carregar treino. Tentar novamente',
                            ),
                          ),
                        const SizedBox(height: 48),
                        Text(
                          'Gerenciar',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 620 ? 4 : 2;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: columns == 4
                                  ? 1.1
                                  : constraints.maxWidth < 360
                                  ? 0.9
                                  : 1.25,
                              children: [
                                ManagementShortcut(
                                  buttonKey: const Key('openHistoryButton'),
                                  icon: Icons.history,
                                  label: 'Histórico',
                                  onTap: () => _open(
                                    context,
                                    const WorkoutHistoryScreen(),
                                  ),
                                ),
                                ManagementShortcut(
                                  buttonKey: const Key('openGymsButton'),
                                  icon: Icons.fitness_center,
                                  label: 'Academias',
                                  onTap: () =>
                                      _open(context, const GymsScreen()),
                                ),
                                ManagementShortcut(
                                  buttonKey: const Key('openCategoriesButton'),
                                  icon: Icons.category_outlined,
                                  label: 'Categorias',
                                  onTap: () =>
                                      _open(context, const CategoriesScreen()),
                                ),
                                ManagementShortcut(
                                  buttonKey: const Key(
                                    'openMuscleGroupsButton',
                                  ),
                                  icon: Icons.accessibility_new,
                                  label: 'Grupos musculares',
                                  onTap: () => _open(
                                    context,
                                    const MuscleGroupsScreen(),
                                  ),
                                ),
                                ManagementShortcut(
                                  buttonKey: const Key('openExercisesButton'),
                                  icon: Icons.list_alt,
                                  label: 'Exercícios',
                                  onTap: () =>
                                      _open(context, const ExercisesScreen()),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('openNavigationDrawerButton'),
          tooltip: 'Abrir menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        const SizedBox(width: 4),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ApexColors.primaryNeon,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.show_chart_rounded, color: ApexColors.canvas),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'APEX WORKOUT',
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
