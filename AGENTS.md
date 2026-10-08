# Fluxo de trabalho do Apex Workout

- Use `docs/project_definition_document.md` como fonte dos requisitos e da ordem das tarefas.
- Consulte `docs/task_tracker.md` para identificar a tarefa atual e o estado da aprovação.
- Antes de cada tarefa, inspecione sem alterar arquivos e apresente no terminal/conversa o plano: escopo, arquivos previstos e critérios de conclusão.
- Pare e aguarde aprovação explícita do usuário antes de implementar a tarefa.
- Implemente somente a tarefa aprovada e execute as verificações pertinentes.
- Ao terminar, atualize o registro para “Aguardando teste do usuário”, apresente os resultados e as instruções de teste e pare.
- Aguarde a confirmação do usuário sobre os testes. Corrija problemas da tarefa atual antes de avançar.
- Somente após essa confirmação apresente o plano da próxima tarefa, que exige nova aprovação.
- Não interprete aprovação da implementação como aprovação dos testes ou de tarefas futuras.
- Organize funcionalidades em `lib/features/`, recursos compartilhados em `lib/core/` e configuração do aplicativo em `lib/app/`.
- Mantenha os fluxos principais locais, com Riverpod para estado e Drift/SQLite para persistência.
