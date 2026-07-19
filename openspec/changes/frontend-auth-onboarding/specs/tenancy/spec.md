## ADDED Requirements

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
