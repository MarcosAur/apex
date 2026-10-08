# Registro de tarefas — Apex Workout

Fonte: [Project Definition Document](project_definition_document.md).

## Controle de execução

Versão atual: **1.0 concluída e validada pelo usuário em 14/09/2026**.
Estado do projeto: **Aguardando teste do usuário — Módulo Bem-estar**.
Entrega atual: **Módulo Bem-estar (tarefas 6.1 a 7.5)** — sono, refeições e água.

### Ícone Android do Apex Workout

Plano aprovado pelo usuário com “Aprovado”.
Estado: **Validada pelo usuário em 19/09/2026**.

Implementação:

- `assets/images/logo.jpeg` foi preservada como fonte original.
- O editor de imagens integrado gerou `assets/images/apex_launcher_icon.png`,
  removendo o quadriculado externo e usando fundo obsidiana.
- Os recursos `mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`,
  `mipmap-xxhdpi` e `mipmap-xxxhdpi` foram substituídos.
- O manifesto continua usando `@mipmap/ic_launcher`, agora apontando para os
  recursos atualizados.

Verificação:

- `flutter build apk --release`: concluído com sucesso.
- APK: `build/app/outputs/flutter-apk/app-release.apk` (58,3 MB).

Teste do usuário: instale o APK como atualização e confirme o novo ícone na
tela inicial. Se houver cache, remova e recrie o atalho ou reinicie o aparelho.

Correções atuais: **espaçamento do status de salvamento e exclusão do histórico**.
Plano aprovado pelo usuário com “Aplique”.
Estado: **Validada pelo usuário na conclusão da versão 1**.

Refatoração adicional aprovada: **nível de esforço em `exercise_logs`**.
Estado da refatoração: **Validada pelo usuário na conclusão da versão 1**.

Entrega atual: **fluxo integrado de treino (3.2, 4.1, 4.2 e consulta 5.1/5.2)**.
Plano aprovado pelo usuário com “Implemente”, após solicitar a integração antes
do teste das entregas anteriores. A aprovação não valida testes anteriores.
Estado: **Validada pelo usuário na conclusão da versão 1**.
Não iniciar novas tarefas antes da solicitação do usuário e da aprovação de novo plano.

| Tarefa | Entrega | Estado |
| --- | --- | --- |
| 1.1 | Estrutura Flutter e dependências | Validada pelo usuário |
| 1.2 | Tabelas e relacionamentos Drift | Validada pelo usuário |
| 1.3 | Conexão SQLite, migrações e dados iniciais | Validada pelo usuário |
| 2.1 | Cadastro de academias | Validada pelo usuário |
| 2.2 | Categorias e grupos musculares | Validada pelo usuário |
| 2.3 | Cadastro de exercícios | Validada pelo usuário |
| 3.1 | Tela inicial e tema Kinetic Obsidian | Validada pelo usuário |
| 3.2 | Criação e retomada de sessão de treino | Validada pelo usuário |
| 4.1 | Seleção de exercícios na sessão | Validada pelo usuário |
| 4.2 | Registro de séries, cargas, repetições e esforço | Validada pelo usuário |
| 5.1 | Histórico de treinos | Validada pelo usuário — consulta integrada |
| 5.2 | Detalhamento de treino | Validada pelo usuário — consulta integrada |
| 6.1 | Tabelas, enums e migração v5 de Bem-estar | Aguardando teste do usuário |
| 6.2 | Repositório reativo e regras de domínio de Bem-estar | Aguardando teste do usuário |
| 7.1 | Navegação no menu lateral e tela diária de Bem-estar | Aguardando teste do usuário |
| 7.2 | Formulário e registro de sono (horários e duração) | Aguardando teste do usuário |
| 7.3 | Formulário e registro de refeições e itens | Aguardando teste do usuário |
| 7.4 | Ingestão de água com atalhos e valor personalizado | Aguardando teste do usuário |
| 7.5 | Histórico de bem-estar com navegação para a data | Aguardando teste do usuário |

## Entrega integrada — Módulo Bem-estar (6.1–7.5)

Plano aprovado pelo usuário com “IMplementeIMplemente”.
Estado: **Aguardando teste do usuário**.

