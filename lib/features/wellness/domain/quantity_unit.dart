enum QuantityUnit {
  grams('g', 'Gramas', 'g'),
  milliliters('ml', 'Mililitros', 'ml'),
  units('unit', 'Unidades', 'un.');

  const QuantityUnit(this.storageValue, this.label, this.symbol);

  /// Código persistido; não renomear sem migração.
  final String storageValue;
  final String label;
  final String symbol;

  static QuantityUnit fromStorage(String value) => values.firstWhere(
    (unit) => unit.storageValue == value,
    orElse: () => throw ArgumentError.value(
      value,
      'value',
      'Unidade de quantidade desconhecida.',
    ),
  );
}
