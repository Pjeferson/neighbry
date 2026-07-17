## Why

`Tenancy` resolve "quem pode acessar o sistema e com que poder", mas o sistema ainda não sabe nada sobre a estrutura física e social de um condomínio — quantos blocos tem, quais unidades existem, quem mora ou é dono de cada uma. Sem isso, nenhum fluxo de negócio real (rateio de taxa, aviso por unidade, controle de acesso) tem onde se apoiar. `Registry` é o próximo bounded context planejado desde o início do projeto (`openspec/project.md` seção 8), e agora `Condominium` já existe como código real pra `Registry` se apoiar em cima.

## What Changes

- Novo bounded context `Registry`: `Building`, `Unit`, `Person`, `Occupancy`.
- `Person` é por condomínio (não global), reconciliada por CPF único dentro do condomínio — a mesma pessoa cadastrada em duas unidades do mesmo condomínio reaproveita o registro, nunca duplica.
- `Occupancy` liga `Person` a `Unit` com dois flags independentes e mutuamente exclusivos por pessoa: `owner` (no máx. 1 ativo por Unit) e `responsible` (no máx. 1 ativo por Unit) — quem não tem nenhum dos dois é só morador comum.
- Hierarquia de autorização por Unit: `owner` > `responsible` > morador comum — só o `owner` gerencia quem é `responsible`; `responsible` gerencia moradores comuns; morador comum só edita o próprio perfil.
- `Person` com `type: service_provider` nunca tem `Occupancy` — prestador não ocupa unidade.
- Três service objects centrais, cada um coberto por policy de autorização: `RegisterOccupant` (cadastra Person+Occupancy, concede acesso opcionalmente), `RegisterServiceProvider` (cadastra prestador, sem Occupancy), `EndOccupancy` (encerra uma Occupancy — quem pode encerrar depende do tipo: `owner` só admin, `responsible` só o `owner`, morador comum o `responsible`/`owner`/admin).
- Concessão de acesso (login) reaproveita `Tenancy::InviteMember`/`AcceptInvitation` já existentes — chamada síncrona direta ao service público de `Tenancy` (padrão Open Host Service / Customer-Supplier do Context Map de DDD, não Shared Kernel nem acesso a model interno). `Registry` nunca chama de volta `Tenancy`; a reconciliação (`Person.user_id`) acontece via evento publicado por `Tenancy`, correlacionado por `invitation_id` armazenado em `Person` (nunca por email).
- Cadastro de `Building` e `Unit` — admin-only. Sem isso, a estrutura física do condomínio só existiria se criada manualmente via console, o que não é um caminho real pra uma aplicação com frontend (gap encontrado depois da primeira rodada de implementação, corrigido ainda dentro desta mesma change).
- **BREAKING**: nenhuma — `Tenancy` ganha capacidade nova (publicar evento), não remove nem quebra nada existente.

## Capabilities

### New Capabilities
- `registry`: estrutura física/social do condomínio — `Building`, `Unit`, `Person`, `Occupancy`, cadastro e encerramento de ocupação, prestadores de serviço.

### Modified Capabilities
- `tenancy`: `AcceptInvitation` passa a publicar um evento de domínio (`InvitationAccepted`, com `invitation_id` e `user_id`) após ativar o `Membership` — novo requirement, comportamento aditivo, não altera nada do que já existe.

## Impact

- **Backend**: novo namespace `app/domains/registry/` (Building, Unit, Person, Occupancy), `app/services/registry/`, `app/policies/registry/`; novas migrations com `condominium_id` denormalizado nas 4 tabelas (conforme requirement já vigente na spec de `tenancy`); pequena adição em `app/services/tenancy/accept_invitation.rb` pra publicar o evento; endpoints `POST /api/v1/buildings` e `POST /api/v1/buildings/:building_id/units` (admin-only).
- **Frontend**: telas de cadastro de morador/dono/responsável/prestador por unidade, e de cadastro de bloco/unidade (admin); nenhuma mudança em telas de Tenancy já existentes.
- **Sem impacto** em Billing/Notice/Access/CommonArea — ainda não existem.
