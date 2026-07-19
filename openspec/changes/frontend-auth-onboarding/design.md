## Context

`neighbry-frontend` tem hoje ~440 linhas: só autenticação (quebrada, ver proposal.md) e um dashboard placeholder. Nenhum outro bounded context tem tela. Esta é a primeira change que mexe em frontend e backend juntos no mesmo change — decisão consciente, não um desvio do padrão: o endpoint novo (`GET /api/v1/condominiums/:slug`) só existe para servir a UX de busca de condomínio, não tem razão de existir isolado do frontend que o consome. Mudanças anteriores (`add-tenancy`, `add-registry-context`, etc.) foram todas backend-only porque não havia frontend consumindo ainda.

`Tenancy` já resolve tenant por subdomínio no backend (`ResolvesTenant`, `config.action_dispatch.tld_length = 0` em dev). O frontend precisa espelhar essa resolução, mas com uma restrição de plataforma: **não é possível sobrescrever o header `Host` em `fetch`/`XHR` do navegador** — é um header protegido. A única forma de uma requisição do browser carregar o subdomínio certo é a própria URL de destino já conter esse subdomínio.

## Goals / Non-Goals

**Goals:**
- Cadastro de condomínio (com admin) funcionando de ponta a ponta pelo frontend, usando o endpoint que já existe (`POST /api/v1/condominiums`).
- Login funcionando de ponta a ponta, resolvido pelo subdomínio, com mensagens de erro que distinguem os 3 casos que o backend já retorna.
- Um usuário que não sabe (ou esqueceu) o endereço do seu condomínio consegue chegar lá a partir do host genérico, sem precisar decorar a URL.
- Estabelecer os primeiros componentes shadcn/ui reais, já que `components.json` está configurado mas nada foi gerado ainda — esta é a primeira tela nova, ponto natural para isso.

**Non-Goals:**
- Auto-login após onboarding — tecnicamente inviável de forma limpa (ver Decisões) e não traz ganho real de UX dado que o usuário já vai passar por uma navegação de página inteira de qualquer forma.
- Topologia de produção (domínio próprio por condomínio, reverse proxy, etc.) — só o mecanismo de dev (`*.localhost`) é resolvido agora; produção fica documentada como decisão futura.
- Fluxo de aceite de convite (`Tenancy::Invitation`) no frontend — existe no backend desde `add-tenancy`, mas não faz parte do escopo "cadastro + login".
- Qualquer tela dos outros bounded contexts — cada um é uma change própria subsequente.

## Decisions

### Roteamento por tenant: host genérico para descoberta, subdomínio para tudo o resto
Mesmo padrão usado por produtos multi-tenant reais (Slack, Notion, Basecamp): existe um ponto de entrada sem subdomínio (`localhost:5173`) cuja única função é "criar um condomínio novo" ou "me leve para o condomínio que eu já tenho" — nunca autenticação de fato. Login só existe dentro do subdomínio do tenant (`<slug>.localhost:5173/login`), porque é lá que a UX já sabe qual `Condominium` está em jogo (mesmo texto explicativo cabe na spec: ver `specs/tenancy/spec.md` desta change).

Alternativa descartada: pedir o slug do condomínio como campo dentro do próprio formulário de login, mantendo uma única origem para todo o frontend. Descartada porque não entrega a "sensação de personalização" pedida (a URL em si já devia comunicar "isso é o seu condomínio") e porque não resolve o problema de fundo — a API ainda precisaria do subdomínio certo na URL de requisição de qualquer forma, então a complexidade de montar a URL dinâmica existiria de todo jeito, só que escondida atrás de um campo de formulário em vez de estar na barra de endereço.

### Redirect é navegação de página inteira, não roteamento client-side
Trocar de `localhost:5173` para `acme.localhost:5173` é trocar de origin — `TanStack Router` (client-side) não alcança isso. O redirect pós-cadastro e o redirect pós-busca-de-condomínio usam `window.location.href`, aceitando o full reload como parte natural do fluxo (mesmo comportamento que produtos reais desse tipo têm ao trocar de workspace).

### Auto-login pós-cadastro: descartado, não só adiado
`localStorage` é isolado por origin. Um JWT obtido em `localhost:5173` (onboarding) não é visível em `acme.localhost:5173` (onde o app de fato roda) — não existe forma de "carregar" a sessão através da navegação de página inteira sem mecanismo adicional (ex: token de uso único na query string, trocado por sessão no destino). Isso agregaria complexidade e superfície de ataque (token efêmero em URL, visível em histórico/logs) para eliminar um único passo de login que o usuário já vai fazer de qualquer forma. Decisão: sempre pedir login após o redirect, seja pós-cadastro ou pós-busca.

### `GET /api/v1/condominiums/:slug` é público e não usa `ResolvesTenant`
Esse endpoint busca um `Condominium` pelo slug do PATH (não do subdomínio da requisição) — propositalmente diferente de todo outro endpoint do sistema, que resolve tenant pelo `Host`. Ele existe justamente para ser chamado do host genérico, onde não há subdomínio de tenant ainda. Retorna só `{ exists: true, name: "..." }` (ou 404) — nome do condomínio é informação não-sensível (já visível hoje na tela de convite/onboarding), suficiente para o "Entrando em {nome}" na tela de login e para a confirmação antes do redirect. Nenhum dado de membros, unidades ou billing é exposto.

