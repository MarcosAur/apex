# Apex Workout

Aplicativo de acompanhamento de treinos, com foco em Android e iOS e operação local.
Requisitos: [definição do projeto](docs/project_definition_document.md).
Progresso e aprovações: [registro de tarefas](docs/task_tracker.md).

## Ambiente e execução

SDK usado nesta etapa: Flutter 3.47.4 / Dart 3.13.3.
Nesta máquina, o SDK está em `/home/maurelio/develop/flutter`.
Caso o comando não esteja disponível, configure o terminal atual:

```bash
export PATH="/home/maurelio/develop/flutter/bin:$PATH"
```

Na raiz do projeto:

```bash
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
```

Substitua `<id-do-dispositivo>` por um identificador listado pelo comando anterior.
Android requer SDK e emulador ou aparelho; iOS requer macOS e Xcode.
As pastas das demais plataformas vieram do template, mas não representam
validação de suporte completo ao produto.
Para conferir o ambiente, execute `flutter doctor -v`.

## Organização

```text
lib/
  main.dart              # Inicialização e ProviderScope
  app/                   # Configuração do aplicativo
  core/
    database/            # Drift/SQLite, tabelas e migrações (versão 3)
    theme/               # Tema Kinetic Obsidian
    widgets/             # Componentes compartilhados
  features/
    home/presentation/   # Tela inicial e retomada do treino
    gyms/
    categories/
    muscle_groups/
    exercises/
    workouts/
    history/
```

Cada funcionalidade organiza repositórios em `data/`, estado em `providers/` e
telas/componentes em `presentation/`. Os níveis de esforço ficam em `workouts/domain/`.

## Dependências

- `flutter_riverpod`: estado e injeção de dependências; `ProviderScope` instalado na raiz.
- `drift`, `drift_flutter` e `path_provider`: preparação da persistência local.
- `drift_dev` e `build_runner`: geração de código do banco nas próximas tarefas.

O PDR menciona `sqlite3_flutter_libs`, mas esse pacote foi descontinuado e sua
versão 0.6 não tem efeito. Usamos a integração atual `drift_flutter`, com SQLite
3 transitivo, conforme a [configuração oficial do Drift](https://drift.simonbinder.eu/setup/)
e o [aviso do pacote](https://pub.dev/packages/sqlite3_flutter_libs).
O pacote antigo ainda pode aparecer transitivamente no lockfile, sem configuração direta.
As versões resolvidas estão em `pubspec.lock`. Dados e rascunhos de treino são
persistidos localmente no SQLite.

No navegador, `web/sqlite3.wasm` e `web/drift_worker.js` fornecem o SQLite e o
worker exigidos pelo Drift. Esses arquivos devem acompanhar qualquer publicação web.

## Documentação adicional

- [Arquitetura](docs/architecture.md)
- [Banco de dados](docs/database.md)
- [Guia de desenvolvimento](docs/development.md)

```bash
flutter analyze
flutter test
```

Execute o aplicativo, toque em “Iniciar Exercício”, adicione exercícios e registre
séries com carga, repetições e esforço. Academia e observações são opcionais.
Os campos em preenchimento são salvos como rascunhos; aguarde a indicação
“Salvo no dispositivo” e reabra o app para conferir “Continuar treino”.
Conclua ou descarte os rascunhos e use “Encerrar treino” para finalizar.
O histórico permite consultar sessões encerradas e retomar registros legados.
Após mudanças no esquema, encerre a execução anterior e inicie novamente.

## Ciclo de aprovação

Cada tarefa segue: plano sem alterações → aprovação → implementação e verificações
→ teste do usuário → confirmação → plano da próxima tarefa.
As regras para continuar o trabalho estão em `AGENTS.md`.
