## ADDED Requirements

### Requirement: CommonArea é cadastrado apenas por admin
O sistema SHALL permitir que apenas um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` crie um `CommonArea`, com `nome`, `descricao`, `capacidade`, `horario_funcionamento` e `regras_uso`.

#### Scenario: Admin cadastra um CommonArea
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` cadastra um `CommonArea` com `nome` e `capacidade`
- **THEN** o `CommonArea` é criado com `ativo: true`

#### Scenario: Não-admin não cadastra CommonArea
- **WHEN** um `User` sem `Membership(role: admin)` no `Condominium` tenta cadastrar um `CommonArea`
- **THEN** a operação é rejeitada

### Requirement: CommonArea é editável livremente pelo admin
Diferente de `Taxa` e `Aviso`, um `CommonArea` SHALL NOT ter restrição de imutabilidade — qualquer campo pode ser alterado por um admin após a criação.

#### Scenario: Admin edita nome e capacidade de um CommonArea existente
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` altera `nome` ou `capacidade` de um `CommonArea` já persistido
- **THEN** a alteração é aceita e persistida

#### Scenario: Não-admin não edita CommonArea
- **WHEN** um `User` sem `Membership(role: admin)` no `Condominium` tenta editar um `CommonArea`
- **THEN** a operação é rejeitada

### Requirement: CommonArea pertence ao Condominium, sem vínculo com Building
Um `CommonArea` SHALL pertencer diretamente a um `Condominium`, sem referência a nenhuma `Registry::Building`.

#### Scenario: CommonArea criado sem building_id
- **WHEN** um `CommonArea` é cadastrado
- **THEN** o registro não possui nenhuma referência a `Building`

### Requirement: Listagem de CommonArea é aberta a qualquer Membership ativo
O sistema SHALL permitir que qualquer `User` com `Tenancy::Membership` ativo no `Condominium` (qualquer `role`) consulte a listagem de `CommonArea` desse condomínio.

#### Scenario: Morador consulta a listagem de espaços comuns
- **WHEN** um `User` com `Membership(role: resident, status: active)` no `Condominium` consulta a listagem de `CommonArea`
- **THEN** a consulta é permitida

#### Scenario: Staff consulta a listagem de espaços comuns
- **WHEN** um `User` com `Membership(role: manager, status: active)` ou `Membership(role: doorman, status: active)` no `Condominium` consulta a listagem de `CommonArea`
- **THEN** a consulta é permitida

#### Scenario: Usuário sem Membership ativo no condomínio não consulta a listagem
- **WHEN** um `User` sem `Membership` ativo no `Condominium` tenta consultar a listagem de `CommonArea` desse condomínio
- **THEN** a consulta é rejeitada

### Requirement: CommonArea inativo permanece visível na listagem
`ativo: false` SHALL representar indisponibilidade temporária (ex: reforma), não um registro incorreto. A listagem de `CommonArea` SHALL continuar incluindo registros com `ativo: false`, com o status exposto, em vez de ocultá-los.

#### Scenario: CommonArea inativo aparece na listagem com status
- **WHEN** um `CommonArea` com `ativo: false` é consultado na listagem
- **THEN** ele aparece no resultado, com `ativo: false` visível
