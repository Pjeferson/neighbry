# RALPH.md — Harness de implementação autônoma via OpenSpec

Este documento é o prompt de entrada de um loop autônomo (execução repetida,
sem humano no meio confirmando cada passo). Cada invocação começa sem
memória da invocação anterior — todo o estado que importa vive no
repositório (git, arquivos `tasks.md`, diretórios de `openspec/`), nunca na
sua "lembrança" da conversa. Leia este documento por completo antes de agir.

Este documento é genérico — não assume qual bounded context, camada
(frontend/backend) ou tipo de trabalho está sendo implementado. As changes
específicas dizem isso; este documento só descreve o *processo*.

As convenções gerais do projeto (stack, comandos, estilo de código, formato
de commit) estão em `CLAUDE.md` — leia-o também. Este documento cobre o que
`CLAUDE.md` não cobre: como operar em loop autônomo, sem parar pra perguntar.

## 1. Objetivo desta execução

Implementar, uma de cada vez, todas as changes OpenSpec que estão **abertas**
(existem em `openspec/changes/<nome>/`, ainda não movidas para
`openspec/changes/archive/`) e que já têm os 4 artifacts completos
(`proposal.md`, `design.md`, `specs/`, `tasks.md`) — ou seja, changes já
propostas e commitadas, prontas pra implementação. Você não cria novas
changes nem edita `proposal.md`/`design.md`/`specs/` de forma especulativa
— isso já foi decidido antes deste loop começar.

A ordem de implementação está definida em `openspec/project.md`, numa seção
dedicada (ver seção 2 abaixo). Siga essa ordem à risca — não escolha por
conta própria qual change parece "mais fácil" ou "mais importante".

## 2. Como descobrir o que fazer a seguir

1. Leia `openspec/project.md` e localize a seção "Ordem de implementação
   (Ralph loop)" (ou nome equivalente marcado pelo usuário). Ela é uma
   lista simples, cada item é o **nome exato do diretório da change**
   (ex: `frontend-common-area-dashboard`), sem descrição adicional.
2. Para cada nome, nessa ordem, verifique se já existe
   `openspec/changes/archive/*-<nome>/` (glob por data). Se existe, essa
   change já foi implementada e arquivada — pule para a próxima da lista.
3. A primeira da lista que **não** tiver pasta correspondente em
   `archive/` é a change atual. Rode
   `openspec status --change "<nome>" --json` pra confirmar que os 4
   artifacts estão `done` (se não estiverem, essa change não deveria estar
   na lista ainda — pare e registre isso como bloqueio, ver seção 6).
4. Se **todas** as changes da lista já estão arquivadas, não há mais
   trabalho — ver seção 7.

Nunca edite a lista de ordem em `project.md`. Ela é escrita uma vez pelo
humano antes do loop rodar; o loop só lê. "O que já foi feito" é sempre
determinado pela existência da pasta em `archive/`, nunca por marcar algo
na lista.

## 3. Ciclo de trabalho de uma change

Para a change atual (identificada no passo anterior), repita este ciclo:

### 3.1 Orientar-se

- `git status` — nunca assuma o estado do working tree, confira.
- Leia `proposal.md`, `design.md`, `specs/**/*.md` e `tasks.md` da change
  por completo. Não pule design.md — as decisões e o *porquê* delas estão
  lá, e implementar sem lê-las já causou retrabalho em execuções manuais
  anteriores deste projeto.
- `openspec status --change "<nome>" --json` — confirme progresso atual
  (quantas tasks já estão `[x]`). Uma execução anterior do loop pode ter
  parado no meio — resuma dali, não reinicie do zero.

### 3.2 Implementar por grupo de tarefas

`tasks.md` é organizado em grupos numerados (`## 1. ...`, `## 2. ...`).
Trate cada grupo como a unidade de trabalho:

1. Implemente todas as tarefas `- [ ]` de um grupo.
2. Rode a suíte de testes relevante **por completo** (não só os testes
   novos — regressão importa tanto quanto a feature nova).
3. Rode type-check/lint quando aplicável à stack em questão.
4. Só marque as tarefas do grupo como `- [x]` depois que o código E os
   testes desse grupo estiverem verdes. Nunca marque antes, nunca marque
   "porque devia funcionar".
5. Corrija permissão de arquivo se algum comando rodou em container
   (`docker compose run` cria arquivos como root — ver CLAUDE.md).
6. Faça um commit cobrindo esse grupo, seguindo o formato de
   `CLAUDE.md` (`<tipo>: TASK-N — <descrição em português>`). Grupos
   pequenos e diretamente relacionados podem compartilhar um commit
   (ex: "TASK-1/2"), mas nunca deixe trabalho sem commit ao fim do turno.
7. Passe para o próximo grupo.

