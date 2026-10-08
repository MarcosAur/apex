import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../providers/gym_providers.dart';
import 'gym_form_screen.dart';

class GymsScreen extends ConsumerWidget {
  const GymsScreen({super.key});

  Future<void> _openForm(BuildContext context, {Gym? gym}) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => GymFormScreen(gym: gym)));
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gym == null ? 'Academia cadastrada.' : 'Academia atualizada.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeletion(
    BuildContext context,
    WidgetRef ref,
    Gym gym,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir academia?'),
        content: Text(
          'A academia “${gym.name}” será removida permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(gymRepositoryProvider).delete(gym.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Academia excluída.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível excluir. Verifique se a academia está '
              'vinculada a um treino.\n$error',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gyms = ref.watch(gymsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Academias')),
      body: gyms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar as academias.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhuma academia cadastrada.\n'
                  'Use o botão + para adicionar a primeira.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final gym = items[index];
              return ListTile(
                key: Key('gymTile_${gym.id}'),
                title: Text(gym.name),
                subtitle: gym.location == null ? null : Text(gym.location!),
                onTap: () => _openForm(context, gym: gym),
                trailing: IconButton(
                  key: Key('deleteGym_${gym.id}'),
                  tooltip: 'Excluir ${gym.name}',
                  onPressed: () => _confirmDeletion(context, ref, gym),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addGymButton'),
        tooltip: 'Adicionar academia',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
