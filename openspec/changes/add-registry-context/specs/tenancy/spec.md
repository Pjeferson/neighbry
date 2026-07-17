## ADDED Requirements

### Requirement: Evento de domínio publicado ao aceitar convite
Ao ativar um `Membership` através do aceite de um `Invitation`, o sistema SHALL publicar um evento de domínio contendo o identificador do convite e o identificador do `User` resultante, sem conhecimento de quem (se alguém) está inscrito para recebê-lo.

#### Scenario: Aceite de convite publica evento com invitation_id e user_id
- **WHEN** um `Invitation` é aceito com sucesso e o `Membership` correspondente é ativado
- **THEN** um evento de domínio é publicado contendo o identificador desse `Invitation` e o identificador do `User` ativado

#### Scenario: Publicação do evento não depende de nenhum outro bounded context
- **WHEN** o evento de aceite de convite é publicado
- **THEN** `Tenancy` não faz nenhuma chamada direta a código de outro bounded context — a publicação ocorre independentemente de existir algum assinante
