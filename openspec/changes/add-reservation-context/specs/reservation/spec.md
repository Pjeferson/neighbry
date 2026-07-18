## ADDED Requirements

### Requirement: Booking é criada apenas por dono ou responsável da unidade
O sistema SHALL permitir que apenas um `User` com uma `Registry::Occupancy` ativa (`end_date: nil`) e `owner: true` ou `responsible: true` numa `Registry::Unit` crie uma `Reservation::Booking`, vinculada a essa `Occupancy`.

#### Scenario: Dono ativo cria uma reserva
- **WHEN** um `User` cujo `Person` tem uma `Occupancy(owner: true, end_date: nil)` numa `Unit` do `Condominium` reserva um `CommonArea` para uma `data` e `turno` válidos
- **THEN** a `Booking` é criada, vinculada a essa `Occupancy`

#### Scenario: Responsável ativo cria uma reserva
- **WHEN** um `User` cujo `Person` tem uma `Occupancy(responsible: true, end_date: nil)` numa `Unit` do `Condominium` reserva um `CommonArea` para uma `data` e `turno` válidos
- **THEN** a `Booking` é criada, vinculada a essa `Occupancy`

#### Scenario: Ocupante sem papel de dono ou responsável não cria reserva
- **WHEN** um `User` cujo `Person` tem apenas uma `Occupancy(owner: false, responsible: false, end_date: nil)` numa `Unit` tenta reservar um `CommonArea`
- **THEN** a operação é rejeitada

#### Scenario: Pessoa sem Occupancy ativa não cria reserva
- **WHEN** um `User` cujo `Person` não tem nenhuma `Occupancy` ativa no `Condominium` tenta reservar um `CommonArea`
- **THEN** a operação é rejeitada

### Requirement: Booking usa turno fixo do dia
Uma `Booking` SHALL ser feita para um `turno` dentre `manha`, `tarde` ou `noite` — não para um horário livre.

#### Scenario: Reserva criada com turno válido
- **WHEN** uma `Booking` é criada com `turno: "tarde"`
- **THEN** a `Booking` é persistida com esse turno

#### Scenario: Reserva rejeitada com turno inválido
- **WHEN** uma tentativa de criar `Booking` usa um `turno` fora de `manha`, `tarde`, `noite`
- **THEN** a operação é rejeitada

### Requirement: Booking respeita janela de 30 dias, sem datas passadas
O sistema SHALL rejeitar a criação de uma `Booking` cuja `data` seja anterior à data atual ou posterior a 30 dias a partir da data atual.

#### Scenario: Reserva para data dentro da janela é aceita
- **WHEN** uma `Booking` é criada com `data` igual à data atual ou até 30 dias no futuro
- **THEN** a operação é aceita (respeitadas as demais invariantes)

#### Scenario: Reserva para data passada é rejeitada
- **WHEN** uma tentativa de criar `Booking` usa uma `data` anterior à data atual
- **THEN** a operação é rejeitada

#### Scenario: Reserva além de 30 dias no futuro é rejeitada
- **WHEN** uma tentativa de criar `Booking` usa uma `data` mais de 30 dias à frente da data atual
- **THEN** a operação é rejeitada

### Requirement: Booking exige CommonArea ativo
O sistema SHALL rejeitar a criação de uma `Booking` para um `CommonArea` com `ativo: false`.

#### Scenario: Reserva em espaço ativo é aceita
- **WHEN** uma `Booking` é criada para um `CommonArea` com `ativo: true`
- **THEN** a operação é aceita (respeitadas as demais invariantes)

#### Scenario: Reserva em espaço inativo é rejeitada
- **WHEN** uma tentativa de criar `Booking` referencia um `CommonArea` com `ativo: false`
- **THEN** a operação é rejeitada

### Requirement: No máximo uma Booking ativa por espaço, data e turno
O sistema SHALL garantir, mesmo sob criação concorrente, que no máximo uma `Booking` sem `cancelada_em` exista para a mesma combinação de `common_area`, `data` e `turno`.

#### Scenario: Primeira reserva do turno é aceita
- **WHEN** não existe `Booking` ativa para um `CommonArea`, `data` e `turno`
- **THEN** uma nova `Booking` para essa combinação é criada com sucesso

#### Scenario: Segunda reserva do mesmo turno é rejeitada
- **WHEN** já existe uma `Booking` ativa (sem `cancelada_em`) para o mesmo `CommonArea`, `data` e `turno`
- **THEN** uma nova tentativa de `Booking` para essa mesma combinação é rejeitada

