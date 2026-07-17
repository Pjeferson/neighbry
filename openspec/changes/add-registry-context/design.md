## Context

`Tenancy` (arquivada) já existe como código real: `Condominium`, `Membership` (1:1 `User`↔`Condominium` no v1), `Invitation` (fluxo único e seguro de convite, token retornado na API em dev). `Registry` é o segundo bounded context do projeto, e o primeiro a depender de outro bounded context já implementado — isso força a decidir, pela primeira vez com código de verdade em jogo, como dois contexts se comunicam na prática, não só em teoria.

O modelo de domínio deste design nasceu de duas sessões de exploração (`/opsx:explore`). A segunda sessão inverteu a abordagem da primeira: em vez de definir regras de arquitetura e encaixar os fluxos de cadastro nelas, mapeamos primeiro todos os fluxos de cadastro possíveis (quem cadastra quem, o que nasce disso) e só depois derivamos a estrutura — o que revelou que a maioria dos fluxos convergia pra três primitivas, não uma dúzia de casos especiais.

## Goals / Non-Goals

**Goals:**
- Modelar `Building`, `Unit`, `Person`, `Occupancy` com os invariantes reais do domínio (proprietário e responsável são papéis distintos e mutuamente exclusivos por pessoa, cada um no máx. 1 ativo por unidade).
- Reduzir os fluxos de cadastro mapeados a um pequeno conjunto de service objects reutilizáveis, cada um com autorização própria.
- Definir com precisão como `Registry` integra com `Tenancy` já existente, sem violar o isolamento entre bounded contexts nem duplicar a lógica de convite/segurança já construída.

**Non-Goals:**
- Não modela `Billing`, `Notice`, `Access`, `CommonArea` — todos dependem de `Registry` existir primeiro, mas nenhum é escopo desta change.
- Não implementa self-signup (pessoa se cadastrando sozinha, pendente de aprovação) — avaliado e descartado explicitamente nesta rodada de exploração.
- Não implementa múltiplos ocupantes por unidade além do que já é suportado (múltiplas `Occupancy` por `Unit` já é o padrão; o que fica de fora é qualquer fluxo de aprovação/moderação de cadastro).
- Não resolve venda/transferência de titularidade como fluxo único — decompõe em duas ações já existentes (`EndOccupancy` do dono antigo + `RegisterOccupant` do novo), não há service dedicado a "transferência".

## Decisions

### 1. `Person` é por condomínio; CPF é a chave de reconciliação

**Decisão**: `Person` carrega `condominium_id` (como toda tabela de domínio) e tem índice único em `(condominium_id, cpf)`. Cadastrar alguém numa segunda unidade do mesmo condomínio busca por CPF antes de criar — reaproveita a `Person` existente, só cria uma nova `Occupancy`.

**Alternativa descartada**: `Person` global (sem `condominium_id`), compartilhada entre condomínios. Descartada porque quebraria o isolamento de tenant que é a base de `Tenancy`, e porque a mesma pessoa em dois condomínios diferentes não deveria compartilhar o mesmo registro de domínio — só o `User` (login) é global, nunca o dado de Registry.

### 2. `Occupancy`: dois flags booleanos independentes e mutuamente exclusivos por pessoa

**Decisão**: `owner: bool` e `responsible: bool` na mesma `Occupancy`, cada um no máx. 1 ativo por `Unit`, e nunca os dois `true` na mesma linha (o dono que administra diretamente simplesmente não tem `responsible` marcado em ninguém — o papel de responsável só existe quando o dono delega).

Isso veio de simplificar um desenho anterior (matriz proprietário×titular vs. inquilino×titular) que a própria pessoa que está definindo o domínio achou complexa demais — a versão final é mais simples e cobre os mesmos casos reais.

### 3. Hierarquia de autorização por Unit: owner > responsible > morador comum

**Decisão**: `owner` pode editar quem é `responsible` e editar moradores comuns; `responsible` só edita moradores comuns; morador comum só edita o próprio perfil. `responsible` não pode se autorremover — só `owner` revoga/troca (limitação deliberada do v1, não uma omissão).

### 4. Três service objects cobrem os fluxos de cadastro mapeados

**Decisão**:
- `Registry::RegisterOccupant(unit, person_data, owner:, responsible:, grant_access:)` — busca/cria `Person` por CPF, cria `Occupancy`, opcionalmente concede acesso.
- `Registry::RegisterServiceProvider(person_data, grant_access:)` — cria `Person(type: service_provider)`, sem `Unit`/`Occupancy`.
- `Registry::EndOccupancy(occupancy)` — encerra uma `Occupancy` existente.

Cada um coberto por uma policy que decide **quem** pode chamar pra qual unidade, não uma lógica diferente por fluxo. Isso nasceu de mapear os fluxos de cadastro (admin cadastra dono, admin cadastra responsável direto, dono delega responsável, responsável cadastra morador comum, admin/dono cadastra prestador) e perceber que quase todos são a mesma operação variando só o ator e os flags — a exceção genuína é `EndOccupancy`, que é uma ação distinta (encerrar, não criar).