### Implementação entregue:

1. **Banco Drift e Migração v5:**
   - `sleep_logs`: `sleep_date`, `bed_time`, `wake_time`, `duration_minutes`, `notes`, `created_at`, `updated_at`.
   - `meals`: `eaten_at`, `meal_type` (8 categorias via enum `MealType`), `notes`, `created_at`, `updated_at`.
   - `meal_items`: `meal_id`, `position`, `name`, `quantity_value`, `quantity_unit` (g, ml, unit via `QuantityUnit`).
   - `water_intakes`: `consumed_at`, `amount_ml` (1 a 5000 ml), `created_at`, `updated_at`.
   - Índices em `sleep_date`, `eaten_at` e `consumed_at`.
   - Migração cumulativa em `AppDatabase` elevando para `schemaVersion = 5` e preservando treinos e academias anteriores.

2. **Camada de Repositório (`WellnessRepository`):**
   - Registro e edição de sono por horários (cálculo automático de duração e atribuição ao dia em que acorda) ou por duração direta.
   - Validação de sobreposição de horários de sono, limite de 24h por dia e rejeição de horários futuros.
   - Registro e edição de refeições apenas com horário, ou com tipo, observações e lista ordenada de itens com quantidade opcional. Exclusão transacional da refeição com seus itens.
   - Registro de água por atalhos rápidos ou volume personalizado.
   - `watchDay(DateTime)` reativo e `watchHistory()` ordenado por dia mais recente.

3. **Interface do Usuário (Tema Kinetic Obsidian):**
   - Menu lateral (`ApexNavigationDrawer`) atualizado com o destino **Bem-estar** e sincronização de tela.
   - Tela do dia (`WellnessScreen`) com seletor de data (anterior, próximo e botão "Hoje").
   - Três cartões de resumo com totais: Sono, Alimentação e Água.
   - Formulário de sono (`SleepFormScreen`) com alternância entre "Horários" e "Duração".
   - Formulário de refeição (`MealFormScreen`) com adição, exclusão e reordenação de itens de alimento.
   - Folha modal de água (`showWaterFormSheet`) e chips de registro rápido (+250 ml, +500 ml).
   - Tela de histórico (`WellnessHistoryScreen`) listando dias com resumo e permitindo voltar para o dia tocado.

### Verificações executadas:

- `flutter analyze lib`: **nenhum problema** (0 erros, 0 avisos).
- `flutter test test/features/wellness/`: **10 testes aprovados** (repositório + migração + interface completa).
- `flutter test test/core/database/`: **todos os testes do banco e migrações aprovados**.
- `flutter build web --wasm`: **concluído com sucesso**.

## Entrega integrada — treino, retomada e encerramento

### Correções após revisão visual

- O estado “Salvando…” / “Salvo no dispositivo” ganhou painel próprio, ícone,
  preenchimento interno e 24 px de separação antes do campo de academia.
- Cada item do histórico ganhou ação de exclusão com confirmação explícita.
- A exclusão transacional remove rascunhos, séries, exercícios da sessão e o
  treino escolhido. Academias, categorias, grupos musculares, exercícios do
  catálogo e demais treinos são preservados.
- É possível excluir treino ativo, encerrado ou legado. Ao apagar o ativo, a
  tela inicial volta a permitir iniciar uma sessão.
- Durante a exclusão, o item exibe progresso; sucesso e erro são informados.

Verificações das correções:

- `flutter analyze`: nenhum problema.
- `flutter test`: **46 testes aprovados**.
- Testes cobrem espaçamento mínimo, cancelamento, confirmação, remoção dos
  dependentes, preservação dos demais dados e ausência de referências órfãs.
- `flutter build web`: concluído com sucesso.

Roteiro de teste:

1. Execute `flutter run` e abra ou continue um treino.
2. Confira o painel de salvamento separado do campo “Academia (opcional)”.
3. Abra “Histórico” e toque na lixeira de um treino.
4. Cancele uma vez e confirme que o treino permanece.
5. Repita, confirme “Excluir” e confira a remoção e a mensagem de sucesso.
6. Para validar um treino ativo, crie um, volte à tela inicial, abra o histórico
   e exclua-o; confira que “Iniciar Exercício” fica disponível novamente.

