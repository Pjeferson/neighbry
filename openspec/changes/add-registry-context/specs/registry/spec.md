## ADDED Requirements

### Requirement: Building pertence a exatamente um Condominium
O sistema SHALL representar cada bloco/torre de um condomínio como um `Building`, pertencente a exatamente um `Condominium`.

#### Scenario: Building sem Condominium é rejeitado
- **WHEN** um `Building` é criado sem `condominium_id`
- **THEN** a criação falha com erro de validação

### Requirement: Unit pertence a exatamente um Building
O sistema SHALL representar cada unidade como um `Unit`, pertencente a exatamente um `Building`.

#### Scenario: Unit sem Building é rejeitado
- **WHEN** um `Unit` é criado sem `building_id`
- **THEN** a criação falha com erro de validação

### Requirement: Person é reconciliada por CPF dentro do condomínio
O sistema SHALL representar cada pessoa conhecida pelo condomínio como uma `Person`, única por `(condominium_id, cpf)`. Cadastrar uma pessoa já existente (mesmo CPF, mesmo condomínio) SHALL reaproveitar o registro existente em vez de criar um duplicado. `Person.type` SHALL ser fixo desde a criação — não SHALL existir fluxo para mudar o `type` de uma `Person` já cadastrada (v1; possível v2).

#### Scenario: CPF duplicado no mesmo condomínio reaproveita a Person
- **WHEN** uma `Person` é cadastrada com um CPF que já existe nesse `Condominium`
- **THEN** nenhuma `Person` nova é criada; a `Person` existente é reutilizada para a nova `Occupancy`

#### Scenario: CPF duplicado em condomínios diferentes cria Person distintas
- **WHEN** o mesmo CPF é cadastrado em dois `Condominium` diferentes
- **THEN** cada `Condominium` tem sua própria `Person`, sem vínculo entre elas

### Requirement: Occupancy liga Person a Unit com papéis mutuamente exclusivos
O sistema SHALL representar o vínculo entre uma `Person` e uma `Unit` através de uma `Occupancy`, contendo dois flags independentes: `owner` e `responsible`. Uma `Unit` SHALL ter no máximo uma `Occupancy` ativa com `owner: true`, e no máximo uma `Occupancy` ativa com `responsible: true`. A mesma `Occupancy` SHALL NOT ter `owner` e `responsible` simultaneamente `true`.

#### Scenario: Segundo owner ativo na mesma Unit é rejeitado
- **WHEN** uma `Unit` já tem uma `Occupancy` ativa com `owner: true` e uma segunda `Occupancy` com `owner: true` é criada para essa `Unit`
- **THEN** a criação falha com erro de validação

#### Scenario: Segundo responsible ativo na mesma Unit é rejeitado
- **WHEN** uma `Unit` já tem uma `Occupancy` ativa com `responsible: true` e uma segunda `Occupancy` com `responsible: true` é criada para essa `Unit`
- **THEN** a criação falha com erro de validação

#### Scenario: Owner e responsible não coexistem na mesma Occupancy
- **WHEN** uma `Occupancy` é criada ou atualizada com `owner: true` e `responsible: true` simultaneamente
- **THEN** a operação falha com erro de validação

#### Scenario: Mesma Person pode ter Occupancy em várias Unit do mesmo condomínio
- **WHEN** uma `Person` já possui uma `Occupancy` ativa numa `Unit` e uma nova `Occupancy` é criada para essa mesma `Person` em outra `Unit` do mesmo `Condominium`
- **THEN** ambas as `Occupancy` coexistem sem conflito

#### Scenario: Cadastro duplicado da mesma Person na mesma Unit é rejeitado
- **WHEN** uma `Person` já possui uma `Occupancy` ativa numa `Unit` e uma nova `Occupancy` é criada para essa mesma `Person` nessa mesma `Unit`
- **THEN** a criação falha com erro de validação de ocupação já cadastrada

### Requirement: Hierarquia de autorização por Unit
Um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` SHALL poder cadastrar qualquer papel (`owner`, `responsible`, morador comum) em qualquer `Unit`. Dentro de uma `Unit`, `owner` SHALL poder gerenciar quem é `responsible` e editar moradores comuns; `responsible` SHALL poder editar moradores comuns mas SHALL NOT poder alterar quem é `owner` ou `responsible`; morador comum (sem `owner` nem `responsible`) SHALL poder editar apenas o próprio perfil.

#### Scenario: Admin cadastra o owner de uma Unit
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` registra uma `Person` como `owner` de uma `Unit`
- **THEN** a operação é permitida

