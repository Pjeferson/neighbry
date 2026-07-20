## Context

`neighbry-frontend` tem hoje só autenticação (`frontend-auth-onboarding`, arquivada): cadastro de condomínio, localizar condomínio, login por subdomínio. `AppLayout`/`Sidebar` existem mas só têm logout; `_authenticated/index.tsx` é um placeholder. Nenhum bounded context (Registry, Billing, Notice, CommonArea, Reservation) tem tela ainda, embora todos tenham API pronta e testada no backend.

`CommonArea` foi escolhido como piloto por ser o módulo mais simples — sem fluxo de negócio complexo, majoritariamente leitura — precisamente para que as decisões de estrutura tomadas aqui (navegação por persona, padrão de listagem, padrão de formulário) sirvam de referência pros próximos 4 módulos, em vez de cada um inventar sua própria convenção.

Investigar "como a tela sabe se o usuário é admin ou morador" expôs que a sessão nunca carregou `role`, e que o modelo de autorização atual não distingue prestador de morador (ambos recebem `Membership(role: "resident")`). Resolver isso é pré-requisito de qualquer tela com visão diferente por tipo de usuário — não é specífico de `CommonArea`, por isso vira parte desta change como fundação.

## Goals / Non-Goals

**Goals:**
- Fazer o modelo de `role` do backend refletir de fato as personas que existem no domínio, sem inventar autorização nova — só nomear corretamente o que já existe (`doorman` → `service_provider`, reaproveitado também para prestador externo).
- Expor `role` na sessão do frontend, e traduzir isso numa "persona" de UI (Admin, Morador, Prestador) que decide o que a sidebar e o conteúdo de cada tela mostram.
- Entregar `CommonArea` funcional para as 3 personas, com o nível de acesso que cada uma já tem hoje no backend (admin: CRUD; morador/prestador: leitura).
- Estabelecer os primeiros padrões de componente shadcn pra listagem administrativa (tabela) e listagem de consumo (cards), pra não redecidir isso a cada módulo novo.

**Non-Goals:**
- Ação de reservar (morador) ou visão de ocupação atual por reserva (prestador) na tela de Espaços — depende de dados de `Reservation`, que ainda não tem frontend. Fica pra quando essa change existir; o catálogo de `CommonArea` construído aqui é a base sobre a qual aquele botão vai ser adicionado depois.
- Tema de cores / rebranding visual — `components.json` tem `cssVariables: true` mas o `shadcn init` nunca rodou (`index.css` sem nenhum token `@theme`). Decisão consciente do usuário: funcional primeiro, paleta de marca depois, numa passada dedicada.
- Tela de gestão de membros/staff (quem pode promover morador a síndico, remover admin, etc.) — mencionada pelo usuário como motivação para manter `manager` separado de `admin`, mas é escopo de uma change futura de Tenancy/gestão de acesso, não desta.
- Diferenciação de UI entre `admin` e `manager` — nesta fase os dois compartilham a mesma persona/telas.

## Decisions

### Rename `doorman` → `service_provider`, reaproveitado para prestador externo
`Tenancy::Membership#role` e `Tenancy::Invitation#role` (enum duplicado) trocam o valor `doorman` por `service_provider`. `Registry::RegisterServiceProvider` — que hoje concede `Membership(role: "resident")` hardcoded ao dar acesso a um prestador externo — passa a conceder `role: "service_provider"`. Com isso, o mesmo role serve tanto para porteiro interno (que talvez nem tenha `Registry::Person` associada) quanto para prestador externo (que tem `Person(type: "service_provider")`) — a persona de frontend "Prestador" é alimentada por essas duas identidades de backend diferentes, unificadas por um único valor de `role`.

Alternativa descartada: manter `doorman` como está e expor também `Registry::Person#type` na sessão pra frontend cruzar os dois dados. Descartada porque exigiria dois campos em vez de um, e a distinção "porteiro interno vs prestador externo" não importa pra nenhuma decisão de UI hoje — as duas identidades têm exatamente a mesma necessidade de visibilidade (ver avisos, ver espaços comuns).