Estado das correções: **Validada pelo usuário na conclusão da versão 1**.

Escopo aprovado: formulário com múltiplos exercícios e séries, academia e
observações opcionais, seis esforços, rascunhos duráveis, retomada de uma única
sessão ativa, encerramento confirmado e consulta posterior somente leitura.

Implementação:

- Seletor com busca, categoria/grupo muscular e acesso ao cadastro de exercícios.
- Séries com carga em kg (aceita vírgula), repetições inteiras positivas e esforço.
- Edição, exclusão com confirmação e renumeração; remoção do exercício com suas séries.
- Gravação local a cada alteração, fila de escritas e feedback de salvamento/erro.
- Rascunho por exercício, inclusive edição, persistindo textos ainda incompletos.
- Banco v3 com `status`, `completed_at`, `set_drafts` e índice de sessão ativa única.
- Migrações 1 → 3 e 2 → 3 preservam registros como legados, retomáveis explicitamente.
- Encerramento bloqueado por rascunhos; treinos encerrados protegidos pelo repositório.
- Tela inicial oferece continuar; histórico identifica ativos, encerrados e legados.

Verificações:

- `flutter analyze`: nenhum problema.
- `flutter test`: **45 testes aprovados**.
- `flutter build web`: compilação concluída, incluindo verificação de compatibilidade Wasm.
- Cobertura de migrações, seis esforços, dados e rascunhos após reabertura de arquivo,
  múltiplas séries/exercícios, validações, unicidade, encerramento e somente leitura.
- Testes de interface: formulário/retomada/histórico e tela de 320 × 640 com teclado.
- Falhas anteriores dos testes da home e do cadastro de exercícios corrigidas.

Roteiro de teste manual:

1. Encerre a execução anterior e execute `flutter run` novamente para abrir o banco v3.
2. Inicie o treino, selecione academia se desejar e preencha observações.
3. Adicione dois exercícios; se o catálogo estiver vazio, use “Gerenciar exercícios”.
4. Adicione várias séries com carga, repetições e esforço; confira edição e exclusão.
5. Deixe um rascunho incompleto. Aguarde “Salvo no dispositivo”, feche e reabra o app.
6. Use “Continuar treino”; confira séries, observações, academia e campos do rascunho.
7. Conclua ou descarte os rascunhos. Cancele uma confirmação de encerramento e depois confirme.
8. Confira o treino encerrado no histórico, sem ações de edição, e inicie um novo treino.
9. Se houver treino antigo, consulte o legado e retome-o quando não houver outro ativo.

No navegador, use a mesma origem e mantenha os dados do site; dados removidos pelo
navegador não são recuperados por este armazenamento local. Compilação Android/iOS
não foi executada nesta entrega.

Estado: **Validada pelo usuário na conclusão da versão 1**.

## Refatoração adicional — esforço por série

Plano aprovado com “Aprovado. Pode implementar”.

Entrega: enum `EffortLevel` com seis códigos textuais estáveis e rótulos em
português; coluna `exercise_logs.effort_level` com `CHECK`; migração 1 → 2
preservando séries antigas com `NULL`; esforço obrigatório em
`WorkoutRepository.addLog`. Código Drift regenerado e PDR/documentação atualizados.
A seleção na interface pertence à tarefa 4.2, conforme o plano aprovado.

Verificações:

- Testes novos aprovados em banco novo e banco legado v1: seis valores,
  rejeição de texto inválido, preservação de séries, versão 2 e reabertura.
- Suíte completa: 36 aprovados e 2 falhas de interface em
  `home_screen_test.dart` (espera mensagem antiga do CTA) e
  `exercises_screen_test.dart` (toque não alcança o botão e tela não abre).
- Análise: aviso de chaves ausentes em `home_screen.dart:59`, trecho não
  alterado nesta refatoração. Nenhum aviso nos arquivos alterados.

Teste do usuário:

```bash
flutter test test/core/database/effort_level_test.dart
flutter run
```