**Alternativa descartada**: um service dedicado por fluxo (ex: `RegisterOwner`, `RegisterResident`, `DelegateResponsible`, `TransferOwnership`...). Descartada por criar 6+ services quase idênticos, com risco real de divergência de comportamento entre eles ao longo do tempo (ex: corrigir uma validação num e esquecer nos outros).

### 5. Remoção de titularidade de `owner` é admin-only; troca de dono não é um fluxo dedicado

**Decisão**: só admin encerra uma `Occupancy` com `owner: true` — é tratado como operação administrativa/sensível (mudança de propriedade), não algo que o próprio dono decide sozinho pela UI. Registrar o novo dono depois é só chamar `RegisterOccupant` de novo — não existe um service "TransferOwnership".

### 6. Integração com `Tenancy`: Open Host Service síncrono numa direção, evento na outra

**Decisão**: `Registry` chama `Tenancy::InviteMember`/`Tenancy::AcceptInvitation` diretamente (chamada síncrona a um service object, nunca a um model) quando `grant_access: true`. Isso é necessário porque a resposta HTTP do cadastro precisa devolver o token do convite na hora (ambiente de dev, decisão já tomada em `add-tenancy`) — um evento assíncrono não serviria pra esse caso.

Na direção contrária, `Tenancy` nunca chama nada de `Registry`: `AcceptInvitation` passa a publicar um evento de domínio (`InvitationAccepted`, com `invitation_id` + `user_id`) sem saber quem está ouvindo. `Registry` se inscreve nesse evento e, ao recebê-lo, procura a `Person` com `pending_invitation_id` igual ao `invitation_id` do evento (guardado no momento em que `Registry` chamou `InviteMember`) e preenche `Person.user_id`. A correlação é por `invitation_id` explícito, nunca por email — email é heurística, `invitation_id` é exato porque `Registry` já sabia qual convite era de qual `Person` desde o início.

**Por que isso não viola o isolamento entre bounded contexts**: a regra do `CLAUDE.md` ("comunicação apenas via Domain Events internos, nunca chamada direta a model de outro módulo") tem duas leituras possíveis — uma estrita (nenhuma chamada direta, nunca) e uma que distingue "nunca no *modelo*" (correto) de "nunca no *service*" (over-broad). A leitura adotada aqui segue o Context Map de Vernon (*Implementing DDD*): isso é o padrão **Open Host Service** — um contexto expõe uma API pública (o service object) que outro consome diretamente — combinado com relação **Customer/Supplier** (`Registry` é cliente de `Tenancy`, dependência unidirecional e explícita, nunca circular). Isso é diferente de **Shared Kernel** (compartilhar modelo) ou de acessar o `ActiveRecord` interno de outro módulo, que continuam proibidos. Evento continua sendo o mecanismo pra qualquer comunicação que não precise ser síncrona — como a revogação de `Membership` quando uma `Occupancy` termina (`add-tenancy` Decisão 7), e agora a reconciliação de `Person.user_id` na direção oposta.

**Alternativa descartada**: `Registry` também se comunicar com `Tenancy` só por evento (ex: publicar `AccessRequested` e esperar `Tenancy` reagir). Descartada porque o fluxo precisa ser síncrono — quem cadastra o morador vê o token do convite na mesma resposta HTTP, não numa tela separada esperando um evento assíncrono ser processado.

### 7. `Person` com `type: service_provider` nunca tem `Occupancy`

**Decisão**: prestador de serviço é uma `Person` sem nenhuma `Occupancy` — não ocupa unidade. `RegisterServiceProvider` é um service à parte de `RegisterOccupant`, sem conceito de `Unit` nenhum.

## Risks / Trade-offs

- **[Risco]** `condominium_id` denormalizado em 4 tabelas (`Building`, `Unit`, `Person`, `Occupancy`) em vez de só `Building` — mais colunas/índices a manter. → **Mitigação**: já é requirement obrigatório da spec de `tenancy` (`Isolamento de dado por tenant`), não uma escolha nova; o ganho (índice direto, RLS futuro viável, defesa contra join esquecido) já foi justificado e aceito na exploração anterior.
- **[Risco]** Correlação de `Person.user_id` via evento assíncrono pode ter atraso ou falhar silenciosamente (job do Sidekiq falha, evento nunca processado). → **Mitigação**: a person continua funcional mesmo sem `user_id` preenchido (o cadastro de domínio nunca dependeu de acesso); vale considerar um job de reconciliação periódico como rede de segurança, mas fica como possível melhoria futura, não bloqueante pra esta change.
- **[Trade-off]** `RegisterOccupant` genérico (um service pra vários fluxos) é menos explícito no código do que services nomeados por fluxo — quem lê `RegisterOccupant(owner: true)` precisa entender que isso é "cadastrar dono", não tem um nome próprio gritando isso. → aceito, porque o ganho de não duplicar lógica supera a perda de legibilidade, e a policy + os parâmetros deixam a intenção clara o suficiente.

## Open Questions

- Nenhuma pendente — os pontos que ficaram em aberto durante a exploração (self-signup, transferência como fluxo dedicado, quem revoga `owner`) foram todos resolvidos e registrados como decisão nas seções acima.