Se, implementando um grupo, você descobrir um bug ou lacuna que não estava
prevista em `tasks.md` (isso já aconteceu várias vezes em execuções
manuais deste projeto — CORS mal configurado, variável de ambiente
conflitando, bug de UX real) — corrija, mas documente claramente no commit
e num resumo ao final *por que* esse arquivo "fora do escopo aparente" mudou.
Não ignore o problema silenciosamente, e não pare o loop por causa disso
a não ser que seja genuinamente ambíguo (ver seção 6).

### 3.3 Grupo de validação final

O último grupo de `tasks.md` de toda change deste projeto é validação
E2E/integração (curl, testes manuais documentados, etc). Esse grupo **não
é opcional e não é dispensável** — é o portão antes de arquivar. Não
arquive uma change com esse grupo incompleto ou pulado.

### 3.4 Arquivar

Quando todas as tarefas de `tasks.md` estiverem `[x]` e a validação final
tiver passado:

1. `openspec validate <nome> --strict` — confirme que a change ainda é
   válida.
2. Se a change tem delta specs (`specs/<capability>/spec.md` dentro da
   change), sincronize com as specs principais em
   `openspec/specs/<capability>/spec.md`: para cada requirement
   `ADDED`, adicione; para `MODIFIED`, substitua o bloco inteiro pelo
   conteúdo novo; para `REMOVED`, remova; para `RENAMED`, renomeie. Não
   pule este passo — é fácil esquecer e a spec principal fica
   desatualizada silenciosamente.
3. Mova o diretório da change para
   `openspec/changes/archive/YYYY-MM-DD-<nome>/` (data de hoje).
4. Commit separado: `chore: arquiva change <nome>`.
5. Volte ao passo 2 desta seção (seção 2) pra descobrir a próxima change.

## 4. Convenções obrigatórias (reforço do CLAUDE.md)

- Toda tarefa/grupo tem teste correspondente rodado e verde antes de
  marcar `[x]` ou commitar.
- Checkboxes de `tasks.md` são atualizados em tempo real, grupo a grupo —
  nunca em lote no final.
- Commits são atômicos por grupo (ou por pequeno conjunto de grupos
  relacionados), nunca um único commit gigante ao final da change inteira.
- Nunca `--no-verify`, nunca pular hook, nunca force-push.
- Nunca `git reset --hard`/`checkout .`/`clean -f` sem stash prévio — se
  encontrar estado inesperado no working tree ao começar, pare e registre
  como bloqueio em vez de descartar.

## 5. Diferenças em relação a uma sessão manual

Numa sessão manual deste projeto, cada grupo de tarefas era confirmado por
um humano antes de avançar pro próximo. Em loop autônomo, **não há essa
pausa** — continue de grupo em grupo, de change em change, até:

- esgotar a lista de changes da seção 2, ou
- encontrar um bloqueio real (seção 6), ou
- o turno atual da execução terminar naturalmente (o harness externo vai
  te invocar de novo; ao retomar, comece pela seção 3.1 de orientação —
  não assuma que está no mesmo ponto que "lembra").

Não peça confirmação ao usuário — não há ninguém pra responder. Tome a
decisão mais alinhada com `design.md`/`proposal.md` da change e siga.
Exceção: decisões que a própria change deixou como "Open Questions" não
resolvidas — isso é sinal de que a change não devia estar pronta pra
implementação (ver seção 6).

## 6. Quando parar e como sinalizar bloqueio

Pare de processar a change atual (não pule silenciosamente pra próxima)
quando:

- Um teste falha e **duas tentativas de correção** não resolvem — não
  insista numa terceira tentativa às cegas.
- `design.md` tem uma "Open Question" não resolvida que afeta a tarefa
  atual.
- A tarefa exige uma decisão de produto/UX que não está coberta por
  nenhum artifact da change (ex: texto de erro específico não
  especificado, comportamento visual não decidido).
- O working tree tem alterações não commitadas que não foram feitas por
  você nesta execução (trabalho de outra sessão/humano em andamento).

Ao parar: **não** deixe a change pela metade sem rastro. Crie ou atualize
`openspec/changes/<nome>/BLOCKED.md` com: em qual grupo/tarefa parou, o
que foi tentado, por que não avançou. Faça commit dessa nota. Isso permite
que a próxima invocação do loop (ou um humano) retome com contexto, em vez
de re-descobrir o mesmo bloqueio do zero.

## 7. Quando todo o trabalho da lista estiver arquivado

Confirme rodando `openspec list --json` (não deve sobrar nenhuma change
ativa correspondente à lista) e `git status` (working tree limpo). Não
invente trabalho novo, não comece a especular sobre próximas changes. Se
tudo bate, encerre o turno relatando o resumo do que foi implementado
nesta execução — o loop externo decide se continua rodando (idle) ou para.
