## ADDED Requirements

### Requirement: Evento de domínio publicado ao aceitar convite
Ao ativar um `Membership` através do aceite de um `Invitation`, o sistema SHALL publicar um evento de domínio contendo o identificador do convite e o identificador do `User` resultante, sem conhecimento de quem (se alguém) está inscrito para recebê-lo.

#### Scenario: Aceite de convite publica evento com invitation_id e user_id
- **WHEN** um `Invitation` é aceito com sucesso e o `Membership` correspondente é ativado
- **THEN** um evento de domínio é publicado contendo o identificador desse `Invitation` e o identificador do `User` ativado

#### Scenario: Publicação do evento não depende de nenhum outro bounded context
- **WHEN** o evento de aceite de convite é publicado
- **THEN** `Tenancy` não faz nenhuma chamada direta a código de outro bounded context — a publicação ocorre independentemente de existir algum assinante

### Requirement: Novo convite substitui convite pendente anterior do mesmo email
Ao convidar um email que já possui um `Invitation` pendente (não aceito) no mesmo `Condominium`, o sistema SHALL invalidar o convite pendente anterior e criar um novo `Invitation` — nunca dois convites pendentes simultâneos para o mesmo email no mesmo `Condominium`. Isso cobre tanto o reenvio de um convite expirado quanto qualquer nova tentativa de convite antes do anterior ser aceito.

#### Scenario: Convidar de novo invalida o convite pendente anterior
- **WHEN** um email que já possui um `Invitation` pendente é convidado novamente para o mesmo `Condominium`
- **THEN** o `Invitation` anterior deixa de poder ser aceito, e um novo `Invitation` é criado com novo `id`, `token` e `expires_at`

#### Scenario: Convite já aceito não é afetado por um novo convite
- **WHEN** um email cujo `Invitation` anterior já foi aceito é convidado novamente
- **THEN** um novo `Invitation` é criado normalmente, sem qualquer efeito sobre o `Membership` já ativo
