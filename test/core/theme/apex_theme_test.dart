import 'package:apex/core/theme/apex_colors.dart';
import 'package:apex/core/theme/apex_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Configura a identidade Kinetic Obsidian', () {
    final theme = ApexTheme.dark;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, ApexColors.canvas);
    expect(theme.colorScheme.primary, ApexColors.primaryNeon);
    expect(theme.colorScheme.secondary, ApexColors.secondaryEmerald);
    expect(theme.colorScheme.error, ApexColors.danger);
    expect(theme.textTheme.headlineLarge?.fontFamily, 'SpaceGrotesk');
    expect(theme.textTheme.bodyLarge?.fontFamily, 'PlusJakartaSans');
  });
}
