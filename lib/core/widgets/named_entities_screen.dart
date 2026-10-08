import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NamedEntitiesScreen<T> extends StatelessWidget {
  const NamedEntitiesScreen({
    required this.title,
    required this.items,
    required this.idOf,
    required this.nameOf,
    required this.formBuilder,
    required this.onDelete,
    required this.emptyMessage,
    required this.addButtonKey,
    required this.itemKeyPrefix,
    required this.deleteKeyPrefix,
    required this.deleteTitle,
    required this.deleteDescription,
    required this.createdMessage,
    required this.updatedMessage,
    required this.deletedMessage,
    required this.linkedErrorMessage,
    super.key,
  });

  final String title;
  final AsyncValue<List<T>> items;
  final int Function(T item) idOf;
  final String Function(T item) nameOf;
  final Widget Function(T? item) formBuilder;
  final Future<void> Function(int id) onDelete;
  final String emptyMessage;
  final String addButtonKey;
  final String itemKeyPrefix;
  final String deleteKeyPrefix;
  final String deleteTitle;
  final String Function(String name) deleteDescription;
  final String createdMessage;
  final String updatedMessage;
  final String deletedMessage;
  final String linkedErrorMessage;

  Future<void> _openForm(BuildContext context, [T? item]) async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => formBuilder(item)));
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(item == null ? createdMessage : updatedMessage)),
      );
    }
  }

  Future<void> _delete(BuildContext context, T item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(deleteDescription(nameOf(item))),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await onDelete(idOf(item));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(deletedMessage)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$linkedErrorMessage\n$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar os dados.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (values) => values.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(emptyMessage, textAlign: TextAlign.center),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: values.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = values[index];
                  final id = idOf(item);
                  return ListTile(
                    key: Key('$itemKeyPrefix$id'),
                    title: Text(nameOf(item)),
                    onTap: () => _openForm(context, item),
                    trailing: IconButton(
                      key: Key('$deleteKeyPrefix$id'),
                      tooltip: 'Excluir ${nameOf(item)}',
                      onPressed: () => _delete(context, item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        key: Key(addButtonKey),
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
