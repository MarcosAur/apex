import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/apex_colors.dart';
import '../domain/wellness_day.dart';
import '../providers/wellness_providers.dart';
import 'wellness_format.dart';

class WellnessHistoryScreen extends ConsumerWidget {
  const WellnessHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de bem-estar')),
      body: state.when(
        data: (days) => days.isEmpty
            ? const Center(child: Text('Nenhum registro de bem-estar.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: days.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final day = days[index];
                  return ListTile(
                    key: Key('wellnessHistoryItem_${dateKey(day.date)}'),
                    title: Text(
                      '${formatWeekday(day.date)}, ${formatDate(day.date)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_describeSummary(day)),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ApexColors.textSecondary,
                    ),
                    onTap: () => Navigator.pop(context, day.date),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao carregar histórico: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static String _describeSummary(WellnessDaySummary day) {
    final parts = <String>[];
    if (day.sleepMinutes != null) {
      parts.add('Sono: ${formatDuration(day.sleepMinutes!)}');
    }
    if (day.mealCount > 0) {
      parts.add(
        '${day.mealCount} ${day.mealCount == 1 ? 'refeição' : 'refeições'}',
      );
    }
    if (day.waterMl != null) {
      parts.add('Água: ${formatMl(day.waterMl!)}');
    }
    return parts.isEmpty ? 'Sem dados' : parts.join(' · ');
  }
}
