import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/workout_repository.dart';
import '../../../core/database/app_database.dart';

final workoutRepositoryProvider = Provider(
  (ref) => WorkoutRepository(ref.watch(databaseProvider)),
);
final workoutsProvider = StreamProvider(
  (ref) => ref.watch(workoutRepositoryProvider).watchAll(),
);

final activeWorkoutProvider = StreamProvider<Workout?>(
  (ref) => ref.watch(workoutRepositoryProvider).watchActive(),
);
final workoutSessionProvider = StreamProvider.autoDispose
    .family<WorkoutSession, int>(
      (ref, id) => ref.watch(workoutRepositoryProvider).watchSession(id),
    );
