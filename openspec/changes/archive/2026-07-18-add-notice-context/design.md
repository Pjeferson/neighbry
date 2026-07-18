## Context

`Tenancy`, `Registry` e `Billing` já estão implementados e arquivados, estabelecendo o padrão de bounded context do projeto e um precedente direto para `Notice`: leitura direta (não mutação) de models de outro bounded context é aceitável quando é só uma consulta — `Billing::FaturaPolicy` já lê `Registry::Occupancy` diretamente, `Registry::AdminCheckable` já lê `Tenancy::Membership` diretamente. `Notice` reaproveita exatamente esse padrão para calcular destinatários, sem precisar de nenhum Domain Event novo nem chamada a service object de outro context.

## Goals / Non-Goals

**Goals:**
- Permitir que o admin comunique um grupo específico (todos, moradores, staff, uma torre ou uma unidade) com rastreio de quem confirmou a leitura.
- Manter o snapshot de destinatários estável no tempo — o contador de confirmações não deve mudar por causa de gente entrando/saindo do condomínio depois do aviso criado.
- Reaproveitar a leitura cross-context já validada em `Billing` (`Registry::Occupancy` ativa, qualquer papel) para resolver destinatários por torre/unidade.

**Non-Goals:**
- Atualização em tempo real via WebSocket (ActionCable/Turbo Streams) — v1 usa polling; v2 fica reservado para quando o frontend React existir, como aprendizado combinado.
- Evento de domínio `AvisoConfirmado` — sem assinante nesta v1, o polling consulta `Notice::Leitura` diretamente.
- Edição de `Aviso` após criado — só desativação (`ativo: false`).
- Múltiplos alvos por `Aviso` (ex: duas torres numa lista) — sempre um alvo só.
- Fallback ou notificação para `Person` sem `User` (sem email/acesso concedido) — por definição, essas pessoas não têm como confirmar leitura de nada no sistema.

## Decisions

### Notice::Leitura como tabela única (snapshot + confirmação)
Alternativa considerada: duas tabelas — uma para a lista de destinatários calculada na criação, outra para registrar confirmações. Descartada porque toda confirmação já pressupõe pertencer à lista de destinatários; separar as duas só duplicaria a chave `(aviso_id, user_id)` em dois lugares sem necessidade. Decisão final: uma linha por destinatário é criada no momento do `Aviso` (com `confirmado_em: nil`), e confirmar é um `UPDATE` nessa mesma linha — nunca um `INSERT` novo. Isso dá de graça: idempotência (confirmar duas vezes não duplica nada) e autorização implícita (sem linha, sem como confirmar — não precisa de policy separada checando "é destinatário?").

### Destinatários calculados por dois caminhos diferentes, conforme o tipo
`todos`/`moradores`/`staff` são resolvidos só por `role` em `Tenancy::Membership` (`status: active`) — não precisam tocar `Registry`. `torre`/`unidade` exigem `Registry::Occupancy` ativa (qualquer papel — owner, responsible ou morador comum, mesma regra já usada em `Billing` para "unidade ativa"), porque `Membership` não tem noção de unidade. Essa assimetria é aceita conscientemente, não é vista como inconsistência: papéis administrativos (`staff`) não estão amarrados a uma `Unit`, moradores estão.

### Deduplicação obrigatória no cálculo de torre
`Registry` já permite que a mesma `Person` tenha `Occupancy` ativa em mais de uma `Unit` do mesmo condomínio (cenário coberto na spec de `Registry`). Isso significa que alguém pode ocupar duas unidades da mesma `Building` — sem deduplicar por `user_id`, um `Aviso` tipo `torre` tentaria criar duas linhas de `Notice::Leitura` para a mesma pessoa, inflando o "total de destinatários" no contador. A query de resolução de destinatários SHALL aplicar `.distinct` por `user_id`, e a tabela SHALL ter um índice único em `(aviso_id, user_id)` como defesa em profundidade — mesmo padrão de "aplicação + banco" já usado em `Registry::Occupancy` e `Billing::Fatura`.

### Aviso imutável, correção via desativação silenciosa
Mesmo padrão já estabelecido para `Taxa` (`Billing`) e `Invitation` (`Tenancy`): depois de criado, nenhum campo de `Aviso` muda exceto `ativo`. Diferente de `Taxa` (onde a correção é desativar + criar um novo, sem vínculo), aqui desativar um `Aviso` errado SHALL fazê-lo desaparecer da lista que o morador vê — não fica visível como "cancelado", simplesmente some, como se nunca tivesse existido para quem recebeu. O registro em si e as confirmações já feitas continuam no banco para auditoria do admin.

### Confirmação bloqueada quando Aviso está inativo
Se um `Aviso` for desativado depois de já ter sido visto por alguém que ainda não confirmou, a confirmação SHALL ser rejeitada — consistente com a decisão acima de que um `Aviso` desativado deve se comportar, para o morador, como se nunca tivesse existido.

### Painel de confirmação restrito a admin
Só quem cria (`admin`) enxerga o contador e a lista de quem confirmou — `manager`/`doorman`, mesmo sendo `staff` e podendo aparecer como destinatários, não têm acesso ao painel de acompanhamento nesta v1.

## Risks / Trade-offs

- [Polling gera requisições desnecessárias e tem delay até N segundos] → Mitigação: aceitável para v1; ActionCable é o caminho natural de melhoria e já está planejado como aprendizado futuro, não uma omissão.
- [Aviso tipo `torre`/`unidade` pode ter zero destinatários se a Unit/Building estiver vaga] → Mitigação: mesmo comportamento aceito em `Billing` (nenhuma Taxa aplicável → nenhuma Fatura); não é tratado como erro, só um aviso que nunca será visto por ninguém.
- [Sem evento de domínio, um `Notice` futuro que precise reagir a confirmações de leitura exigiria adicionar o evento depois] → Mitigação: aditivo e de baixo custo quando/se necessário; não vale antecipar sem um consumidor real.

## Migration Plan

Change aditiva, sem impacto em dados existentes: novas tabelas `avisos` e `leituras`, ambas com `condominium_id` não-nulo. Nenhuma migração em `Tenancy`, `Registry` ou `Billing`. Sem necessidade de rollback especial além de reverter as migrations novas.

## Open Questions

Nenhuma pendente — todas as decisões de modelagem foram fechadas durante a exploração que precedeu esta proposta.
