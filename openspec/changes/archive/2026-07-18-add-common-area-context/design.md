## Context

`Tenancy`, `Registry`, `Billing` e `Notice` já estão implementados e arquivados. `CommonArea` é o mais simples dos cinco: nenhuma leitura cross-context além da checagem de admin já padronizada (`AdminCheckable`, replicada em cada bounded context desde `Registry`). `project.md` descreve `CommonArea` numa única linha — "Cadastro de espaços comuns (reservas ficam para v2)" — sem aggregate nem invariante pré-esboçados, então todo o modelo abaixo veio inteiramente da exploração desta change.

## Goals / Non-Goals

**Goals:**
- Prover um catálogo editável de espaços comuns, com informação suficiente (capacidade, horário, regras) pra ser útil mesmo sem sistema de reservas.
- Manter o cadastro deliberadamente enxuto — resistir à tentação de antecipar campos que só fazem sentido quando reservas existirem.

**Non-Goals:**
- Sistema de reservas/agenda — fica para um bounded context futuro (`Reservation`, nome candidato), que leria `CommonArea` como Open Host Service, no mesmo padrão que `Billing` já lê `Registry::Occupancy`.
- `taxa_de_uso` — sem reserva, não há como cobrar de ninguém por usar o espaço; um preço "solto" sem mecanismo de cobrança é especulativo.
- `requer_aprovacao` — só faz sentido dentro de um fluxo de pedido/reserva, que não existe nesta v1.
- `tipo`/categoria — sem necessidade de filtrar/agrupar ainda; poucos espaços comuns não justificam taxonomia.
- Upload de fotos — exigiria infraestrutura de upload que o projeto não tem.
- Imutabilidade — diferente de `Taxa`/`Aviso`, não há histórico financeiro nem confirmação de leitura vinculada a uma versão específica do registro.

## Decisions

### CommonArea é recurso do condomínio, sem vínculo com Building
Diferente de `Unit` (que pertence a uma `Building`), um espaço comum é do condomínio inteiro — mesmo quando fisicamente fica "no bloco A", o sistema não precisa modelar essa relação, porque nada no domínio depende dela nesta v1 (sem reserva por torre, sem regra de acesso por torre). `condominium_id` denormalizado é suficiente.

### Campos informativos sem depender de reserva
`horario_funcionamento` e `regras_uso` (ambos texto livre) foram incluídos porque são úteis independente de existir agendamento — um morador quer saber "posso usar agora?" e "quais as regras" mesmo sem marcar hora. Todos os campos especulativos sobre reserva (`taxa_de_uso`, `requer_aprovacao`, `tipo`, fotos) ficam documentados como backlog explícito de um futuro bounded context `Reservation`, não como campos "desligados" dentro de `CommonArea`.

### Sem imutabilidade — edição livre pelo admin
`Taxa` e `Aviso` são imutáveis porque proteger histórico (Cobrança referenciando um valor específico; confirmação de leitura de uma versão específica do conteúdo) importa nesses casos. `CommonArea` não tem essa pressão — é dado de referência puro, mais parecido com `Building`/`Unit` (também livremente editáveis em `Registry`) do que com `Taxa`/`Aviso`. Corrigir um erro de cadastro é só uma edição normal.

### ativo: false significa indisponível, não oculto
Diferente de `Aviso` (onde desativar apaga um erro de conteúdo e o registro some da visão de quem recebeu), `ativo` em `CommonArea` representa disponibilidade — um espaço em reforma continua existindo e sendo relevante pro morador saber que está temporariamente fechado. Por isso a listagem SHALL continuar retornando `CommonArea` com `ativo: false`, apenas com o status visível, em vez de ocultá-las. Decisão tomada durante a formalização da proposta (não foi explicitamente perguntada na exploração) — sinalizando aqui para revisão, caso a intenção fosse outra.

### Reservation como bounded context separado (decisão registrada, não implementada)
Quando reservas existirem, `Reservation` deve ser um bounded context próprio, não uma extensão de `CommonArea` — mesmo critério que já separou `Registry` (estrutura, baixa volatilidade) de `Billing` (processo, alta volatilidade): reserva envolve concorrência (já citada no backlog do `project.md` como "bom caso pra lock otimista"), calendário/disponibilidade, e potencialmente integração com `Billing` (cobrança) e `Access` (liberação condicionada a reserva válida). Manter `CommonArea` como catálogo estável agora evita precisar desfazer acoplamento depois.

### Visibilidade aberta, cadastro restrito
Cadastro e edição exigem `Tenancy::Membership(role: admin)`, mesmo padrão de `Building`/`Unit`/`Taxa`. Listagem e consulta exigem apenas `Membership` ativo (qualquer role) — sem policy de escopo por unidade/ocupação como em `Fatura`, porque a informação não é sensível nem pessoal.

## Risks / Trade-offs

- [Sem campo de tipo/categoria, uma lista grande de espaços comuns fica difícil de organizar na UI] → Mitigação: aceitável para o volume esperado (poucos espaços por condomínio); adicionar categoria depois é aditivo, não quebra nada existente.
- [Regras de uso como texto livre não são validáveis/estruturadas] → Mitigação: decisão consciente — estruturar regras (ex: horário máximo, capacidade enforçada) só faz sentido quando houver reserva pra de fato aplicá-las.

## Migration Plan

Change aditiva, sem impacto em dados existentes: nova tabela `common_areas`, com `condominium_id` não-nulo. Nenhuma migração em `Tenancy`, `Registry`, `Billing` ou `Notice`. Sem necessidade de rollback especial além de reverter a migration nova.

## Open Questions

Nenhuma pendente — todas as decisões de modelagem foram fechadas durante a exploração que precedeu esta proposta.
