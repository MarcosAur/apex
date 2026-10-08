import 'package:flutter/material.dart';

import '../../../../core/theme/apex_colors.dart';
import '../../../../core/theme/apex_shapes.dart';
import '../../../wellness/presentation/wellness_screen.dart';

class ApexNavigationDrawer extends StatelessWidget {
  const ApexNavigationDrawer({this.selectedIndex = 0, super.key});

  final int selectedIndex;

  void _onDestinationSelected(BuildContext context, int index) {
    Navigator.of(context).pop();
    if (index == selectedIndex) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WellnessScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      key: const Key('apexNavigationDrawer'),
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onDestinationSelected(context, index),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ApexColors.primaryNeon,
                    borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: ApexColors.canvas,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'APEX WORKOUT',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(letterSpacing: 1.1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        const NavigationDrawerDestination(
          key: Key('workoutsDrawerDestination'),
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: Text('Treinos'),
        ),
        const NavigationDrawerDestination(
          key: Key('wellnessDrawerDestination'),
          icon: Icon(Icons.spa_outlined),
          selectedIcon: Icon(Icons.spa),
          label: Text('Bem-estar'),
        ),
      ],
    );
  }
}
