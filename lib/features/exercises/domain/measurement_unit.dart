enum MeasurementUnit {
  kilograms('kg', 'Quilogramas', 'Carga'),
  kilometers('km', 'Quilômetros', 'Distância');

  const MeasurementUnit(this.storageValue, this.label, this.fieldLabel);

  final String storageValue;
  final String label;
  final String fieldLabel;

  String get symbol => storageValue;

  bool get requiresUserReps => this == MeasurementUnit.kilograms;

  static MeasurementUnit fromStorage(String value) => values.firstWhere(
    (unit) => unit.storageValue == value,
    orElse: () => throw ArgumentError.value(
      value,
      'value',
      'Unidade de medida desconhecida.',
    ),
  );
}
