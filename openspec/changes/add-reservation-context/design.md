## Context

`Tenancy`, `Registry`, `Billing`, `Notice` e `CommonArea` já estão implementados e arquivados. O design da v1 de `CommonArea` (`openspec/changes/archive/2026-07-18-add-common-area-context/design.md`) já havia decidido, sem implementar, que reserva seria um bounded context `Reservation` separado — mesmo critério que separou `Registry` (estrutura) de `Billing` (processo): reserva envolve concorrência, calendário/disponibilidade e potencial integração futura com `Billing` (cobrança). Este design retoma exatamente essa decisão registrada.

O padrão de acoplamento entre bounded contexts já está estabelecido pelo código existente, não precisa ser reinventado: escrita cross-context passa por domain event via `ActiveSupport::Notifications` (`config/initializers/domain_events.rb`); leitura cross-context é feita direto via ActiveRecord — `Billing::GenerateInvoicesForCycle` já consulta `Registry::Unit` e `Registry::Occupancy` sem indireção nenhuma. `Reservation` segue o mesmo padrão de leitura para `CommonArea::CommonArea` e `Registry::Occupancy`.

## Goals / Non-Goals

**Goals:**
- Permitir que dono ou responsável de uma unidade reserve um espaço comum ativo, num turno fixo, dentro de uma janela de 30 dias, sem intervenção do admin.
- Garantir, sob concorrência real (duas requisições simultâneas para o mesmo espaço/data/turno), que só uma reserva vingue — sem depender de sorte na ordem de execução da aplicação.
- Reutilizar o idioma de invariante já validado neste projeto (índice único parcial + rescue de corrida), em vez de introduzir uma técnica nova só porque o backlog usou a palavra "lock otimista".
- Impedir que uma única unidade monopolize um espaço comum específico dentro do mesmo mês, sem depender de cobrança/billing pra isso — pesquisa de domínio (sistemas de reserva de amenities em condomínios/HOA) aponta esse como o problema #1 de sistemas sem enforcement automático: nada impede hoje, por exemplo, que uma unidade reserve o salão de festas em múltiplos turnos ao longo do mesmo mês, mesmo respeitando a janela de 30 dias.

**Non-Goals:**
- Cancelamento pelo admin — só quem reservou cancela nesta v1. Registrado aqui como backlog explícito de v2 (junto com o campo `cancelada_por`, que fica de fora da migration desta v1 para não precisar de ALTER TABLE depois — se v2 precisar, adiciona coluna nova).
- Cobrança de reservas — sem `taxa_de_uso` nem limite mínimo mensal por unidade. Reservar é gratuito nesta v1. V2 poderá definir um número mínimo de reservas por mês por unidade e valor para reservas extras, mas isso depende de um mecanismo de cobrança que ainda não existe para este contexto.
- Horário livre / intervalos arbitrários — só os 3 turnos fixos (`manha`, `tarde`, `noite`). Sem isso, o problema de concorrência seria overlap de intervalo (mais complexo); com turno fixo, degenera em unicidade de tupla discreta.
- Aprovação manual / fallback de segunda alçada — aprovação é sempre automática nesta v1.
- Notificação de confirmação/lembrete de reserva — fora de escopo, sem pressão de negócio para isso ainda.
- Bloqueio pontual de turno por manutenção (ex: piscina fechada uma sexta-feira para limpeza, sem desativar o `CommonArea` inteiro) — gap real identificado via pesquisa de domínio, mas fica registrado como backlog v2 explícito. Nesta v1 o único mecanismo de indisponibilidade é `CommonArea#ativo`, que desliga o espaço inteiro, não um turno específico. Como cancelamento pelo admin também é fora de escopo desta v1 (ver acima), um turno já reservado não pode ser liberado/bloqueado por manutenção — limitação aceita conscientemente.
- Waitlist e no-show tracking — waitlist exige infraestrutura de notificação que o projeto não tem ainda; no-show exigiria check-in, que amarraria com o bounded context `Access` (ainda não implementado). Ambos ficam registrados como candidatos a v2, sem prioridade definida.

## Decisions

