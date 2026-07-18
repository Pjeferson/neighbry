# billing

## Purpose

Capability introduzida por `add-billing-context`. Cobrança condominial
mensal: `Taxa` (encargo cadastrado pelo admin, imutável, com vigência por
competência), `CicloCobranca` (execução mensal idempotente e retomável por
condomínio), `Fatura`/`Cobrança` (por `Unit` ativa — qualquer unidade com
`Registry::Occupancy` ativa, sem distinção de papel — rateio igual entre
elas) e `Pagamento` (confirmação manual pelo admin ou via simulação de
webhook de PSP com round-trip HTTP real). Visibilidade de `Fatura` segue
ocupação ativa na `Unit`, não papel. Configuração de cobrança fica
denormalizada dentro de `Billing`, sem tocar `Tenancy::Condominium`.

## Requirements

### Requirement: Taxa é definida pelo admin do condomínio
O sistema SHALL permitir que apenas um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` cadastre uma `Taxa`, com `valor`, `descricao`, `data_inicio` e `data_fim` opcional.

#### Scenario: Admin cadastra uma Taxa
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` cadastra uma `Taxa` com `valor` e `data_inicio`
- **THEN** a `Taxa` é criada com `ativo: true`

#### Scenario: Não-admin não cadastra Taxa
- **WHEN** um `User` sem `Membership(role: admin)` no `Condominium` (incluindo owner/responsible de alguma Unit) tenta cadastrar uma `Taxa`
- **THEN** a operação é rejeitada

### Requirement: Taxa é imutável após criação
Uma vez criada, `valor`, `data_inicio` e `data_fim` de uma `Taxa` SHALL NOT ser alterados. Correção de um cadastro incorreto SHALL ser feita desativando a `Taxa` (`ativo: false`) e criando uma nova — sem qualquer vínculo automático ou rastreável entre a `Taxa` desativada e a nova.

#### Scenario: Tentativa de editar valor de Taxa existente é rejeitada
- **WHEN** uma tentativa de alterar `valor`, `data_inicio` ou `data_fim` de uma `Taxa` já persistida ocorre
- **THEN** a operação falha, sem alterar o registro existente

#### Scenario: Admin desativa uma Taxa e cadastra a correção
- **WHEN** um admin desativa (`ativo: false`) uma `Taxa` cadastrada com erro e cadastra uma nova `Taxa` com os dados corretos
- **THEN** as duas `Taxa` existem como registros independentes, sem campo que associe uma à outra

### Requirement: Taxa é aplicável a uma competência conforme vigência e status ativo
Uma `Taxa` SHALL ser considerada aplicável a uma competência (mês de referência) quando `ativo` for `true`, a competência for maior ou igual a `data_inicio`, e (`data_fim` for nulo OU a competência for menor ou igual a `data_fim`).

#### Scenario: Taxa sem data_fim aplica indefinidamente
- **WHEN** uma `Taxa` tem `data_fim` nulo e está `ativo: true`
- **THEN** ela é aplicável a qualquer competência igual ou posterior a `data_inicio`

#### Scenario: Taxa com data_fim deixa de aplicar após o prazo
- **WHEN** a competência de geração é posterior ao `data_fim` de uma `Taxa`
- **THEN** essa `Taxa` não gera `Cobrança` nessa competência

#### Scenario: Taxa desativada não aplica mesmo dentro da vigência
- **WHEN** uma `Taxa` está `ativo: false`, mesmo dentro do intervalo `data_inicio`/`data_fim`
- **THEN** ela não gera `Cobrança` na competência

### Requirement: Configuração de dia de cobrança é isolada dentro de Billing
O sistema SHALL armazenar o dia de cobrança de cada `Condominium` (`dia_cobranca`, entre 0 e 15) em uma tabela própria de `Billing`, denormalizada com `condominium_id`, sem adicionar coluna em `Tenancy::Condominium`.

#### Scenario: Configuração de cobrança referencia o Condominium sem acoplar código entre contextos
- **WHEN** o job de geração mensal precisa do `dia_cobranca` de um `Condominium`
- **THEN** ele consulta a tabela de configuração própria de `Billing`, nunca uma coluna em `Tenancy::Condominium`

### Requirement: Prazo de vencimento é configurável por condomínio
A configuração de cobrança de cada `Condominium` SHALL incluir `dias_para_vencimento`. A `data_vencimento` de uma `Fatura` SHALL ser calculada como a data de geração da `Fatura` somada a `dias_para_vencimento`.

