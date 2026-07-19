## 1. Backend — endpoint de existência de Condominium e CORS

- [ ] 1.1 Rota `GET /api/v1/condominiums/:slug` (`param: :slug`, sem `ResolvesTenant`)
- [ ] 1.2 `Api::V1::CondominiumsController#show` — busca por slug, retorna `{ exists: true, name: }` (200) ou `{ exists: false }` (404); nenhum outro dado exposto
- [ ] 1.3 Request specs — slug existente, slug inexistente, resposta não vaza dados sensíveis
- [ ] 1.4 `config/initializers/cors.rb` — trocar origin fixo por regex aceitando host genérico e qualquer subdomínio `*.localhost:5173` em dev

## 2. Frontend — fundação

- [ ] 2.1 Gerar componentes shadcn/ui: Button, Input, Label, Card (`components.json` já configurado)
- [ ] 2.2 Reescrever `api.ts` — base da API derivada de `window.location` (troca de porta), com `VITE_API_URL` como override

## 3. Frontend — cadastro de Condominium (host genérico)

- [ ] 3.1 `CondominiumSignupPage` — formulário (nome do condomínio, slug, nome do admin, email do admin, senha do admin) usando os componentes shadcn novos
- [ ] 3.2 Campo de slug auto-sugerido a partir do nome (slugificado), editável manualmente; para de re-sincronizar após edição manual
- [ ] 3.3 Hook de mutação para `POST /api/v1/condominiums`
- [ ] 3.4 Redirect (`window.location.href`) para `<slug>.<host>/login` após sucesso

## 4. Frontend — localizar Condominium existente (host genérico)

- [ ] 4.1 Seção/tela "já tem conta? informe o identificador do seu condomínio"
- [ ] 4.2 Normaliza o slug digitado (trim + lowercase) antes de qualquer uso
- [ ] 4.3 Hook para `GET /api/v1/condominiums/:slug` — trata existente vs não encontrado
- [ ] 4.4 Redirect para `<slug>.<host>/login` quando encontrado; erro inline quando não

## 5. Frontend — login (subdomínio do tenant)

- [ ] 5.1 Reescrever `LoginPage` — remove qualquer referência ao fluxo antigo de auto-registro
- [ ] 5.2 Tratar os 3 erros distintos de `SessionsController#create` (`condominium_not_found`, `invalid_credentials`, `no_active_membership_for_tenant`) com mensagens específicas
- [ ] 5.3 Exibir nome do Condominium no topo do login, via `GET /api/v1/condominiums/:slug` usando o subdomínio atual

## 6. Frontend — roteamento por host

- [ ] 6.1 Util para detectar se a requisição atual está no host genérico ou num subdomínio de tenant
- [ ] 6.2 Ajustar `routes/` — cadastro/localização de Condominium só acessíveis no host genérico; `/login` só no subdomínio (redireciona para o host genérico se acessado sem subdomínio)
- [ ] 6.3 Remover `RegisterPage` antiga e `useAuth.signUp`

## 7. Testes de frontend

- [ ] 7.1 `CondominiumSignupPage.test.tsx` — sucesso, erro de validação (ex: slug duplicado), redirect chamado com a URL certa
- [ ] 7.2 Teste da tela de localizar Condominium — encontrado (redirect), não encontrado (erro inline)
- [ ] 7.3 `LoginPage.test.tsx` reescrita — sucesso, e os 3 casos de erro com mensagens distintas
- [ ] 7.4 Teste da base de URL dinâmica em `api.ts`

## 8. Validação E2E

- [ ] 8.1 Validação manual via browser/curl contra os servidores rodando: cadastro de condomínio no host genérico → redirect para o subdomínio → login bem-sucedido ✓ → logout e busca do mesmo condomínio pelo identificador no host genérico → redirect → login ✓ → tentativa de login com senha errada mostra mensagem específica ✓ → tentativa de login de usuário sem membership nesse tenant mostra mensagem específica ✓ → acesso a `/login` no host genérico redireciona para o cadastro ✓
