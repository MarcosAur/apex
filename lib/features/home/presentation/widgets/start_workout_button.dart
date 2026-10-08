import 'package:flutter/material.dart';

import '../../../../core/theme/apex_shapes.dart';

class StartWorkoutButton extends StatelessWidget {
  const StartWorkoutButton({
    required this.onPressed,
    this.label = 'Iniciar Exercício',
    super.key,
  });
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x5200E676), blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          key: const Key('startWorkoutButton'),
          onPressed: onPressed,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(label),
        ),
      ),
    );
  }
}