#### Scenario: Admin cadastra o responsible de uma Unit diretamente
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` registra uma `Person` como `responsible` de uma `Unit`, sem que essa `Unit` tenha `owner` cadastrado
- **THEN** a operação é permitida

#### Scenario: Owner define o responsible da própria Unit
- **WHEN** a `Person` com `owner: true` numa `Unit` designa outra `Person` como `responsible` dessa `Unit`
- **THEN** a operação é permitida

#### Scenario: Owner não define responsible de outra Unit
- **WHEN** a `Person` com `owner: true` numa `Unit` tenta designar `responsible` numa `Unit` diferente, onde não tem `Occupancy` ativa
- **THEN** a operação é rejeitada

#### Scenario: Responsible cadastra morador comum na própria Unit
- **WHEN** a `Person` com `responsible: true` numa `Unit` cadastra outra `Person` sem `owner` nem `responsible` nessa mesma `Unit`
- **THEN** a operação é permitida

#### Scenario: Responsible não revoga a si mesmo
- **WHEN** a `Person` com `responsible: true` tenta encerrar a própria `Occupancy` de responsável
- **THEN** a operação é rejeitada — apenas o `owner` da `Unit` pode fazer isso

#### Scenario: Morador comum não cadastra outras pessoas
- **WHEN** uma `Person` sem `owner` nem `responsible` numa `Unit` tenta cadastrar outra pessoa nessa `Unit`
- **THEN** a operação é rejeitada

### Requirement: Encerramento de owner é restrito a admin
Encerrar uma `Occupancy` com `owner: true` SHALL ser permitido apenas a um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` — nunca pelo próprio `owner` ou por um `responsible`.

#### Scenario: Owner não encerra a própria titularidade
- **WHEN** a `Person` com `owner: true` numa `Unit` tenta encerrar a própria `Occupancy`
- **THEN** a operação é rejeitada

#### Scenario: Admin encerra a Occupancy de um owner
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` encerra a `Occupancy` de `owner` de uma `Unit`
- **THEN** a operação é permitida e a `Occupancy` passa a ter `fim` preenchido

### Requirement: Person do tipo prestador de serviço nunca tem Occupancy
`Person` com `type: service_provider` SHALL NOT estar associada a nenhuma `Occupancy` — prestador de serviço não ocupa unidade. Um prestador SHALL poder ser cadastrado tanto por um `User` com `Membership(role: admin)` no `Condominium` quanto por uma `Person` com `owner: true` ou `responsible: true` em alguma `Unit` desse `Condominium`.

#### Scenario: Prestador cadastrado sem unidade
- **WHEN** uma `Person` com `type: service_provider` é cadastrada
- **THEN** nenhuma `Occupancy` é criada para essa `Person`

#### Scenario: Admin cadastra prestador
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` cadastra uma `Person` com `type: service_provider`
- **THEN** a operação é permitida

#### Scenario: Owner cadastra prestador
- **WHEN** a `Person` com `owner: true` numa `Unit` cadastra uma `Person` com `type: service_provider` nesse mesmo `Condominium`
- **THEN** a operação é permitida

#### Scenario: Morador comum não cadastra prestador
- **WHEN** uma `Person` sem `owner` nem `responsible` em nenhuma `Unit` tenta cadastrar uma `Person` com `type: service_provider`
- **THEN** a operação é rejeitada

### Requirement: Concessão de acesso ao cadastrar Person reaproveita o convite de Tenancy
`Person` SHALL NOT ter um campo de email — email só existe como parâmetro de entrada, exigido apenas quando a concessão de acesso é solicitada, e nunca é persistido em `Person` (após o aceite, o email de referência passa a ser `person.user.email`). Ao cadastrar uma `Person` (ocupante ou prestador) com concessão de acesso solicitada, o sistema SHALL invocar o fluxo de convite já existente em `Tenancy` (`InviteMember`) em vez de implementar um mecanismo de convite próprio. O identificador do convite resultante SHALL ser armazenado em `Person.pending_invitation_id` para reconciliação posterior. Se o email informado já corresponder a um `User` com `Tenancy::Membership` ativo, o cadastro SHALL ser rejeitado antes de qualquer convite ser criado.

#### Scenario: Cadastro com concessão de acesso gera convite
- **WHEN** uma `Person` é cadastrada com concessão de acesso solicitada e um email
- **THEN** um `Tenancy::Invitation` é criado para esse email, e o identificador desse convite fica associado à `Person` em `pending_invitation_id`

#### Scenario: Cadastro sem concessão de acesso não gera convite
- **WHEN** uma `Person` é cadastrada sem concessão de acesso solicitada
- **THEN** nenhum `Tenancy::Invitation` é criado, e a `Person` permanece sem `user_id` e sem `pending_invitation_id`

#### Scenario: Concessão de acesso rejeitada se o email já tem Membership
- **WHEN** o email informado na concessão de acesso já corresponde a um `User` com `Tenancy::Membership` ativo
- **THEN** o cadastro é rejeitado com erro de validação, e nenhum `Tenancy::Invitation` é criado

### Requirement: Reconciliação de acesso por identificador de convite, não por email
Quando um convite de acesso vinculado a uma `Person` é aceito, o sistema SHALL vincular o `User` resultante à `Person` correspondente usando o identificador do convite armazenado no momento da concessão — nunca por correspondência de email.

#### Scenario: Aceite de convite preenche o User da Person correta
- **WHEN** o convite associado a uma `Person` é aceito em `Tenancy`
- **THEN** a `Person` correspondente (identificada pelo identificador do convite, não pelo email) passa a ter `user_id` preenchido
