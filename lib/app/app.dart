import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_provider.dart';
import '../core/theme/apex_theme.dart';
import '../features/home/presentation/home_screen.dart';

class ApexApp extends ConsumerWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(databaseInitializationProvider);
    return MaterialApp(
      title: 'Apex Workout',
      debugShowCheckedModeBanner: false,
      theme: ApexTheme.dark,
      home: initialization.when(
        data: (_) => const HomeScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível preparar os dados locais.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
