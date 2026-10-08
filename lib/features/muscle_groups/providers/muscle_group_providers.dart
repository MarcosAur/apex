import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/muscle_group_repository.dart';

final muscleGroupRepositoryProvider = Provider<MuscleGroupRepository>((ref) {
  return MuscleGroupRepository(ref.watch(databaseProvider));
});

final muscleGroupsProvider = StreamProvider<List<MuscleGroup>>((ref) {
  return ref.watch(muscleGroupRepositoryProvider).watchAll();
});