Esperado: os dois testes aprovados; aplicativo abre após a migração e mantém
os dados existentes. Ainda não há seletor de esforço na tela de séries.
Estado: **Validada pelo usuário na conclusão da versão 1**.

## Tarefa 1.1

Escopo aprovado: organização por funcionalidades, Riverpod na raiz, dependências
da camada de dados, tela provisória, documentação e registro do ciclo de aprovação.

Decisão de compatibilidade: usar `drift_flutter` com SQLite 3 em lugar de uma
dependência direta do `sqlite3_flutter_libs` descontinuado; referências no README.
O PDR foi preservado.

Verificações automáticas:

- Dependências resolvidas com sucesso (`flutter pub get`).
- Formatação validada (`dart format lib test`).
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: teste de inicialização aprovado (1 teste).

Implementação entregue: `ProviderScope`, `ApexApp`, tela provisória, diretórios
reservados, dependências e documentação. Banco, CRUD e tema definitivo permanecem
nas próximas tarefas. Builds de Android/iOS não foram executados nesta etapa.

Teste manual do usuário: aprovado com “Funcionando. Pode partir para próxima”.

## Tarefa 1.2

Plano aprovado com “Implemente”: sete tabelas do PDR, chaves e nulabilidade,
`AppDatabase` com executor injetado, geração Drift e testes em memória.

Arquivos: `lib/core/database/app_database.dart`, seu `.g.dart`, sete definições
em `lib/core/database/tables/` e `test/core/database/app_database_test.dart`.

Decisões:

- Esquema inicial na versão 1, sem campos ou restrições de negócio adicionais.
- IDs inteiros autoincrementais e apenas `gyms.location`, `workouts.gym_id`
  e `workouts.notes` opcionais, conforme o PDR.
- `PRAGMA foreign_keys = ON` na abertura garante a integridade das referências.
- Sem exclusão em cascata: referências existentes impedem a exclusão do registro pai.
- Conexão persistente, migrações de versão e dados iniciais ficam para a tarefa 1.3.
- Nenhuma integração do banco com a tela provisória nesta tarefa.

Verificações automáticas:

- `dart run build_runner build`: código Drift gerado com sucesso.
- `dart format lib/core/database test/core/database`: código formatado.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 13 testes aprovados (12 de banco e 1 de inicialização).
- Cobertura do banco: sete tabelas, treino completo com carga decimal e séries,
  campos opcionais, IDs autoincrementais, seis relacionamentos protegidos contra
  referências inválidas/exclusão de pais, inserção órfã e campos obrigatórios.

Teste do usuário: aprovado ao autorizar o avanço para a tarefa 1.3.

Roteiro para validação no terminal, na raiz do projeto:

```bash
/home/maurelio/develop/flutter/bin/flutter test test/core/database/app_database_test.dart
/home/maurelio/develop/flutter/bin/flutter analyze
```

Resultado esperado: todos os testes aprovados e análise sem problemas. Os testes
usam SQLite em memória e não criam banco persistente. A tela do aplicativo permanece
igual, pois a entrega desta tarefa é o esquema de dados.

Para regenerar o código após futuras alterações aprovadas nas tabelas:

```bash
/home/maurelio/develop/flutter/bin/dart run build_runner build
```

## Tarefa 1.3

Plano aprovado: conexão persistente, provider Riverpod com descarte, estratégia
de migração, dados iniciais idempotentes e testes de persistência e ciclo de vida.

Dados iniciais aprovados:

- Categorias: Push, Pull e Legs.
- Grupos musculares: Peitoral, Costas, Ombros, Bíceps, Tríceps, Quadríceps,
  Posteriores de coxa, Glúteos, Panturrilhas e Core.

Decisões:

- O arquivo de produção se chama `apex_workout.sqlite` e usa a área privada de
  documentos do aplicativo, definida pelo `drift_flutter`.
- Nomes de categorias e grupos musculares são únicos.
- O seed usa inserção com conflito ignorado e também roda ao abrir bancos
  existentes, permitindo repetição sem duplicação.
- Migrações futuras precisam ser implementadas explicitamente antes de aumentar
  `schemaVersion`; uma atualização desconhecida falha com mensagem clara.
