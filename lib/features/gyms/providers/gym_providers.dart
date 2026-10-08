import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/gym_repository.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository(ref.watch(databaseProvider));
});

final gymsProvider = StreamProvider<List<Gym>>((ref) {
  return ref.watch(gymRepositoryProvider).watchAll();
});
