## 1. Backend — endpoint de existência de Condominium e CORS

- [x] 1.1 Rota `GET /api/v1/condominiums/:slug` (`param: :slug`, sem `ResolvesTenant`)
- [x] 1.2 `Api::V1::CondominiumsController#show` — busca por slug, retorna `{ exists: true, name: }` (200) ou `{ exists: false }` (404); nenhum outro dado exposto
- [x] 1.3 Request specs — slug existente, slug inexistente, resposta não vaza dados sensíveis
- [x] 1.4 `config/initializers/cors.rb` — trocar origin fixo por regex aceitando host genérico e qualquer subdomínio `*.localhost:5173` em dev

## 2. Frontend — fundação

- [x] 2.1 Gerar componentes shadcn/ui: Button, Input, Label, Card (`components.json` já configurado)
- [x] 2.2 Reescrever `api.ts` — base da API derivada de `window.location` (troca de porta), com `VITE_API_URL` como override

## 3. Frontend — cadastro de Condominium (host genérico)

- [x] 3.1 `CondominiumSignupPage` — formulário (nome do condomínio, slug, nome do admin, email do admin, senha do admin) usando os componentes shadcn novos
- [x] 3.2 Campo de slug auto-sugerido a partir do nome (slugificado), editável manualmente; para de re-sincronizar após edição manual
- [x] 3.3 Hook de mutação para `POST /api/v1/condominiums`
- [x] 3.4 Redirect (`window.location.href`) para `<slug>.<host>/login` após sucesso

## 4. Frontend — localizar Condominium existente (host genérico)

- [x] 4.1 Seção/tela "já tem conta? informe o identificador do seu condomínio"
- [x] 4.2 Normaliza o slug digitado (trim + lowercase) antes de qualquer uso
- [x] 4.3 Hook para `GET /api/v1/condominiums/:slug` — trata existente vs não encontrado
- [x] 4.4 Redirect para `<slug>.<host>/login` quando encontrado; erro inline quando não

## 5. Frontend — login (subdomínio do tenant)

- [x] 5.1 Reescrever `LoginPage` — remove qualquer referência ao fluxo antigo de auto-registro
- [x] 5.2 Tratar os 3 erros distintos de `SessionsController#create` (`condominium_not_found`, `invalid_credentials`, `no_active_membership_for_tenant`) com mensagens específicas
- [x] 5.3 Exibir nome do Condominium no topo do login, via `GET /api/v1/condominiums/:slug` usando o subdomínio atual

## 6. Frontend — roteamento por host

- [x] 6.1 Util para detectar se a requisição atual está no host genérico ou num subdomínio de tenant (`lib/tenant.ts`, criado no Grupo 3 pra servir o redirect de cadastro)
- [x] 6.2 Ajustar `routes/` — cadastro/localização de Condominium só acessíveis no host genérico; `/login` só no subdomínio (redireciona para o host genérico se acessado sem subdomínio)
- [x] 6.3 Remover `RegisterPage` antiga e `useAuth.signUp` (inevitável já no Grupo 5 — `useAuth.signUp` removido quebraria `RegisterPage` de qualquer forma)

## 7. Testes de frontend

- [x] 7.1 `CondominiumSignupPage.test.tsx` — sucesso, erro de validação (ex: slug duplicado), redirect chamado com a URL certa
- [x] 7.2 Teste da tela de localizar Condominium — encontrado (redirect), não encontrado (erro inline)
- [x] 7.3 `LoginPage.test.tsx` reescrita — sucesso, e os 3 casos de erro com mensagens distintas (inevitável já no Grupo 5 — a reescrita da página quebrava os testes antigos)
- [x] 7.4 Teste da base de URL dinâmica em `api.ts`

## 8. Validação E2E

- [x] 8.1 Validação manual via curl contra os servidores rodando (backend + Vite dev server): cadastro de condomínio via host genérico ✓ → CORS dinâmico confirmado pro host genérico e para subdomínios arbitrários (não fixo) ✓ → login bem-sucedido no subdomínio do tenant ✓ → senha errada retorna `invalid_credentials` ✓ → usuário sem membership nesse tenant retorna `no_active_membership_for_tenant` ✓ → subdomínio inexistente retorna `condominium_not_found` ✓ → `GET /api/v1/condominiums/:slug` confirma existência (com nome) e ausência, a partir do host genérico e do próprio subdomínio, sem vazar dados sensíveis ✓ → Vite dev server responde em qualquer subdomínio `*.localhost:5173` ✓. Lógica client-side (redirect via `window.location`, guards de rota por host) coberta pelos 34 testes de componente do Grupo 7 — curl não executa JS, essa camada foi validada por lá, não aqui.
