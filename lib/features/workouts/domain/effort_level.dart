enum EffortLevel {
  veryLow('very_low', 'Muito baixo'),
  low('low', 'Baixo'),
  medium('medium', 'Médio'),
  high('high', 'Alto'),
  failureAtEnd('failure_at_end', 'Falha ao final'),
  failureBeforeEnd('failure_before_end', 'Falha antes do final');

  const EffortLevel(this.storageValue, this.label);
  final String storageValue;
  final String label;
}