#### Scenario: Data de vencimento calculada a partir da geração
- **WHEN** uma `Fatura` é gerada para um `Condominium` com `dias_para_vencimento` igual a 10
- **THEN** a `data_vencimento` dessa `Fatura` é a data de geração mais 10 dias

### Requirement: Configuração de cobrança é criada automaticamente ao onboardar um condomínio
Ao receber o evento de onboarding de um `Condominium` (publicado por `Tenancy`), o sistema SHALL criar automaticamente uma configuração de cobrança padrão (`dia_cobranca` e `dias_para_vencimento`) para esse condomínio, editável pelo admin posteriormente. `Condominium` sem configuração de cobrança (ex: onboardado antes desta capability existir) SHALL ser ignorado silenciosamente pelo job de geração mensal, sem erro.

#### Scenario: Configuração padrão criada ao onboardar um condomínio novo
- **WHEN** o evento de onboarding de um `Condominium` é publicado
- **THEN** uma configuração de cobrança padrão é criada para esse `Condominium`

#### Scenario: Condomínio sem configuração de cobrança é ignorado pelo job
- **WHEN** o job de geração mensal roda e encontra um `Condominium` sem configuração de cobrança
- **THEN** esse `Condominium` é ignorado nessa execução, sem erro e sem gerar `CicloCobranca`

### Requirement: Geração mensal de cobrança é idempotente por competência
O sistema SHALL garantir que, para cada `Condominium`, exista no máximo um `CicloCobranca` por competência (mês de referência truncado para o primeiro dia do mês), independente de quantas vezes o job de geração seja executado ou de mudanças em `dia_cobranca` durante o mês.

#### Scenario: Segunda execução no mesmo mês não gera novo ciclo
- **WHEN** já existe um `CicloCobranca` para um `Condominium` na competência do mês corrente
- **THEN** uma nova tentativa de gerar o ciclo para esse condomínio nessa competência é rejeitada, sem criar registro duplicado

#### Scenario: Mudança de dia_cobranca no meio do mês não duplica cobrança
- **WHEN** um `CicloCobranca` já foi gerado para a competência do mês corrente e o `dia_cobranca` do `Condominium` é alterado para um dia posterior ainda dentro do mesmo mês
- **THEN** o job de geração, ao rodar nesse novo dia, não cria um segundo `CicloCobranca` para a mesma competência

### Requirement: Geração de CicloCobranca é retomável após falha parcial
`CicloCobranca` SHALL ter um status (`gerando` ou `concluido`). Um ciclo é criado como `gerando` antes de gerar qualquer `Fatura`, e SHALL passar a `concluido` somente depois que todas as `Fatura` daquela competência tiverem sido geradas com sucesso. Se a geração for interrompida no meio (ex: falha do processo), uma nova execução do job SHALL retomar a geração das unidades restantes desse mesmo `CicloCobranca`, em vez de criar um novo.

#### Scenario: Ciclo interrompido no meio da geração permanece em gerando
- **WHEN** a geração de `Fatura` para as unidades de um `CicloCobranca` é interrompida antes de processar todas as unidades ativas
- **THEN** o `CicloCobranca` permanece com status `gerando`

#### Scenario: Nova execução retoma um ciclo em gerando sem duplicar Fatura já criada
- **WHEN** o job de geração roda novamente e encontra um `CicloCobranca` da competência corrente com status `gerando`
- **THEN** ele gera `Fatura` apenas para as unidades ativas que ainda não têm `Fatura` nesse ciclo, sem duplicar as já existentes

### Requirement: Disparo do ciclo de cobrança tolera atraso do cron
O sistema SHALL disparar a geração do `CicloCobranca` de um `Condominium` quando a data corrente for maior ou igual ao `dia_cobranca` configurado E não existir ainda um `CicloCobranca` na competência corrente — não exigindo que a execução ocorra exatamente no dia configurado.

#### Scenario: Job perdido no dia exato ainda gera o ciclo depois
- **WHEN** o job de geração não roda no dia exato de `dia_cobranca` (ex: indisponibilidade do servidor) mas roda em um dia posterior, ainda sem `CicloCobranca` na competência
- **THEN** o `CicloCobranca` é gerado nessa execução posterior

### Requirement: Unit ativa é definida por ter Occupancy ativa, de qualquer papel
Uma `Unit` SHALL ser considerada "ativa" para fins de cobrança quando possuir ao menos uma `Registry::Occupancy` ativa, independente do papel (`owner`, `responsible` ou morador comum sem nenhum dos dois). `Unit` sem nenhuma `Occupancy` ativa SHALL NOT ser cobrada.

