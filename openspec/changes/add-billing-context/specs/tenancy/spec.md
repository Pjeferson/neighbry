## ADDED Requirements

### Requirement: Evento de domínio publicado ao onboardar condomínio
Ao criar um `Condominium` através do fluxo de onboarding, o sistema SHALL publicar um evento de domínio contendo o identificador do `Condominium` criado, sem conhecimento de quem (se alguém) está inscrito para recebê-lo.

#### Scenario: Onboarding publica evento com condominium_id
- **WHEN** um `Condominium` é criado com sucesso através do fluxo de onboarding
- **THEN** um evento de domínio é publicado contendo o identificador desse `Condominium`

#### Scenario: Publicação do evento não depende de nenhum outro bounded context
- **WHEN** o evento de onboarding de condomínio é publicado
- **THEN** `Tenancy` não faz nenhuma chamada direta a código de outro bounded context — a publicação ocorre independentemente de existir algum assinante
