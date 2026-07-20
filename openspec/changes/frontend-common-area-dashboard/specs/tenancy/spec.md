## MODIFIED Requirements

### Requirement: Papéis de Membership
O `role` de `Membership` SHALL ser um dos seguintes valores: `admin`, `manager`, `service_provider`, `resident`. `admin`, `manager` e `service_provider` são papéis de staff/administração do condomínio (incluindo prestadores de serviço, internos ou externos, com acesso ao sistema); `resident` é o papel padrão de morador comum sem privilégio administrativo.

#### Scenario: Papel inválido rejeitado
- **WHEN** um `Membership` é criado com um `role` fora do conjunto `admin | manager | service_provider | resident`
- **THEN** a criação falha com erro de validação

### Requirement: Login resolvido por subdomínio
O sistema SHALL resolver o `Condominium` (tenant) a partir do subdomínio da requisição antes de validar credenciais de login. Login SHALL falhar se o `User` autenticado não possuir `Membership` ativo naquele `Condominium`. A resposta de um login bem-sucedido SHALL incluir o `role` da `Membership` usada para autenticar.

#### Scenario: Login bem-sucedido no subdomínio correto
- **WHEN** um `User` com `Membership` ativo no `Condominium` do slug `acme` faz login em `acme.neighbry.com`
- **THEN** o login é aceito e a sessão fica escopada a esse `Condominium`

#### Scenario: Login rejeitado sem Membership no tenant
- **WHEN** um `User` sem `Membership` ativo no `Condominium` do slug `acme` tenta logar em `acme.neighbry.com`
- **THEN** o login é rejeitado, mesmo que as credenciais (email/senha) estejam corretas

#### Scenario: Resposta de login inclui o role da Membership
- **WHEN** um `User` com `Membership(role: manager)` ativo faz login com sucesso
- **THEN** a resposta inclui `role: "manager"`
