## Context

`Tenancy` (multi-tenancy, login, convites) e `Registry` (prédios, unidades, pessoas, ocupações) já estão implementados e arquivados, estabelecendo o padrão de bounded context do projeto: models em `app/domains/<context>/`, services em `app/services/<context>/`, policies em `app/policies/<context>/`, comunicação entre contextos via `ActiveSupport::Notifications` (Domain Events) ou, quando síncrono, chamando o service object de outro contexto (nunca seu model).

`Billing` é o terceiro bounded context. `openspec/project.md` seção 3 já esboçava `Fatura`/`Taxa`/`Pagamento` com rateio por metragem, mas esse esboço foi revisado em profundidade durante exploração (`/opsx:explore`) antes desta proposta — várias decisões divergem do esboço original de forma deliberada (detalhado abaixo).

## Goals / Non-Goals

**Goals:**
- Gerar cobrança mensal por unidade de forma idempotente, mesmo com cron rodando diariamente e configuração de dia de cobrança podendo mudar no meio do mês.
- Permitir confirmação de pagamento tanto manual (admin) quanto via simulação de webhook de PSP, com a fronteira entre "domínio real" e "simulação de infraestrutura externa" bem definida — o endpoint de webhook deve ser exatamente o que existiria em produção com um PSP de verdade.
- Reaproveitar `Registry::Occupancy` (não uma hierarquia de papéis) como base de autorização de leitura de dados financeiros: quem mora ali, de qualquer papel, vê a fatura de onde mora.
- Manter `Billing` isolado de `Tenancy` e `Registry` — nenhuma coluna nova nessas tabelas, nenhuma dependência direta de código (a única exceção é um novo evento de domínio publicado por `Tenancy`, aditivo).

**Non-Goals:**
- Rateio proporcional por fração ideal ou metragem (v2). V1 faz rateio igualitário entre unidades ativas.
- Correção de resto de divisão do rateio (ex: "banco de crédito" que acumula centavos e aplica no mês seguinte) — v2. V1 aceita a soma das `Cobrança` não bater centavo a centavo com o valor total da `Taxa`.
- Cancelamento de `Fatura` (v2).
- Multa/juros por atraso (v2) — por isso `atrasado` não precisa ser um estado armazenado com data de início do atraso.
- Vínculo de auditoria entre uma `Taxa` desativada por erro e a `Taxa` que a corrige.
- Assinatura HMAC real no webhook — v1 usa segredo estático simples.
- Delay assíncrono real (fila) na confirmação de pagamento — a chamada do simulador ao webhook é HTTP síncrona.

## Decisions

### Vocabulário: Fatura é por unidade, não por condomínio
Considerado e descartado: `Fatura` como agregado do condomínio inteiro no mês, com `Cobrança` como a obrigação individual por unidade. Rejeitado porque diverge do uso coloquial ("minha fatura" é sempre o boleto individual do morador) e torna `Pagamento` estranho (ninguém paga o condomínio inteiro de uma vez). Decisão final: `Fatura` é o Aggregate Root por `Unit` e por competência; `Cobrança` é o encargo individual (uma por `Taxa` vigente) dentro dela. Isso também preserva o invariante já registrado em `project.md`: "Fatura não existe sem ao menos uma Cobrança".

### CicloCobranca como marcador de execução mensal, não como agregado de negócio
Motivação inicial era só idempotência (evitar gerar faturas duas vezes no mês), mas o conceito também passou a servir para dar uma visão de adimplência do mês (faturas pagas ÷ total de faturas do ciclo). Nome escolhido: `CicloCobranca` (billing cycle), com `competencia` como atributo (termo contábil brasileiro para o período de referência).

**Regra de idempotência**: `competencia` é sempre truncada para o primeiro dia do mês corrente no momento da execução do job — nunca a data exata em que o job rodou. Isso é o que torna a idempotência resiliente a mudanças de `dia_cobranca` no meio do mês: se o ciclo já foi gerado dia 5 e o admin muda `dia_cobranca` para depois do dia 5, uma segunda tentativa de gerar colide no índice único `(condominium_id, competencia)` e é bloqueada, independente de qual dia o job rodou.

**Trigger do cron**: `hoje >= dia_cobranca` (não `==`). Com a idempotência garantida pelo índice único, a condição de disparo pode ser mais frouxa sem risco de duplicar cobrança — isso cobre o caso de o servidor cair no dia exato ou o admin mudar `dia_cobranca` para um valor já passado no mês corrente.

**Adimplência calculada, não armazenada**: contagem de faturas pagas vs. total do ciclo é sempre computada sob demanda, evitando um campo cacheado que pode ficar desatualizado sem um mecanismo de invalidação.

### Configuração de cobrança denormalizada em Billing
`dia_cobranca` (0–15) é dado de configuração do condomínio, mas por causa do isolamento entre bounded contexts (nenhuma dependência direta de código, regra 8 do `CLAUDE.md`), não pode virar coluna em `Tenancy::Condominium`. Fica em `Billing::CondominiumBillingSetting`, com `condominium_id` denormalizado — mesmo padrão de toda tabela de domínio do projeto.

