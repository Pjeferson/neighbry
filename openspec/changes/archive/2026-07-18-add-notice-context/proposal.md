## Why

Neighbry ainda não tem mecanismo de comunicação do condomínio com seus moradores e equipe — a quarta peça do domínio descrita em `openspec/project.md` seção 3. Sem `Notice`, o admin não tem como avisar formalmente (com rastreio de quem leu) sobre assembleias, manutenções ou avisos gerais, que é um dos fluxos centrais de qualquer sistema de gestão condominial.

## What Changes

- Novo bounded context `Notice`, isolado dos demais (`Tenancy`, `Registry`, `Billing`) via namespace Ruby próprio, lendo `Tenancy::Membership` e `Registry::Occupancy` diretamente (leitura entre contexts, mesmo padrão já usado em `Billing`) — nenhuma mutação cruzada, nenhum evento de domínio necessário nesta v1.
- `Aviso`: criado apenas por admin, com `titulo`, `corpo` e um único `tipo` de destinatário (`todos`, `moradores`, `staff`, `torre` ou `unidade`). Imutável após criado — a única mudança permitida é `ativo: false` (correção de erro, o aviso some da visão do morador mas fica no banco para auditoria).
- `Notice::Leitura`: tabela única fazendo dois papéis — snapshot dos destinatários calculados no momento da criação do `Aviso`, e registro de confirmação de leitura (`confirmado_em`, preenchido por ação manual do morador, nunca automática). Sem tabela separada para "lista de destinatários".
- Cálculo de destinatários: `todos`/`moradores`/`staff` resolvidos via `Tenancy::Membership` (por `role`); `torre`/`unidade` resolvidos via `Registry::Occupancy` ativa (qualquer papel — owner, responsible ou morador comum), deduplicado por `user_id` (uma `Person` pode ocupar mais de uma `Unit` na mesma `Building`).
- Confirmação de leitura é bloqueada se o `Aviso` estiver `ativo: false`.
- Painel de confirmação (contador "N de M confirmaram" + lista de quem confirmou) visível apenas para admin, atualizado via polling nesta v1 — ActionCable/Turbo Streams fica para v2 (aprendizado futuro junto com o frontend).
- Sem evento de domínio `AvisoConfirmado` nesta v1 — não há assinante e o polling não depende dele.

## Capabilities

### New Capabilities
- `notice`: criação de avisos direcionados (todos/moradores/staff/torre/unidade) com snapshot de destinatários, confirmação manual de leitura e painel de acompanhamento para o admin.

### Modified Capabilities
(nenhuma — leitura direta de `Tenancy::Membership` e `Registry::Occupancy`, sem nenhuma mudança de schema ou comportamento nesses contexts)

## Impact

- Novas tabelas: `avisos`, `leituras` — ambas com `condominium_id` denormalizado, seguindo a convenção de nomes sem prefixo de módulo já usada em `Tenancy`/`Registry`/`Billing`.
- Novos endpoints em `/api/v1/notice/*` (avisos, confirmação de leitura, listagem para o painel admin).
- Nenhuma migração ou mudança de código em `Tenancy`, `Registry` ou `Billing`.
