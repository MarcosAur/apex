import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../home/providers/clock_provider.dart';
import '../data/wellness_repository.dart';
import '../domain/wellness_day.dart';

final wellnessRepositoryProvider = Provider(
  (ref) => WellnessRepository(
    ref.watch(databaseProvider),
    now: ref.watch(clockProvider),
  ),
);

/// Registros do dia civil local; a chave deve ser a meia-noite do dia.
final wellnessDayProvider = StreamProvider.autoDispose
    .family<WellnessDay, DateTime>(
      (ref, day) => ref.watch(wellnessRepositoryProvider).watchDay(day),
    );

final wellnessHistoryProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(wellnessRepositoryProvider).watchHistory(),
);