### Fatura sem estado "atrasado" armazenado
Alternativa considerada: job diário que promove `Fatura` de `pendente` para `atrasado` ao passar do vencimento. Rejeitada por não ter necessidade de negócio agora (sem multa/juros, "desde quando atrasou" não importa) e por introduzir mais um job e mais uma forma do dado ficar dessincronizado. `atrasado` é sempre `pendente` + `data_vencimento < hoje`, resolvido em tempo de leitura.

### Taxa sem distinção recorrente/extra
Alternativa inicial: `Taxa` com um `tipo` (`recorrente` | `extra`). Descartada: a única diferença real entre os dois é se há ou não uma data de expiração — uma taxa "extra" é apenas uma taxa com `data_fim` preenchida cobrindo um período curto. Um único campo `data_fim` (nullable) resolve os dois casos sem precisar de enum.

**Imutabilidade de `valor`, `data_inicio`, `data_fim`**: uma vez criada, uma `Taxa` nunca é editada nesses campos — correção de erro é desativar (`ativo: false`) e cadastrar uma nova. Isso preserva o histórico (uma `Cobrança` já gerada referencia o valor que valia na época) sem risco de uma edição retroativa mudar o que já foi cobrado. Diferente do padrão de "invalidação automática" usado em `Tenancy::Invitation` (que tem uma chave natural de duplicidade: `condominium + email + pending`), `Taxa` não tem essa chave — múltiplas taxas ativas simultâneas são normais e esperadas, então não há como o sistema inferir automaticamente "isso é a correção daquilo". A ligação entre a taxa errada e a corrigida não é rastreada — decisão explícita, considerada over-engineering para o estágio atual.

### Pagamento via webhook mockado com round-trip HTTP real
Alternativa considerada: simulação de pagamento como chamada Ruby direta entre dois service objects (sem HTTP), mais simples de testar. Rejeitada em favor de um round-trip HTTP real entre dois endpoints:
- `POST /api/v1/billing/mock_psp/simulate` — autenticado como admin (JWT normal). Só existe porque estamos mockando; simula "ser o PSP".
- `POST /api/v1/billing/webhooks/payments` — autenticado por segredo estático (não JWT de sessão), simulando a fronteira de autenticação real de um webhook de PSP externo. Esse é o endpoint que, em produção com um PSP real, receberia a notificação de pagamento sem qualquer mudança de código.

Essa separação mantém o contrato de produção intacto (só troca quem chama o webhook) e ensina a fronteira de rede/autenticação que um PSP real teria, que era um objetivo explícito do projeto (aprendizado de DDIA).

### Unidade "ativa" para fins de cobrança
Alternativa descartada: exigir que uma `Unit` tenha `owner` ou `responsible` cadastrado para ser cobrada (cogitamos criar essa regra em `Registry`, mas foi descartada — nenhuma mudança em `Registry` nesta change). Decisão final: uma `Unit` é considerada "ativa" para geração de `Fatura` e para o divisor do rateio quando tem **ao menos uma `Registry::Occupancy` ativa, de qualquer papel** — mesmo que seja só um morador comum, sem `owner`/`responsible` cadastrado. `Unit` sem nenhuma ocupação ativa (vaga) não é cobrada.

Consequência aceita conscientemente: uma unidade pode ser cobrada mesmo sem ninguém com autoridade formal (owner/responsible) pra efetivamente pagar a fatura — aceito porque o morador ali mora e deve saber do valor devido, mesmo que não seja quem assina a responsabilidade financeira formalmente.

**Risco residual não resolvido nesta change**: se o `owner`/`responsible` de uma `Unit` tiver a própria `Occupancy` encerrada e restar apenas morador(es) comum(ns) com `Occupancy` ainda ativa, a unidade permanece "ativa" (continua sendo cobrada) mesmo sem ninguém formalmente responsável — mesmo comportamento aceito acima, não é um caso novo, só documentado explicitamente aqui.

### Visibilidade de Fatura por Occupancy, não por papel
Sem policy hierárquica nova: qualquer `Person` com `Registry::Occupancy` ativa numa `Unit` — `owner`, `responsible` ou morador comum, sem distinção de papel — vê as `Fatura` dessa unidade. Admin (`Tenancy::Membership role: admin`) vê todas as faturas do condomínio. `Person` sem nenhuma `Occupancy` ativa em nenhuma `Unit` não vê nenhuma fatura. Cadastro de `Taxa` e confirmação manual de pagamento continuam restritos a admin — a simplificação é só na leitura de `Fatura`.

### CicloCobranca com status para retomada segura após falha parcial
`CicloCobranca` tem `status: gerando | concluido`. Criado como `gerando` antes de iterar as unidades ativas; vira `concluido` só depois que todas as `Fatura` da competência foram geradas com sucesso. Se o job cair no meio (gerou `Fatura` pra 3 de 10 unidades e travou), a próxima execução encontra o mesmo `CicloCobranca` em `gerando` (não cria um novo — o índice único em `(condominium_id, competencia)` já impede isso) e retoma a geração das unidades restantes.

