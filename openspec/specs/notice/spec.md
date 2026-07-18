# notice

## Purpose

Capability introduzida por `add-notice-context`. Comunicação do condomínio
com moradores e equipe: `Aviso` (criado só por admin, imutável exceto
`ativo`, sempre com um único tipo de destinatário — `todos`, `moradores`,
`staff`, `torre` ou `unidade`) e `Notice::Leitura` (tabela única fazendo o
papel de snapshot de destinatários e registro de confirmação). Destinatários
de `todos`/`moradores`/`staff` são resolvidos via `Tenancy::Membership`;
`torre`/`unidade` via `Registry::Occupancy` ativa (qualquer papel),
deduplicados por `User`. Confirmação de leitura é sempre manual, idempotente,
e bloqueada quando o `Aviso` está desativado. Painel de acompanhamento
restrito a admin.

## Requirements

### Requirement: Aviso é criado apenas por admin
O sistema SHALL permitir que apenas um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` crie um `Aviso`.

#### Scenario: Admin cria um Aviso
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` cria um `Aviso`
- **THEN** o `Aviso` é criado com `ativo: true`

#### Scenario: Não-admin não cria Aviso
- **WHEN** um `User` sem `Membership(role: admin)` no `Condominium` (incluindo staff não-admin e moradores) tenta criar um `Aviso`
- **THEN** a operação é rejeitada

### Requirement: Aviso tem um único tipo de destinatário
Um `Aviso` SHALL ter exatamente um `tipo` de destinatário: `todos`, `moradores`, `staff`, `torre` ou `unidade`. Quando `tipo: torre`, `building_id` SHALL estar presente e `unit_id` SHALL ser nulo. Quando `tipo: unidade`, `unit_id` SHALL estar presente e `building_id` SHALL ser nulo. Para os demais tipos, `building_id` e `unit_id` SHALL ser ambos nulos.

#### Scenario: Aviso tipo torre sem building_id é rejeitado
- **WHEN** um `Aviso` com `tipo: torre` é criado sem `building_id`
- **THEN** a criação falha com erro de validação

#### Scenario: Aviso tipo unidade sem unit_id é rejeitado
- **WHEN** um `Aviso` com `tipo: unidade` é criado sem `unit_id`
- **THEN** a criação falha com erro de validação

#### Scenario: Aviso tipo todos com building_id é rejeitado
- **WHEN** um `Aviso` com `tipo: todos` é criado com `building_id` ou `unit_id` preenchido
- **THEN** a criação falha com erro de validação

### Requirement: Aviso é imutável exceto o status ativo
Uma vez criado, `titulo`, `corpo`, `tipo`, `building_id` e `unit_id` de um `Aviso` SHALL NOT ser alterados. O único campo mutável após a criação SHALL ser `ativo`.

#### Scenario: Tentativa de editar titulo de Aviso existente é rejeitada
- **WHEN** uma tentativa de alterar `titulo`, `corpo`, `tipo`, `building_id` ou `unit_id` de um `Aviso` já persistido ocorre
- **THEN** a operação falha, sem alterar o registro existente

### Requirement: Aviso desativado desaparece da visão do morador
Quando um `Aviso` é desativado (`ativo: false`), o sistema SHALL deixar de exibi-lo para qualquer `User` na listagem de avisos recebidos — como se nunca tivesse existido para o destinatário. O registro e as confirmações já feitas SHALL permanecer persistidos para consulta do admin.

#### Scenario: Aviso desativado some da lista do morador
- **WHEN** um `Aviso` que já era visível para um morador é desativado pelo admin
- **THEN** esse `Aviso` deixa de aparecer na listagem de avisos desse morador

#### Scenario: Aviso desativado permanece visível para o admin
- **WHEN** um admin consulta o histórico de avisos do condomínio, incluindo desativados
- **THEN** o `Aviso` desativado e suas confirmações continuam acessíveis

### Requirement: Destinatários de todos, moradores e staff são resolvidos por Membership
Para `Aviso` com `tipo: todos`, o sistema SHALL considerar destinatário todo `User` com `Tenancy::Membership(status: active)` no `Condominium`. Para `tipo: moradores`, apenas `Membership(role: resident, status: active)`. Para `tipo: staff`, apenas `Membership(role: admin | manager | doorman, status: active)`.

#### Scenario: Aviso tipo todos inclui staff e moradores
- **WHEN** um `Aviso` com `tipo: todos` é criado num `Condominium` com admins, staff e moradores ativos
- **THEN** todos eles são incluídos como destinatários

#### Scenario: Aviso tipo moradores exclui staff
- **WHEN** um `Aviso` com `tipo: moradores` é criado
- **THEN** apenas `User` com `Membership(role: resident)` são incluídos como destinatários

#### Scenario: Aviso tipo staff inclui admin, manager e doorman
- **WHEN** um `Aviso` com `tipo: staff` é criado
- **THEN** `User` com `Membership(role: admin)`, `Membership(role: manager)` e `Membership(role: doorman)` são todos incluídos como destinatários

