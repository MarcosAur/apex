enum MealType {
  breakfast('breakfast', 'Café da manhã'),
  lunch('lunch', 'Almoço'),
  snack('snack', 'Lanche'),
  dinner('dinner', 'Jantar'),
  supper('supper', 'Ceia'),
  preWorkout('pre_workout', 'Pré-treino'),
  postWorkout('post_workout', 'Pós-treino'),
  other('other', 'Outra');

  const MealType(this.storageValue, this.label);

  /// Código persistido; não renomear sem migração.
  final String storageValue;
  final String label;

  static MealType fromStorage(String value) => values.firstWhere(
    (type) => type.storageValue == value,
    orElse: () => throw ArgumentError.value(
      value,
      'value',
      'Tipo de refeição desconhecido.',
    ),
  );
}