#### Scenario: Duas criações concorrentes para o mesmo turno resultam em apenas uma reserva
- **WHEN** duas requisições concorrentes tentam criar `Booking` para o mesmo `CommonArea`, `data` e `turno` sem nenhuma reserva prévia
- **THEN** exatamente uma das duas é criada com sucesso e a outra é rejeitada

#### Scenario: Turno liberado após cancelamento aceita nova reserva
- **WHEN** a única `Booking` existente para um `CommonArea`, `data` e `turno` está cancelada (`cancelada_em` presente)
- **THEN** uma nova `Booking` para essa mesma combinação pode ser criada

### Requirement: No máximo uma Booking ativa por unidade e CommonArea por mês
O sistema SHALL garantir, mesmo sob criação concorrente, que no máximo uma `Booking` sem `cancelada_em` exista para a mesma combinação de `unit` (via `occupancy`), `common_area` e mês de competência de `data` — independente do `turno`.

#### Scenario: Primeira reserva do mês para o espaço é aceita
- **WHEN** a unidade não tem nenhuma `Booking` ativa para um `CommonArea` no mês da `data` informada
- **THEN** a nova `Booking` é criada com sucesso

#### Scenario: Segunda reserva do mesmo espaço no mesmo mês é rejeitada
- **WHEN** a unidade já tem uma `Booking` ativa para um `CommonArea` em qualquer turno dentro do mesmo mês
- **THEN** uma nova tentativa de `Booking` da mesma unidade para esse `CommonArea` nesse mês é rejeitada, mesmo que o `turno` ou o dia sejam diferentes

#### Scenario: Reserva para CommonArea diferente no mesmo mês é aceita
- **WHEN** a unidade já tem uma `Booking` ativa para um `CommonArea` no mês, e tenta reservar um `CommonArea` diferente no mesmo mês
- **THEN** a nova `Booking` é aceita

#### Scenario: Reserva para o mesmo espaço em mês diferente é aceita
- **WHEN** a unidade já tem uma `Booking` ativa para um `CommonArea` num mês, e tenta reservar o mesmo `CommonArea` num mês diferente (dentro da janela de 30 dias)
- **THEN** a nova `Booking` é aceita

#### Scenario: Duas criações concorrentes da mesma unidade para o mesmo espaço e mês resultam em apenas uma reserva
- **WHEN** duas requisições concorrentes da mesma unidade tentam criar `Booking` para o mesmo `CommonArea` no mesmo mês (em turnos ou dias diferentes), sem nenhuma reserva prévia da unidade nesse espaço/mês
- **THEN** exatamente uma das duas é criada com sucesso e a outra é rejeitada

#### Scenario: Limite libera após cancelamento
- **WHEN** a única `Booking` ativa da unidade para um `CommonArea` no mês é cancelada (`cancelada_em` presente)
- **THEN** a unidade pode criar uma nova `Booking` para esse mesmo `CommonArea` e mês

### Requirement: Aprovação é automática
O sistema SHALL confirmar toda `Booking` criada com sucesso imediatamente, sem etapa de aprovação por um admin.

#### Scenario: Reserva criada já está confirmada
- **WHEN** uma `Booking` é criada respeitando todas as demais invariantes
- **THEN** ela está imediatamente confirmada, sem estado de pendência

### Requirement: Cancelamento é restrito a quem reservou
O sistema SHALL permitir que apenas o `User` cuja `Occupancy` está vinculada a uma `Booking` a cancele.

#### Scenario: Autor da reserva cancela sua própria Booking
- **WHEN** o `User` vinculado (via `Occupancy`) a uma `Booking` ativa a cancela
- **THEN** a `Booking` recebe `cancelada_em` preenchido

#### Scenario: Outro morador não cancela reserva alheia
- **WHEN** um `User` diferente do que criou a `Booking` tenta cancelá-la
- **THEN** a operação é rejeitada

#### Scenario: Admin não cancela reserva de morador nesta v1
- **WHEN** um `User` com `Membership(role: admin)` que não é o autor da `Booking` tenta cancelá-la
- **THEN** a operação é rejeitada

### Requirement: Listagem de Booking é aberta a qualquer Membership ativo
O sistema SHALL permitir que qualquer `User` com `Tenancy::Membership` ativo no `Condominium` (qualquer `role`) consulte a listagem de `Booking` desse condomínio.

#### Scenario: Morador consulta a agenda de reservas
- **WHEN** um `User` com `Membership(role: resident, status: active)` no `Condominium` consulta a listagem de `Booking`
- **THEN** a consulta é permitida

#### Scenario: Usuário sem Membership ativo no condomínio não consulta a listagem
- **WHEN** um `User` sem `Membership` ativo no `Condominium` tenta consultar a listagem de `Booking` desse condomínio
- **THEN** a consulta é rejeitada