#### Scenario: Unit com apenas morador comum é considerada ativa
- **WHEN** uma `Unit` tem uma `Registry::Occupancy` ativa sem `owner` nem `responsible`
- **THEN** essa `Unit` é considerada ativa para fins de cobrança

#### Scenario: Unit vaga não é considerada ativa
- **WHEN** uma `Unit` não tem nenhuma `Registry::Occupancy` ativa
- **THEN** essa `Unit` não é considerada ativa e não recebe `Fatura`

### Requirement: Fatura agrega Cobranças de uma Unit
O sistema SHALL representar a cobrança mensal de uma `Unit` através de uma `Fatura` (Aggregate Root), pertencente a um `CicloCobranca`. Uma `Fatura` SHALL NOT existir sem ao menos uma `Cobrança`.

#### Scenario: Geração cria uma Fatura por Unit ativa com Taxa aplicável
- **WHEN** o `CicloCobranca` de um `Condominium` é gerado e existe ao menos uma `Taxa` aplicável na competência
- **THEN** uma `Fatura` é criada para cada `Unit` ativa desse `Condominium`, cada uma com ao menos uma `Cobrança`

#### Scenario: Nenhuma Taxa aplicável não gera Fatura
- **WHEN** o `CicloCobranca` de um `Condominium` é gerado e não existe nenhuma `Taxa` aplicável na competência
- **THEN** nenhuma `Fatura` é criada para esse ciclo

#### Scenario: Uma Unit não recebe duas Fatura no mesmo CicloCobranca
- **WHEN** uma tentativa de gerar uma segunda `Fatura` para a mesma `Unit` dentro do mesmo `CicloCobranca` ocorre
- **THEN** a criação falha, sem duplicar a `Fatura` já existente

### Requirement: Cobrança é rateada igualmente entre as unidades ativas
Para cada `Taxa` aplicável em uma competência, o sistema SHALL gerar uma `Cobrança` por `Unit` ativa do `Condominium`, com valor igual ao `valor` da `Taxa` dividido pelo número de unidades ativas do condomínio naquela competência.

#### Scenario: Rateio igual entre unidades
- **WHEN** uma `Taxa` de valor total R$ 400 é aplicável em um `Condominium` com 4 unidades ativas
- **THEN** cada `Fatura` gerada recebe uma `Cobrança` dessa `Taxa` no valor de R$ 100

### Requirement: Status atrasado de Fatura é sempre calculado
`Fatura` SHALL persistir apenas os status `pendente` e `pago`. O estado "atrasado" SHALL NOT ser armazenado — SHALL ser sempre derivado em tempo de leitura como `status = pendente` e data de vencimento anterior à data corrente.

#### Scenario: Fatura pendente vencida é considerada atrasada na leitura
- **WHEN** uma `Fatura` com `status: pendente` tem data de vencimento anterior à data corrente
- **THEN** qualquer consulta que exponha o status da fatura reporta "atrasado", sem que o registro persistido tenha sido alterado

### Requirement: Pagamento quita a Fatura inteira
O sistema SHALL representar a quitação de uma `Fatura` através de um `Pagamento`, vinculado à `Fatura` inteira (nunca a uma `Cobrança` individual). Ao registrar um `Pagamento`, a `Fatura` correspondente SHALL passar a `status: pago`.

#### Scenario: Pagamento muda status da Fatura para pago
- **WHEN** um `Pagamento` é registrado para uma `Fatura` com `status: pendente`
- **THEN** a `Fatura` passa a `status: pago`

### Requirement: Fatura tem no máximo um Pagamento
O sistema SHALL permitir apenas um `Pagamento` por `Fatura`, sem suporte a pagamento parcial. Uma segunda tentativa de registrar `Pagamento` para uma `Fatura` já paga — seja por confirmação manual ou por webhook — SHALL ser rejeitada sem criar um segundo registro nem alterar o `Pagamento` existente.

#### Scenario: Segunda tentativa de pagamento é rejeitada
- **WHEN** uma tentativa de registrar `Pagamento` ocorre para uma `Fatura` que já tem `status: pago`
- **THEN** a operação é rejeitada, sem criar um segundo `Pagamento`

#### Scenario: Pagamento com valor diferente do total da Fatura é rejeitado
- **WHEN** uma tentativa de registrar `Pagamento` com valor diferente da soma das `Cobrança` da `Fatura` ocorre
- **THEN** a operação é rejeitada

### Requirement: Confirmação manual de pagamento é restrita a admin
O sistema SHALL permitir que apenas um `User` com `Tenancy::Membership` de `role: admin` no `Condominium` confirme manualmente o pagamento de uma `Fatura`.

