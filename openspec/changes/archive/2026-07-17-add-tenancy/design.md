## Context

Neighbry parte de um esqueleto migrado (`migrate-skeleton-to-monolith`, já arquivada) que só tem `User`/`JwtDenylist` via Devise. Nenhum bounded context de domínio existe. O projeto é multi-tenant desde a concepção (`openspec/project.md` fala em "administração de condomínios", plural), mas isso nunca tinha sido modelado explicitamente — decisão tomada em sessão de exploração (`/opsx:explore`) antes desta proposta.

`Tenancy` é o primeiro bounded context do projeto e introduz a estrutura de módulos (`app/domains/<context>/`) que o `CLAUDE.md` previa sem ainda existir na prática. Toda decisão de isolamento de tenant tomada aqui vira precedente para os bounded contexts seguintes (Registry, Billing, Notice, Access, CommonArea).

## Goals / Non-Goals

**Goals:**
- Modelar `Condominium` como raiz multi-tenant e `Membership` como o vínculo de acesso ao sistema entre `User` e `Condominium`.
- Resolver o tenant a partir da URL (subdomínio) antes de qualquer autenticação acontecer.
- Garantir que nenhuma senha jamais passe pelas mãos de quem não é o dono dela, mesmo durante convite.
- Deixar `Membership` pronto para ser revogado por evento de domínio de `Registry` no futuro, sem acoplar os dois módulos agora.

**Non-Goals:**
- Não modela `Registry` (Building/Unit/Person/Occupancy) — change separada (`add-registry-context`), a depender desta.
- Não implementa envio real de email — mantém a decisão já registrada em `local-dev-environment` de não ter infraestrutura de email neste estágio.
- Não implementa Postgres Row-Level Security nesta change — só deixa a porta aberta (ver Decisão 2).
- Não constrói onboarding self-service polido de condomínio — fluxo administrativo simples é suficiente.

## Decisions

### 1. Isolamento de tenant: `condominium_id` denormalizado em toda tabela de domínio

**Decisão**: toda tabela de qualquer bounded context (presente ou futuro) carrega `condominium_id` diretamente, mesmo quando derivável via join (ex: `Unit` já chegaria em `Condominium` via `Building`).

**Alternativa descartada**: confiar só em joins a partir da raiz (`Condominium → Building → Unit`) sem denormalizar. Descartada porque isolamento de tenant é o tipo de bug mais caro de deixar implícito — qualquer query que esqueça um join intermediário vaza dado entre condomínios. Denormalizar torna cada tabela auditável e filtrável sozinha, sem depender de nenhuma outra estar correta.

### 2. Row-Level Security como defesa em profundidade — avaliar na implementação, não obrigatório nesta change

**Decisão**: a aplicação deve resolver um "tenant atual" por request (ex: `ActiveSupport::CurrentAttributes`, resolvido a partir do subdomínio) e todo model de domínio deve escopar automaticamente por ele — nunca depender de que cada query lembre de filtrar manualmente. RLS no Postgres é a camada extra recomendada (o app erra, o banco não deixa passar), mas fica como decisão a confirmar durante a implementação desta change, não bloqueia a proposta.

**Alternativa descartada**: escopar manualmente com `where(condominium_id: ...)` em cada controller/query. Descartada pelo mesmo motivo do item 1 — depende de disciplina humana sem rede de segurança.

### 3. Login por subdomínio, não por digitação de tenant nem por lista pós-login

**Decisão**: cada `Condominium` tem um `slug` único, usado como subdomínio (`<slug>.neighbry.com/login`). O tenant é resolvido pela URL antes de qualquer credencial ser verificada.

**Alternativas descartadas**:
- **Digitação manual de tenant** (padrão AWS: usuário digita account ID/alias antes do login) — descartada porque a audiência do Neighbry (morador, síndico, porteiro) não tem por que memorizar um slug, ao contrário de um profissional técnico operando várias AWS accounts todo dia.
- **Login único + lista de condomínios pós-login** — mais simples de implementar (sem precisar de roteamento por subdomínio), mas foi preterida pela escolha explícita do usuário por subdomínio, que já resolve o tenant antes mesmo da tela de login aparecer.

### 4. Um único fluxo de convite — sem "cadastro completo vs parcial"

**Decisão**: convite gera um token seguro com validade. Em dev, o token/link volta na resposta da API e é mostrado na tela de quem convidou. Em produção, o mesmo token seria enviado por email — troca de canal, não de lógica. Só a pessoa convidada, ao aceitar, define sua própria senha.

**Alternativa descartada**: um modo "cadastro completo" onde quem convida já digita email+senha da pessoa convidada, pensado inicialmente como atalho de desenvolvimento. Descartada por risco de segurança real — permitiria que qualquer titular soubesse a senha de outra pessoa, mesmo que só por um instante. A troca por "mostrar o token na tela" resolve o mesmo problema de não depender de email em dev, sem esse risco, e sem duplicar lógica de fluxo.

