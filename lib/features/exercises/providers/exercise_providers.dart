import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/exercise_list_item.dart';
import '../data/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

final exercisesProvider = StreamProvider<List<ExerciseListItem>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAll();
});
