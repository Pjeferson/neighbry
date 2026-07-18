## 1. Migrations

- [x] 1.1 `taxas` (condominium_id, valor, descricao, data_inicio, data_fim nullable, ativo, default true)
- [x] 1.2 `condominium_billing_settings` (condominium_id único, dia_cobranca 0–15, dias_para_vencimento)
- [x] 1.3 `ciclo_cobrancas` (condominium_id, competencia, status: gerando/concluido) — índice único em (condominium_id, competencia)
- [x] 1.4 `faturas` (condominium_id, unit_id, ciclo_cobranca_id, status: pendente/pago, data_vencimento) — índice único em (ciclo_cobranca_id, unit_id)
- [x] 1.5 `cobrancas` (condominium_id, fatura_id, taxa_id, valor)
- [x] 1.6 `pagamentos` (condominium_id, fatura_id, metodo, valor, data, transaction_id) — índice único em fatura_id
- [x] 1.7 `Tenancy::OnboardCondominium` — adicionar `ActiveSupport::Notifications.instrument("tenancy.condominium_onboarded", condominium_id:)` (sem migration; mudança de código aditiva)

## 2. Domain models (app/domains/billing/)

- [x] 2.1 `Billing::Taxa` — validações de presença/valor positivo; callback ou validação que rejeita alteração de `valor`/`data_inicio`/`data_fim` em registro já persistido; escopo/método de aplicabilidade por competência (`ativo` + intervalo de datas)
- [x] 2.2 `Billing::CondominiumBillingSetting` — validação de `dia_cobranca` entre 0 e 15 e `dias_para_vencimento` positivo
- [x] 2.3 `Billing::CicloCobranca` — normalização de `competencia` para o primeiro dia do mês antes de salvar; enum `status: gerando/concluido`
- [x] 2.4 `Billing::Fatura` — enum `status: pendente/pago`; validação de presença de ao menos uma `Cobrança`; método que calcula "atrasado" em tempo de leitura (não persistido)
- [x] 2.5 `Billing::Cobranca` — pertence a `Fatura` e a `Taxa`
- [x] 2.6 `Billing::Pagamento` — pertence a `Fatura`; validação de `valor` igual à soma das `Cobrança` da `Fatura`

## 3. Cadastro de Taxa (admin)

- [x] 3.1 `Billing::RegisterTaxa` service object (`Dry::Monads::Result`)
- [x] 3.2 `Billing::TaxaPolicy` — restringe cadastro a `Membership(role: admin)`
- [x] 3.3 `Billing::TaxaSerializer`
- [x] 3.4 `POST /api/v1/billing/taxas` — controller + rota

## 4. Configuração de dia de cobrança

- [x] 4.1 Subscriber de `tenancy.condominium_onboarded` em `config/initializers/domain_events.rb` — cria `Billing::CondominiumBillingSetting` padrão via `Billing::CreateDefaultBillingSetting` service
- [x] 4.2 `Billing::SetBillingDay` service object — upsert de `dia_cobranca`/`dias_para_vencimento`, restrito a admin (edição posterior à criação automática)
- [x] 4.3 `PUT /api/v1/billing/settings` — controller + rota

## 5. Geração mensal idempotente

- [x] 5.1 `Billing::GenerateBillingCycle` service — cria `CicloCobranca` (`status: gerando`) para a competência corrente; idempotente via índice único (retorna Failure/no-op se já existe); ignora silenciosamente condomínios sem `CondominiumBillingSetting`
- [x] 5.2 `Billing::GenerateInvoicesForCycle` service — para cada `Unit` com ao menos uma `Registry::Occupancy` ativa (qualquer papel) e ainda sem `Fatura` nesse `CicloCobranca`, cria `Fatura` com uma `Cobrança` por `Taxa` aplicável na competência, valor rateado igualmente; ao concluir todas as unidades, marca `CicloCobranca` como `concluido`
- [x] 5.3 `Billing::GenerateMonthlyInvoicesJob` (ActiveJob) — itera condomínios com `CondominiumBillingSetting` onde `hoje >= dia_cobranca`, chama os dois services acima, retomando ciclos incompletos. **Escopo**: implementa a lógica idempotente do job; o agendamento diário em si (cron/sidekiq-cron/scheduler da plataforma) não foi conectado nesta change — nenhuma gem nova foi adicionada sem validação explícita.

