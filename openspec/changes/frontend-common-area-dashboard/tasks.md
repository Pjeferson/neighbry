## 1. Backend — rename doorman → service_provider

- [x] 1.1 `Tenancy::Membership#role` enum — `doorman` vira `service_provider`
- [x] 1.2 `Tenancy::Invitation#role` enum — mesmo rename (enum duplicado)
- [x] 1.3 `Registry::RegisterServiceProvider` — concede `role: "service_provider"` (não mais `"resident"` hardcoded) ao chamar `Tenancy::InviteMember`
- [x] 1.4 `Notice::ResolveDestinatarios::STAFF_ROLES` — `%w[admin manager doorman]` vira `%w[admin manager service_provider]`
- [x] 1.5 Atualizar specs de teste existentes que citam `doorman`: `spec/domains/tenancy/membership_spec.rb`, `spec/services/notice/resolve_destinatarios_spec.rb`, `spec/integration/registry_tenancy_reconciliation_spec.rb`

## 2. Backend — role na resposta de login

- [x] 2.1 `Api::V1::Auth::SessionsController#create` — inclui `role` da `Membership` na resposta de sucesso
- [x] 2.2 Request/model specs cobrindo a resposta com `role`

## 3. Frontend — fundação de persona

- [x] 3.1 `authStore` — `User` ganha campo `role`
- [x] 3.2 `useAuth.signIn` — captura `role` da resposta de login e passa pro store
- [x] 3.3 `lib/persona.ts` (ou equivalente) — função pura `getPersona(role)` mapeando `admin|manager -> "admin"`, `service_provider -> "service_provider"`, `resident -> "resident"`
- [x] 3.4 Gerar componentes shadcn/ui novos: `Table`, `Badge`, `Dialog`, `Textarea`, `Switch`

## 4. Frontend — Sidebar por persona

- [x] 4.1 `Sidebar` reescrita — 5 itens (Unidades/Minha Unidade, Avisos, Faturas, Espaços, Reservas), filtrados e ordenados por persona conforme a matriz do design.md
- [x] 4.2 Itens sem tela implementada ainda ficam desabilitados/placeholder ("em breve"), exceto "Espaços"

## 5. Frontend — CommonArea admin (CRUD)

- [x] 5.1 `useCommonAreas` — hook de listagem (`GET /api/v1/common_areas`)
- [x] 5.2 `useCreateCommonArea` / `useUpdateCommonArea` — hooks de mutação (`POST`/`PATCH /api/v1/common_areas`)
- [x] 5.3 `AdminCommonAreaView` — listagem em `<Table>`: nome, capacidade, horário, status (`Badge` ativo/inativo), ação de editar
- [x] 5.4 `CommonAreaFormDialog` — modal (`Dialog`) de criar/editar, reaproveitado pelas duas ações; campos: nome, descrição (`Textarea`), capacidade, horário de funcionamento, regras de uso (`Textarea`). Ajuste em relação ao planejado: `ativo` NÃO entrou no dialog — ficou só o toggle inline (5.5), evita duplicar a mesma ação em dois lugares
- [x] 5.5 Toggle de `ativo` inline na tabela (`Switch` + `Badge`), sem precisar abrir o modal

## 6. Frontend — CommonArea morador/prestador (catálogo)

- [ ] 6.1 `ResidentCommonAreaView` — catálogo em cards, somente leitura: nome, capacidade, horário, regras de uso, status
- [ ] 6.2 Reaproveitada tal qual para a persona `service_provider` (mesma view, sem ações administrativas)
- [ ] 6.3 Estado vazio ("nenhum espaço cadastrado ainda") e de carregamento (texto simples, sem skeleton)

## 7. Frontend — rota e composição por persona

- [ ] 7.1 Rota `/common-areas` (dentro de `_authenticated`) — escolhe `AdminCommonAreaView` ou `ResidentCommonAreaView` a partir da persona do usuário logado
- [ ] 7.2 Dashboard placeholder (`_authenticated/index.tsx`) ganha link/redirect pra a primeira tela funcional de cada persona (opcional — avaliar durante a implementação)

## 8. Testes de frontend

- [ ] 8.1 Testes de `getPersona` — cobre os 4 valores de `role` mapeando pra persona certa
- [ ] 8.2 Testes de `Sidebar` — itens certos por persona, placeholders desabilitados
- [ ] 8.3 Testes de `AdminCommonAreaView` — listagem, criar via modal, editar via modal, toggle de `ativo`
- [ ] 8.4 Testes de `ResidentCommonAreaView` — listagem em cards, sem ações administrativas visíveis
- [ ] 8.5 Teste de que a rota `/common-areas` renderiza a view certa por persona

## 9. Testes de backend (rename)

- [ ] 9.1 Rodar suíte completa após o rename — nenhuma referência residual a `"doorman"` deve quebrar
- [ ] 9.2 Specs cobrindo `RegisterServiceProvider` concedendo `role: "service_provider"` (não `"resident"`)

## 10. Validação E2E

- [ ] 10.1 Validação manual via curl + browser: login como admin retorna `role: "admin"` ✓ → cria/edita/desativa um `CommonArea` pela UI ✓ → login como morador vê catálogo em cards, sem ações administrativas ✓ → login como prestador (via `RegisterServiceProvider` com `grant_access`) recebe `role: "service_provider"` e vê a mesma visão de morador (sem edição) ✓ → sidebar mostra os itens certos, na ordem certa, por persona ✓