### `manager` continua distinto de `admin` no backend — só a persona de frontend os une por enquanto
Não generalizamos `manager` para `admin` no modelo de autorização: existe uma distinção já implementada e testada (`Notice::AvisoPolicy` rejeita `manager` do painel de confirmação de Aviso, só `admin` acessa), e o usuário sinalizou uma regra de negócio futura (só admin cadastra/remove síndicos; síndico não cadastra admin) que depende dessa separação continuar existindo no backend. A simplificação é só na camada de apresentação: nesta fase, `manager` e `admin` renderizam a mesma UI. Isso significa que um usuário `manager` pode, em teoria, clicar numa ação que o backend rejeita (o painel de confirmação de Aviso, quando essa tela existir) — aceito como limitação conhecida desta fase, não escondido silenciosamente: registrado aqui para quando a tela de Avisos for construída.

### Sessão do frontend ganha `role`; UI deriva "persona" a partir dele
`SessionsController#create` já busca a `Membership` pra validar login (`Tenancy::Membership.active.find_by(user:, condominium:)`) — só faltava incluir `role` na resposta. `authStore` (zustand) passa a guardar esse campo. Uma função pura (`getPersona(role)`) mapeia os 4 valores de `role` pras 3 personas:
```
admin, manager   -> "admin"
service_provider -> "service_provider"
resident         -> "resident"
```
Cada tela/item de sidebar decide o que renderizar a partir dessa persona, não do `role` cru — evita espalhar a regra "admin e manager são a mesma coisa" por todo o código.

### Sidebar mostra os 5 itens do domínio completo desde já, com placeholder para o que não existe
Ordem de prioridade (dada pelo usuário): Unidades, Avisos, Faturas, Espaços, Reservas. Cada persona vê um subconjunto:
```
ADMIN                MORADOR              PRESTADOR
Unidades             Minha Unidade        Avisos
Avisos               Avisos               Espaços
Faturas              Faturas
Espaços              Espaços
Reservas             Reservas
```
Só "Espaços" tem tela funcional nesta change. Os demais itens aparecem desabilitados (ou levam a um placeholder simples "em breve") — decisão explícita do usuário para já comunicar a forma final do produto e evitar reabrir o componente `Sidebar` a cada módulo novo.

### CommonArea: tabela para admin, cards para morador/prestador
Admin vê uma listagem orientada a configuração — `<Table>` do shadcn, com ação de editar (abre modal) e toggle de `ativo` inline. Morador e prestador veem cards — mais legível para poucos campos por registro (nome, capacidade, horário, regras, status), sem ações de edição. As duas views leem o mesmo endpoint (`GET /api/v1/common_areas`, já aberto a qualquer `Membership` ativo) — a diferença é só de apresentação e de quais controles aparecem, decidida pela persona.

### Criar/editar em modal (Dialog), não rota própria
Confirmado pelo usuário como preferência para esta fase — CRUD rápido não precisa de navegação de página inteira. Usa o componente `Dialog` do shadcn (a gerar). Este é o padrão que os próximos módulos com CRUD administrativo (Registry: Building/Unit; Billing: Taxa) devem seguir, salvo decisão em contrário quando chegar a vez deles.

### Componentes shadcn novos: Table, Badge, Dialog, Textarea, Switch
Gerados via `npx shadcn add`, sem rodar `init` (mesma situação de `frontend-auth-onboarding` — os componentes funcionam sem o bloco `@theme`, só ficam visualmente crus; não é escopo desta change corrigir isso).

## Risks / Trade-offs

- [Rename de `doorman` é uma mudança de contrato já testada — qualquer código ou dado externo que dependesse do valor `"doorman"` quebra] → Mitigação: projeto em estágio de aprendizado, sem dado de produção; grep já mapeou todos os 9 arquivos afetados (3 specs, 3 specs de teste, 3 arquivos de app) antes de começar a implementação.
- [`manager` ver a mesma UI de `admin` mas apanhar erro em ações que o backend restringe é uma experiência ruim, mesmo que rara] → Mitigação: hoje só existe 1 ação assim (painel de confirmação de Aviso), e essa tela nem existe ainda nesta change — o risco só se materializa quando `Notice` ganhar frontend, momento em que pode ser revisitado.
- [Sidebar com itens placeholder pode comunicar uma promessa de prazo que não existe] → Mitigação: aceito pelo usuário conscientemente, com o objetivo de comunicar a forma final do produto desde já.

## Migration Plan

Sem migration de banco (`role` é enum de aplicação, não de coluna tipada). Mudança de comportamento pura: dado existente com `role: "doorman"` (se houver, em ambiente de dev) precisaria ser atualizado manualmente ou recriado — aceitável neste estágio do projeto.

## Open Questions

Nenhuma pendente — todas as decisões foram fechadas durante a exploração que precedeu esta proposta.