- A interface aguarda a inicialização e apresenta erro caso o armazenamento local
  não possa ser preparado.

Verificações automáticas:

- `dart run build_runner build`: código Drift regenerado com sucesso.
- `dart format lib test`: código formatado.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 16 testes aprovados.
- Persistência validada em arquivo temporário com fechamento e reabertura.
- Seed validado após múltiplas execuções, sem duplicações.
- Chaves estrangeiras validadas após a reabertura.
- Instância única e fechamento do banco pelo container Riverpod validados.

Teste do usuário: pendente.

Correção durante o teste manual: a execução no Chrome revelou que a conexão não
informava os artefatos web exigidos pelo Drift. A conexão passou a fornecer
`DriftWebOptions`, usando `web/sqlite3.wasm` e `web/drift_worker.js` oficiais e
compatíveis com Drift 2.35.0.

Validação da correção:

- `flutter analyze`: nenhum problema.
- `flutter test`: 16 testes aprovados.
- `flutter build web`: concluído com sucesso.
- `flutter run -d chrome`: banco aberto com armazenamento Shared IndexedDB,
  aplicação iniciada e nenhum `ProviderException` registrado.

Roteiro para validação:

1. Execute `flutter run`, aguarde a tela “Apex Workout” e encerre o aplicativo.
2. Execute novamente e confirme que a tela abre sem mensagem de erro.
3. Opcionalmente, rode:

```bash
/home/maurelio/develop/flutter/bin/flutter test test/core/database/database_persistence_test.dart
```

Resultado esperado: `All tests passed!`. Ao abrir o aplicativo, o arquivo
`apex_workout.sqlite` é criado na área privada de documentos da plataforma.

Teste do usuário: aprovado com “Prossiga” após a correção da configuração web.

## Tarefa 2.1

Plano aprovado com “Implemente”: repositório Drift, providers reativos, listagem,
formulário de cadastro e edição, exclusão confirmada e acesso provisório pela home.

Decisões:

- Academias são exibidas por nome e observadas por stream do Drift.
- Nome é obrigatório e normalizado; localização vazia é armazenada como nula.
- Toque no item abre a edição; o botão de lixeira pede confirmação.
- A integridade referencial impede remover academias vinculadas a treinos.
- O botão “Gerenciar academias” é provisório até a tela inicial da tarefa 3.1.

Verificações automáticas:

- `dart format lib test`: código formatado.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 20 testes aprovados.
- Repositório validado para cadastro, normalização, ordem, edição e exclusão.
- Exclusão de academia vinculada a treino rejeitada pelo banco.
- Interface validada no fluxo completo, incluindo nome obrigatório, localização
  opcional, cadastro, edição, confirmação e exclusão.

Teste do usuário: pendente.

Roteiro para validação:

1. Abra o aplicativo e toque em “Gerenciar academias”.
2. Confira o estado vazio e toque em “+”.
3. Tente cadastrar sem nome e confira a validação.
4. Cadastre uma academia com nome e localização.
5. Toque na academia, altere os dados e salve.
6. Feche e abra o aplicativo para confirmar a persistência.
7. Use a lixeira, cancele uma vez e depois confirme a exclusão.

Resultado esperado: todas as alterações aparecem imediatamente e permanecem após
reiniciar o aplicativo.

Teste do usuário: aprovado com “Prossiga”.

## Tarefa 2.2

Plano aprovado com “Sim”: CRUD reativo de categorias e grupos musculares,
tratamento de duplicações, proteção de vínculos e acessos provisórios pela home.

Implementação: repositórios e providers separados por entidade, com componentes
compartilhados de formulário e listagem para manter comportamento consistente.

Verificações automáticas:

- `dart format lib test`: código formatado.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 26 testes aprovados.
- Repositórios validados para seed, normalização, cadastro, edição, exclusão,
  nome vazio e duplicação.
- Interfaces validadas no fluxo completo dos dois módulos.
- Mensagem amigável de categoria duplicada validada na interface.
- Restrições de chave estrangeira já cobertas pela suíte do banco impedem a
  exclusão de entidades vinculadas a exercícios.

Teste do usuário: pendente.

Roteiro para validação:

