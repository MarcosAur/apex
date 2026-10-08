# Arquitetura

O `ProviderScope` inicia o app; `ApexApp` inicializa o banco e aplica o tema. Cada feature separa `data`, `providers` e `presentation`. Telas consomem providers, e repositórios encapsulam Drift. O fluxo é: sessão → exercícios → séries → histórico.

`workouts/domain` contém os níveis de esforço. `WorkoutRepository` controla
o ciclo de vida da sessão e serializa as escritas em transações SQLite.
Os providers observam a sessão ativa e seu detalhamento. A tela inicial oferece
iniciar ou continuar; a tela de treino permite edição somente enquanto ativa.
`SetDraftForm` mantém os controladores de texto e persiste alterações em
`set_drafts`, recuperando valores incompletos após reabertura.
O histórico reutiliza o detalhamento em modo de consulta para treinos encerrados
e permite retomar legados. O banco é a fonte do estado durável; Riverpod conecta
as atualizações às telas.
