## Why

O frontend hoje só tem autenticação — nenhum bounded context tem tela, e o dashboard pós-login é um placeholder. Esta é a primeira tela real, escolhida deliberadamente como piloto: `CommonArea` é o módulo mais simples (majoritariamente leitura, sem fluxo de negócio complexo), o que permite usá-lo para estabelecer os padrões de navegação, listagem e formulário que os próximos 4 módulos (Registry, Billing, Notice, Reservation) vão reaproveitar, em vez de cada um inventar sua própria convenção.

Construir isso expôs um problema de fundação mais profundo: o frontend não tem como saber se o usuário logado é admin, síndico, prestador ou morador — a resposta de login nunca expôs `role`, e prestadores de serviço externos hoje recebem `Membership(role: "resident")` hardcoded, indistinguíveis de moradores comuns do ponto de vista de autorização. Sem resolver isso, nenhuma tela com visões diferentes por tipo de usuário é possível.

## What Changes

- **BREAKING**: renomeia o valor `doorman` para `service_provider` no enum `role` de `Tenancy::Membership` e `Tenancy::Invitation` — mesmo role passa a ser usado tanto para porteiro interno quanto para prestador de serviço externo.
- `Registry::RegisterServiceProvider` passa a conceder `Membership(role: "service_provider")` ao dar acesso a um prestador externo, em vez do `role: "resident"` hardcoded atual.
- `Notice::ResolveDestinatarios::STAFF_ROLES` atualizado para refletir o rename (`admin`, `manager`, `service_provider`).
- `SessionsController#create` (login) passa a incluir o `role` da `Membership` na resposta — hoje só retorna `id`, `email`, `name` do `User`.
- Frontend: `authStore` passa a guardar `role`; sidebar e conteúdo das telas passam a variar por "persona" (Admin, Morador, Prestador), derivada do `role` — `admin` e `manager` compartilham a persona Admin, `resident` vira Morador, `service_provider` vira Prestador.
- Sidebar ganha os 5 itens do domínio completo (Unidades, Avisos, Faturas, Espaços, Reservas) filtrados por persona, mesmo que só "Espaços" tenha tela funcional nesta change — os demais aparecem desabilitados/placeholder.
- Nova tela de `CommonArea` ("Espaços"): admin tem CRUD completo (tabela + modal de criar/editar); morador e prestador têm catálogo somente-leitura em cards.
- Primeiros componentes shadcn/ui adicionais: `Table`, `Badge`, `Dialog`, `Textarea`, `Switch`.

## Capabilities

### New Capabilities
(nenhuma — todo o comportamento novo estende capabilities já existentes)

### Modified Capabilities
- `tenancy`: rename do valor `doorman` → `service_provider` no enum `role`; login passa a expor `role` na resposta.
- `notice`: `STAFF_ROLES` (usado para destinatários de Aviso tipo `staff` e para restringir o painel de confirmação) reflete o rename de role.
- `common-area`: requirement de listagem que cita `doorman` explicitamente é atualizado para `service_provider`.

## Impact

- Backend: alteração de enum em 2 models (`Tenancy::Membership`, `Tenancy::Invitation`), 1 service (`Registry::RegisterServiceProvider`), 1 service (`Notice::ResolveDestinatarios`), 1 controller (`Api::V1::Auth::SessionsController`). Sem migration — `role` é validado em nível de aplicação, não é um enum de banco.
- Frontend: `authStore`, `Sidebar`, `AppLayout` (navegação por persona); nova feature `common-area` (`src/features/common-area/`) com views distintas para admin vs morador/prestador; `routes/_authenticated/common-areas.tsx` (ou estrutura equivalente).
- Testes de backend a atualizar (rename de role): `spec/domains/tenancy/membership_spec.rb`, `spec/services/notice/resolve_destinatarios_spec.rb`, `spec/integration/registry_tenancy_reconciliation_spec.rb`.
- Fora de escopo desta change: botão de reservar (morador) e visão de ocupação atual (prestador) na tela de Espaços — dependem de dados de `Reservation`, ficam para a change de frontend desse módulo. Rebranding de paleta de cores/tema do shadcn (`index.css` sem tokens `@theme` ainda) — decisão consciente de deixar para depois, "funcional primeiro".