### 5. `Membership` carrega o papel de acesso ao sistema; `Occupancy` (Registry, futuro) carrega o fato de moradia — nunca a mesma coisa

**Decisão**: `Membership.role` é `admin | manager | doorman | resident` — responde só "essa pessoa acessa este condomínio, e é staff ou morador comum". Não carrega nem `owner` nem `responsible` — isso é autorização fina que pertence a `Occupancy`, futuro agregado de `Registry`, referenciado por `Person`, nunca por `Membership`/`User` diretamente.

**Alternativa descartada**: fundir os dois conceitos num "papel único da pessoa". Descartada porque um síndico real é comumente também dono-morador da própria unidade — são fatos independentes (acesso ao sistema vs. fato de moradia) que coexistem na mesma pessoa sem depender um do outro.

### 6. `Membership` é 1:1 com `User` no v1 — um único condomínio, um único papel

**Decisão**: `Membership` é `(user_id, condominium_id, role)`, mas com unicidade em `user_id` sozinho — um `User` tem no máximo um `Membership` ativo em todo o sistema. Isso significa que, no v1, ninguém acumula papéis (ex: um síndico que também é morador-proprietário da própria unidade não é modelado — ele seria só `admin`, e a `Occupancy` dele em `Registry`, quando existir, fica sem `Membership` próprio associado).

**Motivação**: cardinalidade 1:1 elimina de raiz a necessidade de resolver "qual é o condomínio/papel ativo agora" em toda query e checagem de autorização — não existe "contexto ativo" pra escolher, porque só existe uma possibilidade. Isso foi uma reconsideração deliberada: multiplicidade parecia natural do ponto de vista de modelagem de domínio (ver alternativa descartada abaixo), mas o custo de manter toda a base de código — queries, políticas Pundit, resolução de sessão — condicionada a "qual dos vínculos" foi julgado maior que o benefício agora.

**Alternativa descartada**: `Membership` N:N entre `User` e `Condominium` (decisão original desta change, revertida). Modelava corretamente casos reais (síndico profissional administrando vários prédios, proprietário com unidades em condomínios diferentes), mas cada query e cada policy precisaria carregar/resolver qual vínculo está "ativo" na sessão atual — exatamente a complexidade de "contexto ativo" discutida e descartada para o fluxo de login. Fica registrada como possível v2, não como algo esquecido: `Membership` continua sendo uma entidade própria (não fundida em `User`) precisamente para que relaxar a constraint de unicidade seja a única mudança de schema necessária caso a v2 aconteça — não uma reestruturação.

### 7. Revogação de `Membership` por `Occupancy` fica preparada, não implementada

**Decisão**: `Membership` ganha um campo de status (`active | revoked`). A regra completa — revogar quando a última `Occupancy` ativa de uma pessoa naquele condomínio é encerrada — só pode ser implementada quando `Registry`/`Occupancy` existir. Nesta change, o campo de status existe e pode ser setado manualmente; a automação via evento de domínio (`Tenancy` reagindo a um evento tipo `OccupancyEnded` publicado por `Registry`) é trabalho da change `add-registry-context`, respeitando a regra do `CLAUDE.md` de comunicação entre módulos só via Domain Events, nunca chamada direta a model de outro módulo.

## Risks / Trade-offs

- **[Risco]** Esquecer de escopar uma query por `condominium_id` em algum lugar do código vaza dado entre tenants. → **Mitigação**: `condominium_id` denormalizado (Decisão 1) + `CurrentAttributes`/scope automático resolvido por request; considerar RLS como rede de segurança adicional na implementação.
- **[Risco]** Roteamento por subdomínio adiciona complexidade de infraestrutura local (DNS) que o projeto não tinha até agora. → **Mitigação**: `*.localhost` resolve para `127.0.0.1` automaticamente na maioria dos navegadores modernos, sem precisar editar `/etc/hosts`; validar isso concretamente durante a implementação.
- **[Risco]** Sem envio real de email, o fluxo de convite em produção nunca foi exercitado de ponta a ponta nesta change. → **Mitigação**: aceito como trade-off deliberado, consistente com a decisão já existente de não ter infraestrutura de email neste estágio (`local-dev-environment`); troca de canal isolada o suficiente para não exigir retrabalho de lógica quando email for adicionado.
- **[Trade-off]** `Membership.role = resident` não diz nada sobre `owner`/`responsible` — só fica coerente depois que `Registry` existir e a UI precisa lidar com esse hiato temporariamente. → aceito, pois `Registry` é a próxima change já planejada.

## Open Questions

- RLS entra nesta change ou fica para uma change de hardening posterior? (Decisão 2 deixa em aberto de propósito.)
- O onboarding de condomínio (`create-condominium`) precisa de alguma proteção (ex: só operador do sistema, sem self-service) nesta change, ou fica completamente aberto por enquanto? A proposta assume uso administrativo/manual por ora.
