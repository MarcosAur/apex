# Banco de dados

`AppDatabase` agrega as tabelas `gyms`, `categories`, `muscle_groups`, `exercises`, `workouts`, `workout_exercises`, `exercise_logs`, `set_drafts`, `sleep_logs`, `meals`, `meal_items` e `water_intakes`. A conexão usa Drift/SQLite local (`apex_workout.sqlite`), com foreign keys ativas e seed idempotente.

Após alterar tabelas, incremente `schemaVersion`, implemente a migração e execute `dart run build_runner build --delete-conflicting-outputs`.

## Nível de esforço por série — versão 2

`exercise_logs.effort_level` armazena texto com restrição `CHECK` aos valores
`very_low`, `low`, `medium`, `high`, `failure_at_end` e `failure_before_end`.
O enum Dart `EffortLevel` fornece os rótulos Muito baixo, Baixo, Médio, Alto,
Falha ao final e Falha antes do final. Os códigos persistidos são explícitos e
independentes da ordem do enum; não devem ser renomeados sem migração.

A migração 1 → 2 adiciona a coluna sem apagar registros. Séries antigas ficam
com `NULL` (não informado). O banco permite esse valor para compatibilidade;
`WorkoutRepository.addLog` exige um `EffortLevel` para novas séries.
A seleção visual está integrada ao formulário de séries.

## Treinos e rascunhos — versão 3

- `workouts.status`: texto restrito a `legacy`, `active`, `completed`.
  O padrão `legacy` preserva o significado desconhecido de registros antigos;
  o repositório inicia novos treinos explicitamente como `active`.
- `workouts.completed_at`: data opcional, preenchida ao encerrar.
- Índice único parcial `one_active_workout`: no máximo um treino ativo.
- `set_drafts`: `workout_exercise_id` (PK/FK), `editing_log_id` (opcional),
  `weight_text`, `reps_text`, `effort_code` (opcional). Um rascunho por exercício,
  inclusive ao editar uma série. Textos incompletos são preservados como digitados.

As migrações 1 → 3 e 2 → 3 preservam dados e identificam treinos anteriores como
legados, sem atribuir uma data de encerramento fictícia. Podem ser retomados pelo
histórico se não houver outro ativo. O repositório serializa as gravações e usa
transações para confirmar séries, excluir exercícios e encerrar sessões.
Carga finita não negativa, repetições inteiras positivas e esforço são validados
ao confirmar a série. Exclusões renumeram as séries remanescentes.

Treinos encerrados são somente leitura no repositório e na interface.
Rascunhos precisam ser confirmados ou descartados antes do encerramento.
Cada alteração inicia gravação local; a interface indica quando foi concluída.
No navegador, a persistência depende de manter os dados do mesmo site/origem.

## Unidade de medida — versão 4

- `exercises.measurement_unit` e `workout_exercises.measurement_unit`: unidade (`kg` ou `km`), padrão `kg`.
- `exercise_logs.measurement_value`: carga em kg ou distância em km (renomeada da antiga coluna `weight`).
- `set_drafts.measurement_text`: texto rascunhado (renomeada da antiga coluna `weight_text`).

## Módulo Bem-estar — versão 5

- `sleep_logs`: `sleep_date` (data civil local em que se acorda, formato `YYYY-MM-DD`), `bed_time`, `wake_time` (ambos ou nenhum, com wake > bed), `duration_minutes` (1 a 1440 min), `notes`, `created_at`, `updated_at`. Índice em `sleep_date`.
- `meals`: `eaten_at`, `meal_type` (`breakfast`, `lunch`, `snack`, `dinner`, `supper`, `pre_workout`, `post_workout`, `other`), `notes`, `created_at`, `updated_at`. Índice em `eaten_at`.
- `meal_items`: `meal_id` (FK), `position` (inteiro >= 1), `name` (não vazio), `quantity_value` (positivo opcional), `quantity_unit` (`g`, `ml`, `unit` obrigatória se quantity_value existir). Chave única em `(meal_id, position)`.
- `water_intakes`: `consumed_at`, `amount_ml` (1 a 5000 ml), `created_at`, `updated_at`. Índice em `consumed_at`.

A migração para a versão 5 é cumulativa e preserva registros de treinos e configurações anteriores.
