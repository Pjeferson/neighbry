# tenancy

## Purpose

Capability introduzida por `add-tenancy`. Fundação multi-tenant do Neighbry:
`Condominium` como raiz de isolamento, `Membership` como vínculo de acesso ao
sistema entre `User` e `Condominium`, e o fluxo de convite (`Invitation`) que
concede esse acesso. Login é resolvido por subdomínio antes de qualquer
autenticação. Todo bounded context de domínio (Registry, Billing, Notice,
Access, CommonArea) depende desta capability para escopar seus dados por
tenant.

## Requirements

### Requirement: Condomínio como raiz multi-tenant
O sistema SHALL representar cada condomínio atendido como um `Condominium`, com um `slug` único usado para identificar o tenant na URL de acesso.

#### Scenario: Slug único
- **WHEN** um `Condominium` é criado com um `slug` já usado por outro `Condominium`
- **THEN** a criação falha com erro de validação, sem persistir o registro duplicado

### Requirement: Isolamento de dado por tenant
Toda tabela de domínio do sistema (em qualquer bounded context, presente ou futuro) SHALL carregar `condominium_id` diretamente, mesmo quando o valor for derivável por join a partir de outra tabela.

#### Scenario: Tabela de domínio sem condominium_id
- **WHEN** uma migration cria uma tabela pertencente a um bounded context de domínio
- **THEN** a tabela possui uma coluna `condominium_id` não-nula referenciando `condominiums`

### Requirement: Membership vincula User a Condominium com papel de acesso
O sistema SHALL representar o acesso de um `User` a um `Condominium` através de um `Membership`, contendo um papel (`role`) que determina o nível de acesso ao sistema naquele condomínio. No v1, um `User` SHALL pertencer a no máximo um `Condominium`, com um único `role` — multiplicidade fica fora de escopo (possível v2).

#### Scenario: Um User não pode ter dois Memberships
- **WHEN** uma tentativa de criar um segundo `Membership` para um `User` que já possui um `Membership` (em qualquer `Condominium`) ocorre
- **THEN** a criação falha com erro de validação

### Requirement: Papéis de Membership
O `role` de `Membership` SHALL ser um dos seguintes valores: `admin`, `manager`, `doorman`, `resident`. `admin`, `manager` e `doorman` são papéis de staff/administração do condomínio; `resident` é o papel padrão de morador comum sem privilégio administrativo.

#### Scenario: Papel inválido rejeitado
- **WHEN** um `Membership` é criado com um `role` fora do conjunto `admin | manager | doorman | resident`
- **THEN** a criação falha com erro de validação

### Requirement: Convite de acesso via token único
O sistema SHALL conceder acesso a um `Condominium` exclusivamente através de um fluxo de convite (`Invitation`) com token seguro e prazo de expiração. Nenhuma pessoa diferente da convidada SHALL definir a senha da conta resultante.

#### Scenario: Convite gera token com expiração
- **WHEN** um `Membership` é convidado para um `Condominium`
- **THEN** um `Invitation` é criado com um token único e uma data de expiração futura

#### Scenario: Aceite de convite ativa o Membership
- **WHEN** a pessoa convidada acessa o link do convite antes da expiração e define sua própria senha
- **THEN** um `User` é criado ou vinculado a partir do email do convite, e o `Membership` correspondente passa a `active`

#### Scenario: Convite expirado não pode ser aceito
- **WHEN** a pessoa convidada tenta aceitar um `Invitation` após a data de expiração
- **THEN** o aceite é rejeitado e nenhum `Membership` é ativado

#### Scenario: Convite aceito por quem já tem Membership é rejeitado
- **WHEN** o email do `Invitation` corresponde a um `User` que já possui um `Membership` (neste ou em outro `Condominium`)
- **THEN** o aceite é rejeitado, sem criar um segundo `Membership`

#### Scenario: Ninguém além do convidado define a senha
- **WHEN** qualquer fluxo de criação de `Membership` é exercitado
- **THEN** não existe endpoint ou parâmetro que permita a quem convida definir a senha da pessoa convidada

### Requirement: Canal de entrega do convite isolado do domínio
A entrega do link de convite SHALL ser uma decisão de infraestrutura isolada da lógica de domínio, de forma que trocar o canal (tela vs. email) não exija mudança nas regras de negócio do convite.

#### Scenario: Ambiente sem infraestrutura de email
- **WHEN** um `Invitation` é criado no ambiente de desenvolvimento local
- **THEN** o link de convite é retornado na resposta da API, sem depender de envio de email

### Requirement: Login resolvido por subdomínio
O sistema SHALL resolver o `Condominium` (tenant) a partir do subdomínio da requisição antes de validar credenciais de login. Login SHALL falhar se o `User` autenticado não possuir `Membership` ativo naquele `Condominium`.

#### Scenario: Login bem-sucedido no subdomínio correto
- **WHEN** um `User` com `Membership` ativo no `Condominium` do slug `acme` faz login em `acme.neighbry.com`
- **THEN** o login é aceito e a sessão fica escopada a esse `Condominium`

#### Scenario: Login rejeitado sem Membership no tenant
- **WHEN** um `User` sem `Membership` ativo no `Condominium` do slug `acme` tenta logar em `acme.neighbry.com`
- **THEN** o login é rejeitado, mesmo que as credenciais (email/senha) estejam corretas

### Requirement: Onboarding de condomínio novo
O sistema SHALL prover um fluxo de criação de `Condominium` que, numa única operação, cria o `Condominium` e o primeiro `User` com `Membership(role: admin)` vinculado a ele.

