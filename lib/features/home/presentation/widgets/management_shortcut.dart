import 'package:flutter/material.dart';

import '../../../../core/theme/apex_colors.dart';
import '../../../../core/theme/apex_shapes.dart';

class ManagementShortcut extends StatelessWidget {
  const ManagementShortcut({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ApexColors.surfaceLow,
      borderRadius: BorderRadius.circular(ApexShapes.cardRadius),
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(ApexShapes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ApexColors.secondaryEmerald),
              const SizedBox(height: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
