## ADDED Requirements

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

### Requirement: Membership preparado para revogação futura
`Membership` SHALL possuir um status (`active | revoked`) que permita revogação de acesso, mesmo que o gatilho automático dessa revogação (baseado em `Registry`) ainda não exista.

#### Scenario: Membership revogado não concede acesso
- **WHEN** um `Membership` com status `revoked` é usado para login em seu `Condominium`
- **THEN** o login é rejeitado, mesmo com credenciais corretas e token de sessão previamente válido