#### Scenario: Criação de condomínio cria o admin junto
- **WHEN** um novo `Condominium` é criado através do fluxo de onboarding
- **THEN** um `User` e um `Membership` com `role: admin` para esse `Condominium` são criados na mesma operação

### Requirement: Existência de Condominium pode ser consultada publicamente por slug
O sistema SHALL permitir que qualquer cliente, sem autenticação, consulte se existe um `Condominium` para um dado slug, retornando apenas informação não-sensível (nome). Essa consulta SHALL ser feita pelo slug informado explicitamente, não pelo subdomínio da requisição.

#### Scenario: Slug existente retorna confirmação com nome
- **WHEN** um cliente consulta a existência de um `Condominium` para um slug que existe
- **THEN** a resposta confirma a existência e inclui o nome do `Condominium`

#### Scenario: Slug inexistente retorna não encontrado
- **WHEN** um cliente consulta a existência de um `Condominium` para um slug que não existe
- **THEN** a resposta indica que não foi encontrado, sem expor mais detalhes

#### Scenario: Consulta não expõe dados sensíveis
- **WHEN** um cliente sem autenticação consulta a existência de um `Condominium`
- **THEN** a resposta não inclui membros, unidades, faturas ou qualquer dado além do nome do `Condominium`

### Requirement: Usuário é direcionado ao subdomínio do seu Condominium para autenticar
O sistema SHALL direcionar o usuário para autenticação no endereço específico do subdomínio do `Condominium` — tanto após concluir o onboarding de um `Condominium` novo, quanto após localizar um `Condominium` existente por slug. O sistema SHALL NOT autenticar o usuário fora do subdomínio do `Condominium` ao qual ele pertence.

#### Scenario: Após onboarding, usuário é direcionado ao subdomínio do novo Condominium
- **WHEN** um `Condominium` novo é criado através do fluxo de onboarding
- **THEN** o admin recém-criado é direcionado para autenticar no subdomínio desse `Condominium`, não no ponto de entrada genérico onde o onboarding ocorreu

#### Scenario: Após localizar um Condominium existente, usuário é direcionado ao seu subdomínio
- **WHEN** um usuário localiza, pelo slug, um `Condominium` ao qual já pertence
- **THEN** ele é direcionado para autenticar no subdomínio desse `Condominium`

#### Scenario: Ponto de entrada genérico não autentica ninguém
- **WHEN** um usuário está no ponto de entrada genérico (sem subdomínio de nenhum `Condominium`)
- **THEN** nenhuma tentativa de autenticação com credenciais é aceita nesse ponto — apenas onboarding de `Condominium` novo ou localização de `Condominium` existente

### Requirement: Membership preparado para revogação futura
`Membership` SHALL possuir um status (`active | revoked`) que permita revogação de acesso, mesmo que o gatilho automático dessa revogação (baseado em `Registry`) ainda não exista.

#### Scenario: Membership revogado não concede acesso
- **WHEN** um `Membership` com status `revoked` é usado para login em seu `Condominium`
- **THEN** o login é rejeitado, mesmo com credenciais corretas e token de sessão previamente válido

### Requirement: Evento de domínio publicado ao aceitar convite
Ao ativar um `Membership` através do aceite de um `Invitation`, o sistema SHALL publicar um evento de domínio contendo o identificador do convite e o identificador do `User` resultante, sem conhecimento de quem (se alguém) está inscrito para recebê-lo.

#### Scenario: Aceite de convite publica evento com invitation_id e user_id
- **WHEN** um `Invitation` é aceito com sucesso e o `Membership` correspondente é ativado
- **THEN** um evento de domínio é publicado contendo o identificador desse `Invitation` e o identificador do `User` ativado

#### Scenario: Publicação do evento não depende de nenhum outro bounded context
- **WHEN** o evento de aceite de convite é publicado
- **THEN** `Tenancy` não faz nenhuma chamada direta a código de outro bounded context — a publicação ocorre independentemente de existir algum assinante

### Requirement: Novo convite substitui convite pendente anterior do mesmo email
Ao convidar um email que já possui um `Invitation` pendente (não aceito) no mesmo `Condominium`, o sistema SHALL invalidar o convite pendente anterior e criar um novo `Invitation` — nunca dois convites pendentes simultâneos para o mesmo email no mesmo `Condominium`. Isso cobre tanto o reenvio de um convite expirado quanto qualquer nova tentativa de convite antes do anterior ser aceito.

#### Scenario: Convidar de novo invalida o convite pendente anterior
- **WHEN** um email que já possui um `Invitation` pendente é convidado novamente para o mesmo `Condominium`
- **THEN** o `Invitation` anterior deixa de poder ser aceito, e um novo `Invitation` é criado com novo `id`, `token` e `expires_at`

#### Scenario: Convite já aceito não é afetado por um novo convite
- **WHEN** um email cujo `Invitation` anterior já foi aceito é convidado novamente
- **THEN** um novo `Invitation` é criado normalmente, sem qualquer efeito sobre o `Membership` já ativo

### Requirement: Evento de domínio publicado ao onboardar condomínio
Ao criar um `Condominium` através do fluxo de onboarding, o sistema SHALL publicar um evento de domínio contendo o identificador do `Condominium` criado, sem conhecimento de quem (se alguém) está inscrito para recebê-lo.

#### Scenario: Onboarding publica evento com condominium_id
- **WHEN** um `Condominium` é criado com sucesso através do fluxo de onboarding
- **THEN** um evento de domínio é publicado contendo o identificador desse `Condominium`

#### Scenario: Publicação do evento não depende de nenhum outro bounded context
- **WHEN** o evento de onboarding de condomínio é publicado
- **THEN** `Tenancy` não faz nenhuma chamada direta a código de outro bounded context — a publicação ocorre independentemente de existir algum assinante