## 6. Confirmação manual de pagamento (admin)

- [x] 6.1 `Billing::ConfirmPayment` service — valida `valor == soma das Cobrança` (via `Pagamento#valor_matches_fatura_total`), cria `Pagamento`, marca `Fatura` como `pago`, publica evento `FaturaPaga`; trata violação do índice único de `fatura_id` (segunda tentativa) como Failure sem levantar exceção não tratada
- [x] 6.2 `Billing::PagamentoPolicy` — restringe confirmação manual a `Membership(role: admin)`
- [x] 6.3 `PATCH /api/v1/billing/faturas/:id/confirm_payment` — controller + rota

## 7. Webhook de pagamento e simulador de PSP mockado

- [x] 7.1 `Api::V1::Billing::Webhooks::PaymentsController` — autentica via segredo estático (env var `BILLING_WEBHOOK_SECRET`, header `X-Webhook-Secret`, `ActiveSupport::SecurityUtils.secure_compare`), extrai `transaction_id` do payload, chama `Billing::ConfirmPayment`
- [x] 7.2 `Billing::MockPsp::SimulatePayment` service — gera `transaction_id` simulado (`"MOCK-#{Time.current.to_i}"`), monta payload no formato de webhook e faz requisição HTTP real (`Net::HTTP.post`) ao endpoint de webhook
- [x] 7.3 `POST /api/v1/billing/mock_psp/simulate` (admin autenticado) e `POST /api/v1/billing/webhooks/payments` (segredo estático) — controllers + rotas

## 8. Evento de domínio

- [x] 8.1 Publicação de `billing.fatura_paga` via `ActiveSupport::Notifications` em `Billing::ConfirmPayment` (implementado junto de 6.1)
- [x] 8.2 N/A nesta change — nenhum bounded context assina `billing.fatura_paga` ainda; a publicação sozinha já satisfaz o requisito ("sem conhecimento de quem está inscrito"), mesmo padrão de `tenancy.invitation_accepted` antes de Registry existir

## 9. Visibilidade de Fatura por Occupancy

- [x] 9.1 `Billing::FaturaPolicy` — admin vê todas as faturas do condomínio; qualquer `Person` com `Registry::Occupancy` ativa na `Unit` (qualquer papel) vê apenas as da própria `Unit`; sem `Occupancy` ativa em nenhuma `Unit` não vê nenhuma
- [x] 9.2 `Billing::FaturaSerializer` (com `Cobrança` aninhadas via `has_many :cobrancas`)
- [x] 9.3 `GET /api/v1/billing/units/:unit_id/faturas` — controller escopado pela policy + rota (nested sob `Unit`, mesmo padrão de `units/:id/occupancies`)

## 10. Testes

- [x] 10.1 Specs de modelo — `Taxa` (imutabilidade, aplicabilidade por competência), `CicloCobranca` (normalização, status, índice único), `Fatura` (invariante de Cobrança mínima, índice único por unidade/ciclo), `Pagamento` (índice único por fatura, validação de valor)
- [ ] 10.2 Specs de serviço — geração idempotente e retomável do ciclo, rateio igualitário entre unidades ocupadas, criação automática de `BillingSetting` via evento, confirmação manual de pagamento, rejeição de segunda tentativa de pagamento
- [ ] 10.3 Specs de policy — `TaxaPolicy`, `PagamentoPolicy`, `FaturaPolicy` (admin/qualquer ocupante/sem ocupação)
- [ ] 10.4 Request specs — cadastro de taxa, geração via job (incluindo retomada após falha simulada), confirmação manual, webhook com/sem segredo correto, mock_psp/simulate, listagem de faturas por ocupante

## 11. Validação E2E

- [ ] 11.1 Validação manual via curl contra o servidor rodando: cadastro de taxa → geração de ciclo/fatura → confirmação manual pelo admin → confirmação via mock_psp/simulate → webhook rejeitando segredo incorreto → visibilidade de fatura por owner/responsible/morador comum