1. Abra “Gerenciar categorias” e confira Push, Pull e Legs.
2. Tente adicionar Push novamente e confira a mensagem de duplicação.
3. Cadastre, edite e exclua uma categoria nova.
4. Abra “Gerenciar grupos musculares” e confira os dez registros iniciais.
5. Cadastre, edite e exclua um grupo muscular novo.
6. Reinicie o aplicativo e confirme a persistência dos registros mantidos.

Teste do usuário: avanço autorizado ao solicitar a conclusão de todos os CRUDs.

## Tarefa 2.3

Plano aprovado ao solicitar todos os CRUDs: repositório e listagem relacional,
formulário com seletores obrigatórios, exclusão protegida e acesso pela home.

Verificações automáticas:

- `dart format lib test`: código formatado.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 30 testes aprovados.
- Repositório validado para consulta relacional, cadastro, edição e exclusão.
- Nome obrigatório e referências inexistentes foram rejeitados.
- Exercício vinculado a treino não pode ser excluído.
- Interface validada com seletores obrigatórios, exibição de categoria e grupo
  muscular, edição e exclusão.

Teste do usuário: pendente.

Roteiro para validação:

1. Confira que os quatro acessos de gerenciamento aparecem na tela inicial.
2. Abra “Gerenciar exercícios” e tente salvar o formulário vazio.
3. Cadastre um exercício escolhendo categoria e grupo muscular.
4. Confira os dois nomes abaixo do exercício na listagem.
5. Edite nome, categoria e grupo muscular.
6. Reinicie o aplicativo e confirme a persistência.
7. Exclua o exercício e confirme que ele desaparece.

Com esta entrega, as tarefas 2.1, 2.2 e 2.3 completam os CRUDs de academias,
categorias, grupos musculares e exercícios.

Teste do usuário: avanço autorizado com “proxima”.

## Tarefa 3.1

Plano aprovado com “implente”: tokens Kinetic Obsidian, fontes locais, tema
global, saudação por horário, CTA de 56 px e atalhos responsivos para os CRUDs.

As fontes Space Grotesk e Plus Jakarta Sans e suas licenças OFL foram obtidas do
repositório oficial Google Fonts e incorporadas em `assets/fonts/`.

O CTA permanece informativo; criação e navegação da sessão ficam na tarefa 3.2.

Verificações automáticas:

- `dart format lib test`: código formatado.
- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 36 testes aprovados.
- Saudações validadas às 6h, 12h e 18h.
- CTA validado com 56 px, cor neon e comportamento informativo.
- Layout validado em largura de 320 px sem overflow.
- `flutter build web`: concluído, incluindo fontes e assets.
- `flutter run -d chrome`: inicialização real concluída sem erros.

Teste do usuário: pendente.

Roteiro para validação:

1. Abra o aplicativo e confira a saudação correspondente ao horário local.
2. Confira fundo obsidiana, tipografia, superfícies e destaques verdes.
3. Toque em “Iniciar Exercício” e confira a mensagem informativa.
4. Abra os quatro atalhos de gerenciamento e volte à home.
5. Redimensione a janela do navegador e confirme que os cartões se adaptam.

## Modelo para as próximas tarefas

- Identificador e objetivo do PDR.
- Estado e aprovação explícita do plano.
- Escopo e arquivos previstos.
- Critérios de conclusão e verificações previstas.
- Resultado da implementação e verificações executadas.
- Roteiro de teste manual.
- Resultado informado pelo usuário e eventuais correções.

## Questão para o planejamento futuro

A tarefa 5.1 menciona sessões concluídas, mas o esquema não define estado ou data
de conclusão. Resolver esse ponto no plano do fluxo de sessões, antes de implementar
uma distinção entre treino ativo e concluído.

## Execução das tarefas restantes (3.2–5.2)

Implementação inicial concluída em conjunto: criação de sessão pelo CTA, tela de treino ativo, repositório para exercícios e séries, e histórico navegável.

Verificações: `flutter analyze` sem erros (apenas 1 aviso de estilo); `flutter test` executado. Dois testes legados precisam ser atualizados porque validavam o CTA provisório e um fluxo anterior de exercícios.

Teste manual pendente do usuário.
