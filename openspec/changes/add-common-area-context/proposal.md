## Why

Neighbry ainda não tem cadastro de espaços comuns — a quinta peça do domínio descrita em `openspec/project.md` seção 2. Sem `CommonArea`, o admin não tem onde registrar salão de festas, churrasqueira, quadra ou piscina, nem os moradores onde consultar horário de funcionamento e regras de uso desses espaços.

## What Changes

- Novo bounded context `CommonArea`, isolado dos demais — sem nenhuma leitura ou dependência de `Tenancy`, `Registry`, `Billing` ou `Notice` além da checagem padrão de `Tenancy::Membership` para autorização (mesmo padrão de `AdminCheckable` já usado nos outros quatro contexts).
- `CommonArea`: `nome`, `descricao`, `capacidade`, `horario_funcionamento`, `regras_uso`, `ativo`. Recurso do condomínio inteiro — sem vínculo com nenhuma `Building` do `Registry`.
- Livremente editável pelo admin após criado — diferente de `Taxa`/`Aviso`, não há histórico financeiro nem confirmação de leitura que justifique imutabilidade aqui.
- Cadastro e edição restritos a admin; listagem e visualização abertas a qualquer `User` com `Tenancy::Membership` ativo no condomínio (informação não-sensível).
- **BREAKING**: nenhuma — capability inteiramente nova.

## Capabilities

### New Capabilities
- `common-area`: catálogo de espaços comuns do condomínio (cadastro, edição e consulta), sem sistema de reservas nesta v1.

### Modified Capabilities
(nenhuma)

## Impact

- Nova tabela: `common_areas`, com `condominium_id` denormalizado, seguindo a convenção de nomes sem prefixo de módulo já usada em `Tenancy`/`Registry`/`Billing`/`Notice`.
- Novos endpoints em `/api/v1/common_areas`.
- Nenhuma migração ou mudança de código em `Tenancy`, `Registry`, `Billing` ou `Notice`.
- Fora de escopo nesta v1 (documentado para quando existir um bounded context `Reservation` futuro): `taxa_de_uso`, `requer_aprovacao`, `tipo`/categoria, fotos, sistema de reservas com controle de concorrência.
