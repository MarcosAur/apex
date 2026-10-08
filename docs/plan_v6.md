# Planejamento das Novas Funcionalidades (Treinos)

**Estado:** Aguardando aprovação.

## 1. Duração para exercícios de corrida (ou de distância)
**Objetivo:** Permitir o registro de duração quando o exercício utiliza a unidade "Quilômetros".
- **Banco de Dados (Migração v6):**
  - Tabela `exercise_logs`: adicionar coluna `duration_seconds` (inteiro nulo).
  - Tabela `set_drafts`: adicionar coluna `duration_text` (texto, padrão vazio).
- **Repositório (`WorkoutRepository`):**
  - Atualizar os métodos `beginDraft`, `updateDraft`, `commitDraft` para trafegar e persistir a duração. O texto livre digitado pelo usuário (ex.: `12:30` para 12 min e 30 seg, ou `1:20:00` para 1 hora e 20 min) será convertido para segundos ao confirmar a série.
- **Interface:**
  - Em `SetDraftForm`, caso `measurementUnit` seja de distância (`requiresUserReps == false`), exibir um novo campo `Duração (opcional, ex: 15:30)`.
  - Na lista de séries (logs) do exercício, exibir a duração logo após a distância.

## 2. Avaliação de desempenho ao finalizar o treino
**Objetivo:** Capturar um feedback de desempenho estruturado ao término da sessão.
- **Banco de Dados:**
  - Tabela `workouts`: adicionar coluna `evaluation` (texto nulo).
- **Interface (`ActiveWorkoutScreen`):**
  - Ao tocar em "Encerrar treino", em vez de exibir a confirmação genérica atual, abrir um modal: "Avaliação do treino - Deseja avaliar o desempenho deste treino?" com as opções [Não] e [Sim].
  - Se o usuário escolher [Sim], abrir outro modal com um campo de texto longo para escrever a avaliação.
  - Se escolher [Não], encerrar diretamente.
  - Após preencher a avaliação e salvar, gravar na nova coluna `evaluation` e fechar a sessão.
  - A avaliação também passará a ser exibida como leitura no histórico.

## 3. Data retroativa, título do treino e formatação do histórico
**Objetivo:** Flexibilidade de datas (treinos passados), nomear os treinos e visualizar isso claramente.
- **Banco de Dados:**
  - Tabela `workouts`: adicionar coluna `title` (texto nulo).
- **Repositório:**
  - `updateDetails` passará a aceitar `title` e `performedAt`.
- **Interface:**
  - Em `ActiveWorkoutScreen`, permitir a edição da data/hora de início tocando no texto "Início: ...". Abrirá seletores de data e hora.
  - Adicionar um campo de texto "Título do treino (opcional)" logo abaixo de onde se exibe o status no topo.
  - Em `WorkoutHistoryScreen` (Histórico de treinos), o cabeçalho do item deixará de mostrar apenas data/hora e passará a usar o formato: `[Título ou "Treino"] - DD/MM/YYYY - [Dia da Semana]`.

### Ordem de Execução Recomendada:
1. **Migração v6:** Adição de `duration_seconds`, `duration_text`, `evaluation` e `title`.
2. **Atualização do Repositório:** Validações, parser de tempo de duração e os novos parâmetros.
3. **Formulário de Rascunho (Séries):** Entrada de duração para corridas/distância.
4. **Detalhes do Treino:** Edição de título e data retroativa no topo de `ActiveWorkoutScreen`.
5. **Avaliação ao Encerrar:** Os novos modais de fechamento de sessão.
6. **Histórico e Exportação:** Atualização das views de histórico para exibir os novos dados.