## 1. Estrutura do módulo

- [x] 1.1 Criar `app/domains/tenancy/` como primeiro namespace de bounded context do projeto (models, services, policies dentro do namespace `Tenancy::`)
- [x] 1.2 Confirmar convenção de autoload do Rails 8 para `app/domains/**` (adicionar em `config/application.rb` se necessário)

## 2. Migrations

- [x] 2.1 Migration `condominiums` (id uuid, name, slug único, timestamps)
- [x] 2.2 Migration `memberships` (id uuid, user_id FK, condominium_id FK, role enum, status enum `active|revoked`, timestamps; índice único em `user_id` — v1 é 1:1, ver `design.md` Decisão 6)
- [x] 2.3 Migration `invitations` (id uuid, condominium_id FK, email, role, token único, expires_at, accepted_at nullable, timestamps)
- [x] 2.4 Rodar migrations em development e test (`RAILS_ENV=test`)

## 3. Condominium

- [x] 3.1 Model `Tenancy::Condominium` com validação de `slug` único, formato URL-safe
- [x] 3.2 Factory (`spec/factories/tenancy/condominiums.rb`)
- [x] 3.3 Testes de invariante: slug duplicado é rejeitado

## 4. Membership

- [x] 4.1 Model `Tenancy::Membership` com enum `role: admin | manager | doorman | resident` e enum `status: active | revoked`
- [x] 4.2 Validação de unicidade em `user_id` (um `User` tem no máximo um `Membership`, v1)
- [x] 4.3 Factory (`spec/factories/tenancy/memberships.rb`)
- [x] 4.4 Testes de invariante: segundo membership pro mesmo User rejeitado, role inválido rejeitado (checagem "membership revogado não autentica" fica no Grupo 7, depende do login existir)

## 5. Invitation

- [ ] 5.1 Model `Tenancy::Invitation` com token seguro (ex: `has_secure_token` ou equivalente) e `expires_at`
- [ ] 5.2 Service object `Tenancy::InviteMember` (Dry::Monads::Result) — cria `Invitation` para um email+role num `Condominium`
- [ ] 5.3 Service object `Tenancy::AcceptInvitation` (Dry::Monads::Result) — valida token não expirado, cria/vincula `User` a partir do email do convite com a senha definida pela própria pessoa convidada, ativa o `Membership`
- [ ] 5.4 Garantir que nenhum endpoint/parâmetro permita que quem convida defina a senha de outra pessoa
- [ ] 5.5 Canal de entrega isolado: em desenvolvimento, retornar o link/token do convite na resposta da API em vez de enviar email (documentar o ponto de troca para produção)
- [ ] 5.6 `AcceptInvitation` rejeita aceite se o email do convite corresponder a um `User` que já possui `Membership` (1:1, v1)
- [ ] 5.7 Factory + testes: convite expira, convite aceito ativa Membership, convite não pode ser aceito duas vezes, aceite rejeitado se User já tem Membership

## 6. Resolução de tenant por subdomínio

- [ ] 6.1 Middleware/concern que resolve `Condominium` a partir do subdomínio da requisição (ex: `ActiveSupport::CurrentAttributes`)
- [ ] 6.2 Requisição sem subdomínio correspondente a nenhum `Condominium` retorna erro apropriado (404/400)
- [ ] 6.3 Validar `*.localhost` funcionando em ambiente de desenvolvimento local (documentar no `CLAUDE.md` se precisar de configuração extra)

## 7. Login escopado ao tenant

- [ ] 7.1 Integrar autenticação Devise/JWT existente com a resolução de tenant: login só é aceito se `User` tiver `Membership` `active` no `Condominium` resolvido pelo subdomínio
- [ ] 7.2 Testes: login aceito com Membership ativo no tenant correto; login rejeitado sem Membership; login rejeitado com Membership revogado

## 8. Onboarding de condomínio

- [ ] 8.1 Endpoint `POST /api/v1/condominiums` (fora da lógica de subdomínio) que cria `Condominium` + `User` + `Membership(role: admin, status: active)` numa única transação
- [ ] 8.2 Testes: criação bem-sucedida cria os três registros atomicamente; falha em qualquer etapa não deixa registro parcial

## 9. Autorização

- [ ] 9.1 Policy Pundit para `Membership` (quem pode convidar, quem pode revogar) — inicialmente restrito a `role: admin`
- [ ] 9.2 Testes de policy

## 10. Rotas

- [ ] 10.1 Adicionar rotas em inglês sob `/api/v1/`: `condominiums` (create), `invitations` (create/accept), ajustar rota de login existente para considerar o tenant resolvido
- [ ] 10.2 Serializers (`jsonapi-serializer`) para `Condominium` e `Membership`

## 11. Validação final

- [ ] 11.1 `bundle exec rspec` roda sem falhas
- [ ] 11.2 `docker compose up` sobe sem erro com as novas migrations aplicadas
- [ ] 11.3 Fluxo manual de ponta a ponta: criar condomínio → convidar membro → aceitar convite (token retornado na resposta) → login no subdomínio correto → login rejeitado no subdomínio errado
- [ ] 11.4 Atualizar `CLAUDE.md` se a convenção de módulos (`app/domains/`) precisar de documentação adicional
