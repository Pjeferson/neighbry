## MODIFIED Requirements

### Requirement: Destinatários de todos, moradores e staff são resolvidos por Membership
Para `Aviso` com `tipo: todos`, o sistema SHALL considerar destinatário todo `User` com `Tenancy::Membership(status: active)` no `Condominium`. Para `tipo: moradores`, apenas `Membership(role: resident, status: active)`. Para `tipo: staff`, apenas `Membership(role: admin | manager | service_provider, status: active)`.

#### Scenario: Aviso tipo todos inclui staff e moradores
- **WHEN** um `Aviso` com `tipo: todos` é criado num `Condominium` com admins, staff e moradores ativos
- **THEN** todos eles são incluídos como destinatários

#### Scenario: Aviso tipo moradores exclui staff
- **WHEN** um `Aviso` com `tipo: moradores` é criado
- **THEN** apenas `User` com `Membership(role: resident)` são incluídos como destinatários

#### Scenario: Aviso tipo staff inclui admin, manager e service_provider
- **WHEN** um `Aviso` com `tipo: staff` é criado
- **THEN** `User` com `Membership(role: admin)`, `Membership(role: manager)` e `Membership(role: service_provider)` são todos incluídos como destinatários

### Requirement: Painel de confirmação é restrito a admin
O sistema SHALL permitir que apenas um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` consulte o contador de confirmações e a lista de quem confirmou um `Aviso`.

#### Scenario: Admin consulta o painel de confirmação
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` consulta o painel de confirmação de um `Aviso` desse condomínio
- **THEN** a consulta é permitida e retorna o total de destinatários e o total de confirmações

#### Scenario: Staff não-admin não acessa o painel de confirmação
- **WHEN** um `User` com `Membership(role: manager)` ou `Membership(role: service_provider)` tenta consultar o painel de confirmação de um `Aviso`
- **THEN** a consulta é rejeitada
