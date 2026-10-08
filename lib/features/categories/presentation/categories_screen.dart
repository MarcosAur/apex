import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/named_entities_screen.dart';
import '../providers/category_providers.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NamedEntitiesScreen(
      title: 'Categorias',
      items: ref.watch(categoriesProvider),
      idOf: (category) => category.id,
      nameOf: (category) => category.name,
      formBuilder: (category) => CategoryFormScreen(category: category),
      onDelete: ref.read(categoryRepositoryProvider).delete,
      emptyMessage: 'Nenhuma categoria cadastrada.',
      addButtonKey: 'addCategoryButton',
      itemKeyPrefix: 'categoryTile_',
      deleteKeyPrefix: 'deleteCategory_',
      deleteTitle: 'Excluir categoria?',
      deleteDescription: (name) =>
          'A categoria “$name” será removida permanentemente.',
      createdMessage: 'Categoria cadastrada.',
      updatedMessage: 'Categoria atualizada.',
      deletedMessage: 'Categoria excluída.',
      linkedErrorMessage: 'Não foi possível excluir. A categoria pode estar vinculada a um exercício.',
    );
  }
}
