import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/apex_colors.dart';
import '../../../core/theme/apex_shapes.dart';
import '../../home/presentation/widgets/apex_navigation_drawer.dart';
import '../../home/providers/clock_provider.dart';
import '../domain/wellness_day.dart';
import '../providers/wellness_providers.dart';
import 'meal_form_screen.dart';
import 'sleep_form_screen.dart';
import 'water_form_sheet.dart';
import 'wellness_format.dart';
import 'wellness_history_screen.dart';
import 'widgets/wellness_fields.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _selectedDay = calendarDay(widget.initialDate ?? now);
  }

  void _shiftDay(int delta) {
    setState(() {
      _selectedDay = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + delta,
      );
    });
  }

  Future<void> _openHistory() async {
    final picked = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(builder: (_) => const WellnessHistoryScreen()),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDay = calendarDay(picked));
    }
  }

  Future<void> _quickAddWater(int amountMl) async {
    final now = ref.read(clockProvider)();
    try {
      await ref
          .read(wellnessRepositoryProvider)
          .saveWater(
            consumedAt: defaultTimeFor(_selectedDay, now),
            amountMl: amountMl,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${formatMl(amountMl)} registrado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(describeError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final today = calendarDay(now);
    final isToday = _selectedDay == today;
    final isFutureNext = _selectedDay.isAtSameMomentAs(today);
    final state = ref.watch(wellnessDayProvider(_selectedDay));

    return Scaffold(
      drawer: const ApexNavigationDrawer(selectedIndex: 1),
      appBar: AppBar(
        title: const Text('Bem-estar'),
        actions: [
          IconButton(
            key: const Key('openWellnessHistoryButton'),
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
            onPressed: _openHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _DateSelector(
                  day: _selectedDay,
                  isToday: isToday,
                  canGoForward: !isFutureNext,
                  onPrevious: () => _shiftDay(-1),
                  onNext: () => _shiftDay(1),
                  onToday: () => setState(() => _selectedDay = today),
                ),
                const SizedBox(height: 20),
                state.when(
                  data: (day) => Column(
                    children: [
                      _SleepCard(
                        day: day,
                        onAdd: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SleepFormScreen(day: _selectedDay),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MealsCard(
                        day: day,
                        onAdd: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MealFormScreen(day: _selectedDay),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _WaterCard(
                        day: day,
                        onQuickAdd: _quickAddWater,
                        onCustomAdd: () =>
                            showWaterFormSheet(context, day: _selectedDay),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Erro ao carregar dados: $error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            wellnessDayProvider(_selectedDay),
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.day,
    required this.isToday,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime day;
  final bool isToday;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ApexColors.surfaceLow,
        borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('previousDayButton'),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Dia anterior',
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  formatWeekday(day),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ApexColors.textSecondary,
                  ),
                ),
                Text(
                  isToday ? 'Hoje · ${formatDate(day)}' : formatDate(day),
                  key: const Key('currentDayText'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (!isToday)
            TextButton(
              key: const Key('todayButton'),
              onPressed: onToday,
              child: const Text('Hoje'),
            ),
          IconButton(
            key: const Key('nextDayButton'),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo dia',
            onPressed: canGoForward ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _SleepCard extends ConsumerWidget {
  const _SleepCard({required this.day, required this.onAdd});

  final WellnessDay day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Sono',
      icon: Icons.bedtime_outlined,
      total: day.sleep.isEmpty
          ? 'Não registrado'
          : formatDuration(day.sleepMinutes),
      totalKey: const Key('sleepTotalText'),
      onAdd: onAdd,
      addKey: const Key('addSleepButton'),
      emptyText: 'Nenhum sono registrado para este dia.',
      children: [
        for (final sleep in day.sleep)
          ListTile(
            key: Key('sleepLogItem_${sleep.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              sleep.bedTime != null && sleep.wakeTime != null
                  ? '${formatTime(sleep.bedTime!)} → ${formatTime(sleep.wakeTime!)} '
                      '(${formatDuration(sleep.durationMinutes)})'
                  : formatDuration(sleep.durationMinutes),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: sleep.notes != null ? Text(sleep.notes!) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('editSleepButton_${sleep.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SleepFormScreen(
                        day: day.date,
                        initial: sleep,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: Key('deleteSleepButton_${sleep.id}'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Excluir',
                  onPressed: () async {
                    final ok = await confirmDeletion(
                      context,
                      title: 'Excluir sono?',
                      content: 'Este período de sono será apagado.',
                    );
                    if (ok) {
                      await ref
                          .read(wellnessRepositoryProvider)
                          .deleteSleep(sleep.id);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MealsCard extends ConsumerWidget {
  const _MealsCard({required this.day, required this.onAdd});

  final WellnessDay day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Alimentação',
      icon: Icons.restaurant_outlined,
      total: day.mealCount == 0
          ? 'Nenhuma refeição'
          : '${day.mealCount} ${day.mealCount == 1 ? 'refeição' : 'refeições'}',
      totalKey: const Key('mealsTotalText'),
      onAdd: onAdd,
      addKey: const Key('addMealButton'),
      emptyText: 'Nenhuma refeição registrada.',
      children: [
        for (final entry in day.meals)
          ListTile(
            key: Key('mealItem_${entry.meal.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${formatTime(entry.meal.eatenAt)}'
              '${entry.meal.mealType != null ? ' · ${entry.meal.mealType!.label}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.items.isNotEmpty)
                  Text(
                    entry.items
                        .map(
                          (i) => i.quantityValue != null && i.quantityUnit != null
                              ? '${i.name} (${formatQuantity(i.quantityValue!)} ${i.quantityUnit!.symbol})'
                              : i.name,
                        )
                        .join(', '),
                  ),
                if (entry.meal.notes != null)
                  Text(
                    entry.meal.notes!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('editMealButton_${entry.meal.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealFormScreen(
                        day: day.date,
                        initial: entry,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: Key('deleteMealButton_${entry.meal.id}'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Excluir',
                  onPressed: () async {
                    final ok = await confirmDeletion(
                      context,
                      title: 'Excluir refeição?',
                      content:
                          'A refeição e todos os seus itens serão apagados.',
                    );
                    if (ok) {
                      await ref
                          .read(wellnessRepositoryProvider)
                          .deleteMeal(entry.meal.id);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({
    required this.day,
    required this.onQuickAdd,
    required this.onCustomAdd,
  });

  final WellnessDay day;
  final void Function(int amount) onQuickAdd;
  final VoidCallback onCustomAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SectionCard(
      title: 'Água',
      icon: Icons.water_drop_outlined,
      total: day.water.isEmpty ? '0 ml' : formatMl(day.waterMl),
      totalKey: const Key('waterTotalText'),
      onAdd: onCustomAdd,
      addKey: const Key('addWaterButton'),
      emptyText: 'Nenhuma ingestão de água registrada.',
      headerBottom: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Wrap(
          spacing: 8,
          children: [
            ActionChip(
              key: const Key('quickAddWater250Button'),
              label: const Text('+250 ml'),
              onPressed: () => onQuickAdd(250),
            ),
            ActionChip(
              key: const Key('quickAddWater500Button'),
              label: const Text('+500 ml'),
              onPressed: () => onQuickAdd(500),
            ),
          ],
        ),
      ),
      children: [
        for (final intake in day.water)
          ListTile(
            key: Key('waterIntakeItem_${intake.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${formatTime(intake.consumedAt)} · ${formatMl(intake.amountMl)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('editWaterButton_${intake.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  onPressed: () => showWaterFormSheet(
                    context,
                    day: day.date,
                    initial: intake,
                  ),
                ),
                IconButton(
                  key: Key('deleteWaterButton_${intake.id}'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Excluir',
                  onPressed: () async {
                    final ok = await confirmDeletion(
                      context,
                      title: 'Excluir registro de água?',
                      content: 'Esta ingestão será apagada.',
                    );
                    if (ok) {
                      await ref
                          .read(wellnessRepositoryProvider)
                          .deleteWater(intake.id);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.total,
    required this.totalKey,
    required this.onAdd,
    required this.addKey,
    required this.emptyText,
    required this.children,
    this.headerBottom,
  });

  final String title;
  final IconData icon;
  final String total;
  final Key totalKey;
  final VoidCallback onAdd;
  final Key addKey;
  final String emptyText;
  final List<Widget> children;
  final Widget? headerBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ApexColors.surface,
        borderRadius: BorderRadius.circular(ApexShapes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ApexColors.primaryNeon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: addKey,
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar',
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            total,
            key: totalKey,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: ApexColors.primaryNeon,
            ),
          ),
          ?headerBottom,
          const SizedBox(height: 8),
          const Divider(),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                emptyText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}
