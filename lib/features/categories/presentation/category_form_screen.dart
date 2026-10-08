import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/named_entity_form_screen.dart';
import '../providers/category_providers.dart';

class CategoryFormScreen extends ConsumerWidget {
  const CategoryFormScreen({super.key, this.category});
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NamedEntityFormScreen(
      title: category == null ? 'Nova categoria' : 'Editar categoria',
      entityName: 'uma categoria',
      fieldKey: 'categoryNameField',
      saveButtonKey: 'saveCategoryButton',
      initialName: category?.name,
      onSave: (name) => category == null
          ? ref.read(categoryRepositoryProvider).create(name).then((_) {})
          : ref.read(categoryRepositoryProvider).update(category!.id, name),
    );
  }
}