### `Reservation::Booking` referencia `Registry::Occupancy`, não `Registry::Person`
As flags `owner`/`responsible` (que definem quem pode reservar) vivem em `Occupancy`, não em `Person` — uma pessoa pode ter mais de uma `Occupancy` ativa (dono de duas unidades, ou dono de uma e responsável por outra), e referenciar `person` direto deixaria ambíguo qual unidade autorizou a reserva. Referenciando `occupancy`, a unidade vem embutida — importante para v2 (limite mensal e cobrança são por unidade, não por pessoa). Alternativa considerada: `belongs_to :person` + `belongs_to :unit` seguindo diretamente na `Booking` — descartada por duplicar informação que `Occupancy` já garante consistente (e por não validar automaticamente que a pessoa é de fato dono/responsável daquela unidade).

### Concorrência: índice único parcial, não `lock_version` nem `EXCLUDE`/`tsrange`
A invariante "no máximo uma `Booking` ativa por `common_area` + `data` + `turno`" é resolvida com:
```ruby
add_index :bookings, [:common_area_id, :data, :turno], unique: true,
          where: "(cancelada_em IS NULL)"
```
Esse é o terceiro uso deste idioma no projeto — `Registry::Occupancy` já tem `add_index [:unit_id], unique: true, where: "(owner = true) AND (end_date IS NULL)"` para "só um dono ativo por unidade", e `Billing::CicloCobranca` tem `add_index [:condominium_id, :competencia], unique: true` para "só um ciclo por competência". O service de criação faz `rescue ActiveRecord::RecordNotUnique` (ou `RecordInvalid`, se a validação de unicidade a nível de aplicação disparar primeiro) e retorna falha amigável — mesmo padrão de `Billing::GenerateBillingCycle`.

Alternativas descartadas:
- **Lock otimista (`lock_version` do Rails)**: protege contra dois `UPDATE`s concorrentes no *mesmo registro já existente* (stale write). O problema aqui é dois `INSERT`s concorrentes criando *registros diferentes* que conflitam entre si — `lock_version` não participa dessa corrida de forma alguma.
- **`EXCLUDE` constraint com `btree_gist`/`tsrange`**: resolveria overlap de *intervalos* de horário livre. Como o turno é fixo e discreto, dois registros só conflitam se forem literalmente iguais em `(common_area_id, data, turno)` — não existe mais "sobreposição parcial" a detectar, então a ferramenta mais simples que resolve corretamente já é suficiente. Usar `EXCLUDE` aqui seria complexidade sem benefício (e infraestrutura nova — `btree_gist` — que o projeto ainda não usa).

### Limite de uma reserva ativa por unidade e CommonArea por mês
Para impedir que uma unidade monopolize um espaço comum, `Booking` SHALL garantir no máximo uma reserva ativa por `unit` + `common_area` + mês (competência) — independente de quantos turnos diferentes existam dentro desse mês. Isso é ortogonal ao limite de v2 (mínimo mensal/cobrança de excedente, que é sobre dinheiro); este é sobre justiça de uso, sem nenhuma peça de billing envolvida.

Como `Booking` referencia `occupancy`, não `unit`, diretamente — e duas `Occupancy` diferentes (dono e responsável) podem apontar pra mesma unidade — a checagem não pode se apoiar só em `occupancy_id`. Por isso `unit_id` é denormalizado em `Booking` a partir de `occupancy.unit_id` no momento da criação (mesmo idioma já usado em `Registry::Unit#set_condominium_from_building` e `Registry::Occupancy#set_condominium_from_unit` — `before_validation` preenchendo FK a partir de uma associação). Da mesma forma, `competencia` (primeiro dia do mês de `data`) é denormalizado a partir de `data`, espelhando `Billing::CicloCobranca#competencia`.

Com essas duas colunas, a invariante vira o mesmo idioma de índice único parcial já usado para o turno:
```ruby
add_index :bookings, [:unit_id, :common_area_id, :competencia], unique: true,
          where: "(cancelada_em IS NULL)"
```
Validação de aplicação replica a mesma regra pra mensagem de erro amigável; o índice garante a invariante sob concorrência (duas requisições da mesma unidade tentando reservar o mesmo espaço em turnos diferentes do mesmo mês, simultaneamente).