### Idempotência de Fatura e Pagamento via índices únicos, não via lock
Dois índices únicos fazem o trabalho pesado de idempotência sem precisar de lock distribuído ou verificação em aplicação:
- `billing_faturas`: único em `(ciclo_cobranca_id, unit_id)` — retomar um `CicloCobranca` em `gerando` nunca duplica `Fatura` pra uma unidade já processada.
- `billing_pagamentos`: único em `fatura_id` — como só existe pagamento completo (nunca parcial, decisão explícita), uma `Fatura` nunca tem mais de um `Pagamento`. Uma segunda tentativa de confirmar pagamento (manual ou via webhook, incluindo retry de rede ou duplo clique) esbarra nesse índice; o service trata a violação como no-op/rejeição, não como erro.

### data_vencimento configurável por condomínio
`Billing::CondominiumBillingSetting` ganha `dias_para_vencimento`. `Fatura.data_vencimento = data_de_geração + dias_para_vencimento`. Mantém a mesma filosofia de `dia_cobranca`: configuração por condomínio, denormalizada em `Billing`.

### BillingSetting criado automaticamente ao onboardar um Condominium
Alternativa considerada: sem criação automática — admin configura manualmente depois, cron pula condomínios sem `BillingSetting` (esse fallback continua existindo de qualquer forma, para condomínios já existentes antes desta change). Decisão final: `Tenancy::OnboardCondominium` passa a publicar um evento novo `tenancy.condominium_onboarded` (hoje não publica nenhum evento — mesmo padrão já usado em `AcceptInvitation` com `tenancy.invitation_accepted`), e `Billing` assina esse evento para criar um `CondominiumBillingSetting` com valores padrão (`dia_cobranca` e `dias_para_vencimento` a definir na implementação), editável pelo admin depois. Evita o footgun de "condomínio cadastrado e nunca configurado". É uma mudança pequena e aditiva em `Tenancy` — novo evento publicado, nenhuma mudança de schema ou de comportamento existente — tratada como Modified Capability (delta em `specs/tenancy/spec.md`).

### transaction_id simulado no payload do webhook mockado
`billing_pagamentos` ganha uma coluna `transaction_id`. `Billing::MockPsp::SimulatePayment` gera um valor tipo `"MOCK-#{Time.current.to_i}"` e inclui no payload enviado ao endpoint de webhook, que persiste no `Pagamento` — simula o identificador de transação que um PSP real sempre envia, mesmo sem ainda usá-lo para deduplicação nesta v1 (a deduplicação real é feita pelo índice único em `fatura_id`, não pelo `transaction_id`).

## Risks / Trade-offs

- [Rateio igualitário não reflete tamanho real da unidade, pode ser percebido como injusto em condomínios reais] → Mitigação: decisão explícita de escopo v1, documentada como não-meta; rateio proporcional é v2 sem exigir mudança de schema em `Registry::Unit` além de adicionar o campo de fração/metragem quando chegar a hora.
- [Segredo estático no webhook é fraco comparado a assinatura HMAC real] → Mitigação: aceitável para ambiente de aprendizado/dev; documentado como não-meta explícita, não uma omissão.
- [Correção de `Taxa` sem vínculo rastreável pode confundir um admin auditando o histórico depois] → Mitigação: decisão consciente, `Cobrança` já preserva o valor histórico correto independente do rastreamento entre Taxas; se necessário no futuro, `substitui_id` pode ser adicionado sem quebrar nada existente.
- [Cron com trigger `>=` pode gerar o ciclo "atrasado" (ex: sistema fora do ar por vários dias) sem qualquer alerta] → Mitigação: fora de escopo agora; o índice único garante que não duplica, só que pode gerar depois do dia configurado.
- [Condomínios já onboardados antes desta change nunca recebem `BillingSetting` automaticamente, porque o evento só dispara em novos onboardings] → Mitigação: cron já pula silenciosamente condomínios sem `BillingSetting` (comportamento decidido independentemente do evento); admin configura manualmente uma vez para condomínios pré-existentes.
- [Unidade pode ser cobrada sem ninguém com `owner`/`responsible` pra pagar de fato, caso reste só morador comum] → Mitigação: decisão consciente de escopo (ver Decisão "Unidade ativa"), não é tratado como erro.

## Migration Plan

Change aditiva, sem impacto em dados existentes: novas tabelas (`billing_taxas`, `billing_condominium_billing_settings`, `billing_ciclo_cobrancas` com `status`, `billing_faturas` com índice único `(ciclo_cobranca_id, unit_id)`, `billing_cobrancas`, `billing_pagamentos` com índice único `fatura_id` e coluna `transaction_id`), todas com `condominium_id` não-nulo. Nenhuma migração em `Registry`. Em `Tenancy`: nenhuma migração de schema, apenas um novo `ActiveSupport::Notifications.instrument("tenancy.condominium_onboarded", ...)` em `OnboardCondominium` — aditivo, sem quebrar comportamento existente. Sem necessidade de rollback especial além de reverter as migrations novas e o publish do evento.

## Open Questions

Nenhuma pendente — todas as decisões de modelagem foram fechadas durante a exploração que precedeu esta proposta.
