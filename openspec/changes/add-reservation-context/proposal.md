## Why

`CommonArea` hoje é só catálogo — o admin cadastra espaços comuns, mas não existe forma de um morador efetivamente reservar um horário. `project.md` já registrava esse gap na seção 7 (backlog v2: "Sistema de reservas de áreas comuns (com concorrência — bom caso para lock otimista)") e o design da v1 de `CommonArea` deixou explícito que reserva seria um bounded context futuro separado, não uma extensão do catálogo. Adiantar esse item agora — antes de `Access` — fecha o loop de valor do catálogo de espaços comuns, que sozinho é pouco útil sem reserva.

## What Changes

- Novo bounded context `Reservation`, isolado dos demais — lê `CommonArea::CommonArea` e `Registry::Occupancy` diretamente (leitura cross-context, mesmo padrão que `Billing` já usa pra ler `Registry::Unit`/`Registry::Occupancy`), sem escrita nem dependência de código nos outros contexts.
- `Reservation::Booking` (Aggregate Root): reserva de um `CommonArea` por uma `Registry::Occupancy`, num `data` + `turno` (`manha`/`tarde`/`noite`).
- Apenas `Occupancy` ativa com `owner: true` ou `responsible: true` pode reservar — não qualquer ocupante.
- Janela de reserva: não pode ser em data passada, nem além de 30 dias a partir de hoje.
- Aprovação automática — sem fluxo de aprovação do admin nesta v1.
- Cancelamento self-service: só quem reservou pode cancelar sua própria `Booking`. Cancelamento pelo admin fica fora de escopo (backlog v2 explícito).
- Sem cobrança nesta v1 — reservar é gratuito. Limite mínimo mensal por unidade e cobrança de reservas extras ficam documentados como backlog v2, não implementados agora.
- Limite de justiça de uso (sem billing): no máximo uma `Booking` ativa por unidade e por `CommonArea` dentro do mesmo mês — impede que uma unidade monopolize um espaço específico, independente de quantos turnos livres existam.
- `CommonArea` com `ativo: false` não pode receber reserva.
- Invariante de concorrência (não pode haver duas `Booking` ativas para o mesmo `common_area` + `data` + `turno`) garantida por índice único parcial no banco, mesmo idioma já usado por `Registry::Occupancy` (unicidade de dono/responsável ativo) e `Billing::CicloCobranca` (unicidade por competência) — não por lock otimista de `ActiveRecord` (protege update do mesmo registro, não dois inserts concorrentes) nem por `EXCLUDE`/`tsrange` do Postgres (só se justificaria com horário livre, não com turno fixo).
- Novos endpoints em `/api/v1/reservations`.
- **BREAKING**: nenhuma — capability inteiramente nova.

## Capabilities

### New Capabilities
- `reservation`: reserva de áreas comuns por dono/responsável de unidade, com turnos fixos, janela de 30 dias, aprovação automática e cancelamento self-service.

### Modified Capabilities
(nenhuma — `common-area` continua exatamente como está; `Reservation` só lê seus dados, não altera seu comportamento)

## Impact

- Nova tabela `bookings`, com `condominium_id` denormalizado (mesma convenção dos demais contexts), `common_area_id`, `occupancy_id`, `unit_id` (denormalizado de `occupancy`), `data`, `competencia` (denormalizado de `data`), `turno`, `cancelada_em`.
- Dois índices únicos parciais: `(common_area_id, data, turno) WHERE cancelada_em IS NULL` (concorrência de turno) e `(unit_id, common_area_id, competencia) WHERE cancelada_em IS NULL` (limite mensal por unidade).
- Nenhuma migração ou mudança de código em `Tenancy`, `Registry`, `Billing`, `Notice` ou `CommonArea`.
- Fora de escopo nesta v1 (documentado para v2): cancelamento pelo admin, cobrança de reservas extras/limite mínimo mensal por unidade (dinheiro), horário livre (não-turno), fallback/aprovação manual, **bloqueio pontual de turno por manutenção** (gap identificado via pesquisa de domínio — hoje só existe `CommonArea#ativo` como liga/desliga do espaço inteiro), waitlist, no-show tracking.