### `cancelada_em` como único campo de cancelamento (sem `cancelada_por`)
Só quem reservou pode cancelar nesta v1, então "quem cancelou" é sempre implícito (a própria `occupancy` da `Booking`). Adicionar `cancelada_por_person_id` agora seria especular sobre o fluxo de cancelamento por admin da v2, que ainda não tem requisitos definidos (ex: precisa de motivo? notifica o morador?). Fica documentado aqui como backlog explícito, não como coluna "desligada".

### Nome do bounded context e aggregate em inglês (`Reservation::Booking`)
Segue o padrão de nomenclatura já usado por `Registry`/`Tenancy`/`CommonArea` (inglês), não o de `Billing`/`Notice` (português) — não há regra fixa no projeto sobre isso, é decisão por bounded context, e `Reservation` está mais próximo do domínio estrutural/catálogo (`CommonArea`) do que do domínio de processo financeiro.

### Janela de reserva validada na aplicação, não no banco
`data` não pode ser passada nem exceder 30 dias a partir de hoje — validado em `Booking` via `validates_comparison`/validação custom no momento da criação. Diferente da invariante de unicidade (que precisa sobreviver a concorrência), essa é uma regra de janela de tempo relativa a "agora", que não faz sentido como constraint de banco (mudaria de significado a cada dia). Corrida entre duas requisições não quebra essa invariante — não há necessidade de proteção extra.

### `CommonArea` inativo bloqueia reserva via leitura, não via evento
`Booking` valida `common_area.ativo?` diretamente na criação (leitura síncrona, mesmo padrão de leitura cross-context já estabelecido) em vez de manter um campo espelhado via domain event. Não há necessidade de desnormalizar esse dado — a leitura é barata e sempre atual.

### Listagem aberta, criação restrita a dono/responsável
Qualquer `User` com `Tenancy::Membership` ativo no condomínio pode listar/consultar `Booking` (mesmo padrão de visibilidade que `CommonArea` já usa: leitura não-sensível, aberta a qualquer membro — um morador precisa ver a agenda pra saber se um turno está livre antes de tentar reservar). Criação exige que o `User` autenticado tenha uma `Occupancy` ativa com `owner: true` ou `responsible: true` na unidade correspondente. Cancelamento exige que a `Booking` pertença a uma `Occupancy` do próprio `User`.

## Risks / Trade-offs

- [Índice único parcial depende de `cancelada_em IS NULL` ser a única condição de "ativa" — se v2 adicionar um novo status (ex: "pendente de aprovação"), o índice precisa ser revisado] → Mitigação: aceitável agora; documentado aqui para quando aprovação manual (fora de escopo desta v1) for implementada.
- [Sem `cancelada_por`, se v2 precisar saber quem cancelou uma reserva antiga desta v1, esse dado não existirá retroativamente] → Mitigação: aceitável — cancelamento nesta v1 só pode ser feito por quem reservou, então a informação já está implícita em `occupancy_id`; só cancelamento por terceiro (admin) precisaria do campo, e isso é v2.
- [Turno fixo é menos flexível que horário livre — um espaço poderia comportar duas reservas curtas dentro do mesmo turno] → Mitigação: decisão consciente para simplificar a v1; se v2 precisar de granularidade maior, é um novo turno ou um redesenho aditivo, não quebra dados existentes.

## Migration Plan

Change aditiva, sem impacto em dados existentes: nova tabela `bookings`, com `condominium_id`, `common_area_id`, `occupancy_id`, `unit_id` (denormalizado de `occupancy`) não-nulos, `data`, `competencia` (denormalizado de `data`, primeiro dia do mês), `turno`, `cancelada_em` (nullable), e os dois índices únicos parciais descritos acima (`[:common_area_id, :data, :turno]` e `[:unit_id, :common_area_id, :competencia]`, ambos `where: "(cancelada_em IS NULL)"`). Nenhuma migração ou mudança em `Tenancy`, `Registry`, `Billing`, `Notice` ou `CommonArea`. Sem necessidade de rollback especial além de reverter a migration nova.

## Open Questions

Nenhuma pendente — todas as decisões de modelagem foram fechadas durante a exploração que precedeu esta proposta.
