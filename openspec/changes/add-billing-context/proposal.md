## Why

Neighbry ainda não tem nenhum mecanismo de cobrança condominial — a terceira peça central do domínio (depois de `Tenancy` e `Registry`) descrita no `openspec/project.md` seção 3. Sem `Billing`, o sistema cadastra condomínios, prédios, unidades e moradores, mas não consegue gerar nem cobrar a taxa condominial mensal, que é o fluxo financeiro que justifica o produto existir.

## What Changes

- Novo bounded context `Billing`, isolado dos demais (`Tenancy`, `Registry`) via namespace Ruby próprio e comunicação por Domain Events, seguindo o padrão já estabelecido.
- `Taxa`: encargo cadastrado pelo admin do condomínio, com `valor`, `descricao`, `data_inicio`, `data_fim` (opcional) e `ativo`. Uma vez criada, `valor`/`data_inicio`/`data_fim` são imutáveis — correção de erro é desativar e criar uma nova, sem qualquer vínculo automático entre as duas.
- `Billing::CondominiumBillingSetting`: configuração de cobrança por condomínio (`dia_cobranca`, 0–15), denormalizada dentro de `Billing` — não adiciona coluna em `Tenancy::Condominium`.
- `CicloCobranca`: marca a execução mensal da geração de cobrança por condomínio (`competencia`, sempre truncada para o primeiro dia do mês). Índice único em `(condominium_id, competencia)` garante idempotência mesmo que `dia_cobranca` mude no meio do mês.
- Job diário (Sidekiq) que verifica, por condomínio, se `hoje >= dia_cobranca` e não existe `CicloCobranca` na competência atual; se as duas condições valem, gera o ciclo.
- `Fatura` (Aggregate Root, por `Unit`, status `pendente | pago`): agrega uma ou mais `Cobrança`. `atrasado` é sempre calculado (`pendente` + vencimento no passado), nunca armazenado. Cancelamento de fatura fica fora de escopo nesta change (v2).
- `Cobrança`: uma por `Taxa` vigente na competência, com rateio igual entre as unidades ativas do condomínio (`valor_taxa ÷ número de unidades ativas`) — rateio proporcional por fração ideal/metragem fica fora de escopo (v2); `Registry::Unit` não é alterada nesta change.
- `Pagamento`: quita uma `Fatura` inteira. Dois caminhos:
  - Confirmação manual por admin.
  - Simulação de PSP mockado: endpoint dedicado (`/mock_psp/simulate`, autenticado como admin) monta um payload no formato de webhook real e faz uma chamada HTTP de verdade para o endpoint de webhook (`/webhooks/payments`), que é o único ponto que efetivamente confirma o pagamento e existiria igual em produção com um PSP real. O endpoint de webhook usa um segredo estático (não a autenticação de usuário normal), simulando a fronteira de autenticação de um PSP externo.
- Evento de domínio `FaturaPaga` publicado ao confirmar pagamento (via qualquer um dos dois caminhos).
- Autorização: cadastro de `Taxa` restrito a admin. Confirmação manual de pagamento restrita a admin. Visualização de `Fatura`: admin vê todas as faturas do condomínio; qualquer `Person` com `Occupancy` ativa numa `Unit` (owner, responsible ou morador comum) vê apenas as faturas da própria unidade.
- `Unit` só é cobrada (gera `Fatura`) se tiver ao menos uma `Occupancy` ativa, de qualquer papel — unidade vaga não é cobrada.

## Capabilities

### New Capabilities
- `billing`: geração mensal idempotente de cobrança condominial por unidade (Taxa, CicloCobranca, Fatura, Cobrança), confirmação de pagamento manual ou via webhook de PSP mockado, e autorização de acesso a dados financeiros por papel dentro da unidade.

### Modified Capabilities
- `tenancy`: `Tenancy::OnboardCondominium` passa a publicar um evento de domínio `tenancy.condominium_onboarded` (identificador do `Condominium` criado), para que `Billing` possa reagir criando uma configuração de cobrança padrão. Nenhuma mudança de schema ou de comportamento existente — só um novo evento publicado, seguindo o mesmo padrão já usado em `AcceptInvitation`/`tenancy.invitation_accepted`.

(`Registry::Unit` permanece inalterada — configuração de cobrança e rateio v1 não dependem de nenhum dado novo em `Registry`)

## Impact

- Novas tabelas: `billing_taxas`, `billing_condominium_billing_settings`, `billing_ciclo_cobrancas`, `billing_faturas`, `billing_cobrancas`, `billing_pagamentos` — todas com `condominium_id` denormalizado.
- Novo job Sidekiq de geração mensal.
- Novos endpoints em `/api/v1/billing/*` (taxas, faturas, mock_psp/simulate, webhooks/payments).
- Novo mecanismo de autenticação por segredo estático, distinto do JWT de sessão, específico do endpoint de webhook.
- Pequena mudança aditiva em `Tenancy::OnboardCondominium` (novo evento publicado). Nenhuma migração em `Tenancy` ou `Registry`.