#### Scenario: Admin confirma pagamento manualmente
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` confirma manualmente o pagamento de uma `Fatura` desse condomínio
- **THEN** a operação é permitida e um `Pagamento` é registrado

#### Scenario: Não-admin não confirma pagamento manualmente
- **WHEN** um `User` sem `Membership(role: admin)` no `Condominium` (incluindo owner/responsible da própria Unit) tenta confirmar manualmente um pagamento
- **THEN** a operação é rejeitada

### Requirement: Confirmação de pagamento via simulação de webhook de PSP
O sistema SHALL prover um endpoint de simulação (`mock_psp/simulate`), acessível apenas por admin autenticado, que monta um payload no formato de webhook de PSP e realiza uma chamada HTTP real a um endpoint de webhook dedicado (`webhooks/payments`). O endpoint de webhook SHALL autenticar a chamada através de um segredo estático, não pela autenticação de sessão de usuário, e SHALL ser o único ponto que efetivamente confirma o pagamento — o mesmo endpoint que existiria em produção com um PSP real.

#### Scenario: Simulação de PSP bem-sucedida confirma pagamento
- **WHEN** um admin aciona `mock_psp/simulate` para uma `Fatura` pendente
- **THEN** uma chamada HTTP é feita ao endpoint de webhook com o segredo estático correto, e a `Fatura` passa a `status: pago`

#### Scenario: Webhook rejeita chamada sem o segredo correto
- **WHEN** uma requisição chega ao endpoint de webhook sem o segredo estático válido
- **THEN** a confirmação de pagamento é rejeitada, mesmo que o payload esteja correto

#### Scenario: Webhook não exige autenticação de sessão de usuário
- **WHEN** o endpoint de webhook recebe uma requisição com o segredo estático válido, sem token JWT de sessão
- **THEN** a confirmação de pagamento é aceita

#### Scenario: Simulador inclui um identificador de transação no payload
- **WHEN** o endpoint `mock_psp/simulate` monta o payload enviado ao webhook
- **THEN** o payload inclui um identificador de transação simulado, que é persistido no `Pagamento` resultante

### Requirement: Evento de domínio publicado ao confirmar pagamento
Ao registrar um `Pagamento` que quita uma `Fatura`, por qualquer um dos dois caminhos (confirmação manual ou webhook), o sistema SHALL publicar um evento de domínio `FaturaPaga` contendo o identificador da `Fatura`, sem conhecimento de quem (se alguém) está inscrito para recebê-lo.

#### Scenario: Evento publicado independente do caminho de confirmação
- **WHEN** uma `Fatura` é paga tanto por confirmação manual quanto por webhook de PSP simulado
- **THEN** em ambos os casos um evento `FaturaPaga` é publicado com o identificador da `Fatura`

### Requirement: Visibilidade de Fatura segue Occupancy ativa na Unit, sem distinção de papel
Um `User` com `Membership(role: admin)` no `Condominium` SHALL poder visualizar todas as `Fatura` desse condomínio. Uma `Person` com `Registry::Occupancy` ativa em uma `Unit` — `owner`, `responsible` ou morador comum, sem distinção — SHALL poder visualizar apenas as `Fatura` dessa `Unit`. Uma `Person` sem nenhuma `Occupancy` ativa em nenhuma `Unit` SHALL NOT poder visualizar nenhuma `Fatura`.

#### Scenario: Admin vê faturas de qualquer Unit do condomínio
- **WHEN** um `User` com `Membership(role: admin)` no `Condominium` consulta as `Fatura` de uma `Unit` desse condomínio
- **THEN** a consulta é permitida, independente de o admin ter `Occupancy` nessa `Unit`

#### Scenario: Morador com Occupancy ativa vê as faturas da própria Unit, independente do papel
- **WHEN** uma `Person` com `Occupancy` ativa numa `Unit` (`owner`, `responsible`, ou sem nenhum dos dois) consulta as `Fatura` dessa `Unit`
- **THEN** a consulta é permitida

#### Scenario: Morador não vê faturas de outra Unit
- **WHEN** uma `Person` com `Occupancy` ativa numa `Unit` tenta consultar as `Fatura` de outra `Unit` onde não tem `Occupancy` ativa
- **THEN** a consulta é rejeitada

#### Scenario: Pessoa sem nenhuma Occupancy não vê nenhuma fatura
- **WHEN** uma `Person` sem nenhuma `Occupancy` ativa em nenhuma `Unit` tenta consultar qualquer `Fatura`
- **THEN** a consulta é rejeitada