Reuso: o mesmo endpoint serve dois consumidores — (1) a busca no host genérico antes do redirect, e (2) opcionalmente a própria tela `/login` do subdomínio, que pode chamá-lo (usando o subdomínio atual como slug) para mostrar o nome do condomínio e tratar graciosamente o caso de alguém cair num subdomínio que não existe (em vez de renderizar um formulário de login para um tenant inexistente).

### CORS precisa aceitar origin dinâmico por subdomínio
`config/initializers/cors.rb` hoje só permite o origin exato `http://localhost:5173` — incompatível com a base de URL dinâmica desta change, que gera requisições de `acme.localhost:5173`, `outrocondo.localhost:5173`, etc., cada um um origin diferente pro CORS. Passa a usar regex (`/\Ahttp:\/\/([a-z0-9-]+\.)?localhost:5173\z/`) para aceitar o host genérico e qualquer subdomínio de tenant em dev. Não descoberto na exploração inicial — encontrado ao revisar o arquivo antes de começar a implementação; sem esse ajuste o fluxo inteiro quebra assim que o navegador chega no subdomínio do tenant.

### Slug informado pelo usuário é normalizado antes de qualquer uso
`Tenancy::Condominium#slug` é validado no backend com `/\A[a-z0-9]+(-[a-z0-9]+)*\z/` — minúsculo, sem espaços. Qualquer slug capturado de input do usuário (campo "localizar condomínio") é normalizado (trim + lowercase) no frontend antes da chamada de existência e antes de montar a URL de redirect, para não falhar silenciosamente por diferença de caixa (Postgres compara `slug` como string exata, não case-insensitive).

### Slug do formulário de cadastro é sugerido a partir do nome, mas editável
Ao digitar o nome do condomínio, o campo de slug é preenchido automaticamente com uma versão slugificada (minúsculo, espaços viram hífen, caracteres fora de `[a-z0-9-]` removidos) — mesmo padrão usado por GitHub/Notion/Slack para reduzir fricção sem tirar controle do usuário. O campo continua editável manualmente a qualquer momento; depois de editado manualmente, para de re-sincronizar automaticamente com o nome (comportamento padrão desse tipo de campo "linked until touched").

### `api.ts`: base da API derivada do hostname atual, não mais fixa
```ts
const apiHost = `${window.location.hostname}:${import.meta.env.VITE_API_PORT ?? "3001"}`;
const API_BASE = import.meta.env.VITE_API_URL ?? `${window.location.protocol}//${apiHost}`;
```
`VITE_API_URL` continua existindo como escape hatch total (para builds/ambientes onde essa heurística não se aplica, ex: produção). Sem override, a heurística funciona igual em `localhost:5173→localhost:3001` e `acme.localhost:5173→acme.localhost:3001` porque o hostname já carrega o subdomínio certo — só a porta muda.

### Erros de login diferenciados
`SessionsController#create` já retorna `condominium_not_found` (404), `invalid_credentials` (401) e `no_active_membership_for_tenant` (401) como códigos distintos. A UI trata os três com mensagens diferentes — o caso de "sem membership neste tenant" é genuinamente uma situação diferente de senha errada (a pessoa pode ter conta em outro condomínio) e merece dizer isso, não "email ou senha inválidos".

### Primeiros componentes shadcn/ui
`components.json` já define `style: default`, `baseColor: slate`, aliases prontos — só faltava gerar componentes. Esta change gera o mínimo necessário para os formulários novos (Button, Input, Label, Card), via CLI do shadcn, em vez de continuar com HTML+Tailwind cru como as telas atuais fazem. Não é refatoração das telas antigas (que serão substituídas de qualquer forma) — é estabelecer o padrão pra frente.

## Risks / Trade-offs

- [Heurística de troca de porta em `api.ts` não serve produção, onde frontend e API provavelmente não compartilham hostname+porta previsível] → Mitigação: `VITE_API_URL` já é o escape hatch; produção fica como decisão explícita futura, não bloqueia esta change.
- [Full page reload no redirect perde qualquer estado de UI em memória (ex: TanStack Query cache)] → Mitigação: aceitável — não há dado carregado relevante nesse ponto do fluxo (usuário acabou de chegar).
- [`GET /api/v1/condominiums/:slug` público permite enumerar slugs existentes por força bruta] → Mitigação: aceitável para esta fase — mesma exposição que uma URL de login (`acme.localhost`) já teria; sem rate limit nesta v1, documentado como aceitável dado o estágio do projeto (aprendizado, sem dado real de produção).

## Migration Plan

Aditivo no backend (rota nova, sem migration). No frontend, substitui arquivos existentes (`RegisterPage.tsx`, `useAuth.ts`, `LoginPage.tsx`, `api.ts`, estrutura de `routes/`) — sem dado persistido no cliente que precise de migração (só token em `localStorage`, que continua compatível).

## Open Questions

Nenhuma pendente — decisões fechadas durante a exploração que precedeu esta proposta.