### Requirement: Destinatários de torre e unidade são resolvidos por Occupancy ativa
Para `Aviso` com `tipo: unidade`, o sistema SHALL considerar destinatário todo `User` vinculado (via `Person.user_id`) a uma `Registry::Occupancy` ativa na `Unit` referenciada, independente do papel (`owner`, `responsible` ou morador comum). Para `tipo: torre`, o mesmo critério aplicado a todas as `Unit` do `Building` referenciado. `Person` sem `user_id` (sem acesso concedido) SHALL NOT gerar destinatário.

#### Scenario: Aviso tipo unidade inclui ocupante sem owner nem responsible
- **WHEN** um `Aviso` com `tipo: unidade` é criado para uma `Unit` cuja única `Occupancy` ativa é de um morador comum
- **THEN** o `User` desse morador comum é incluído como destinatário

#### Scenario: Aviso tipo torre inclui moradores de todas as Unit do Building
- **WHEN** um `Aviso` com `tipo: torre` é criado para um `Building` com múltiplas `Unit` ocupadas
- **THEN** os `User` de todas essas `Unit` são incluídos como destinatários

#### Scenario: Person sem User não gera destinatário
- **WHEN** uma `Unit` alvo de um `Aviso` tem `Occupancy` ativa de uma `Person` sem `user_id`
- **THEN** essa `Person` não gera nenhum destinatário

### Requirement: Destinatários de torre são deduplicados por User
Se a mesma `Person` possuir `Registry::Occupancy` ativa em mais de uma `Unit` do `Building` alvo de um `Aviso` tipo `torre`, o sistema SHALL contar essa pessoa como um único destinatário.

#### Scenario: Person com Occupancy em duas Unit da mesma torre conta uma vez
- **WHEN** uma `Person` tem `Occupancy` ativa em duas `Unit` diferentes do mesmo `Building` alvo de um `Aviso` tipo `torre`
- **THEN** o `User` dessa `Person` aparece como destinatário uma única vez

### Requirement: Destinatários são registrados como snapshot no momento da criação
Ao criar um `Aviso`, o sistema SHALL calcular os destinatários uma única vez e persistir um registro de leitura pendente para cada um. Mudanças posteriores em `Membership` ou `Occupancy` SHALL NOT alterar essa lista.

#### Scenario: Novo morador não vê Aviso criado antes de sua ocupação
- **WHEN** um `Aviso` tipo `unidade` é criado e, depois, uma nova `Occupancy` ativa é registrada nessa `Unit`
- **THEN** o novo ocupante não aparece como destinatário desse `Aviso`

#### Scenario: Total de destinatários não muda com saída de morador
- **WHEN** um destinatário de um `Aviso` tem sua `Occupancy` encerrada depois da criação do `Aviso`
- **THEN** o total de destinatários desse `Aviso` permanece o mesmo

### Requirement: Confirmação de leitura é ação manual e idempotente
O sistema SHALL exigir uma ação explícita do destinatário para confirmar a leitura de um `Aviso` — nunca automática ao consultar ou visualizar o conteúdo. Confirmar mais de uma vez SHALL NOT criar registros duplicados.

#### Scenario: Destinatário confirma leitura manualmente
- **WHEN** um destinatário aciona a confirmação de leitura de um `Aviso`
- **THEN** o registro de leitura desse destinatário passa a ter a data/hora da confirmação

#### Scenario: Confirmar duas vezes não duplica o registro
- **WHEN** um destinatário confirma a leitura de um `Aviso` que já havia confirmado antes
- **THEN** nenhum novo registro é criado

### Requirement: Apenas destinatário pode confirmar leitura
Um `User` que não conste na lista de destinatários calculada na criação do `Aviso` SHALL NOT poder confirmar leitura dele.

#### Scenario: Não-destinatário não confirma leitura
- **WHEN** um `User` que não é destinatário de um `Aviso` tenta confirmar a leitura dele
- **THEN** a operação é rejeitada

### Requirement: Confirmação de leitura é bloqueada em Aviso desativado
O sistema SHALL rejeitar a confirmação de leitura de um `Aviso` com `ativo: false`, mesmo que o `User` conste como destinatário original.

#### Scenario: Confirmação rejeitada após desativação
- **WHEN** um `Aviso` é desativado e um destinatário original tenta confirmar a leitura dele
- **THEN** a operação é rejeitada

### Requirement: Painel de confirmação é restrito a admin
O sistema SHALL permitir que apenas um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` consulte o contador de confirmações e a lista de quem confirmou um `Aviso`.

#### Scenario: Admin consulta o painel de confirmação
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` consulta o painel de confirmação de um `Aviso` desse condomínio
- **THEN** a consulta é permitida e retorna o total de destinatários e o total de confirmações

#### Scenario: Staff não-admin não acessa o painel de confirmação
- **WHEN** um `User` com `Membership(role: manager)` ou `Membership(role: doorman)` tenta consultar o painel de confirmação de um `Aviso`
- **THEN** a consulta é rejeitada
