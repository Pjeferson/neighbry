# Neighbry — Sistema de Gestão Condominial — Especificação v1.0

Projeto de aprendizado com foco em **DDD (Domain-Driven Design)** e conceitos de **DDIA (Designing Data-Intensive Applications)**, implementado como **Rails Modular Monolith** + frontend **React**, rodando em **docker-compose**.

---

## 0. Aviso sobre a Origem do Projeto

Este projeto foi iniciado a partir da cópia do esqueleto de um projeto Rails anterior (pra pular a etapa repetitiva de setup). Por causa disso:

- O código pode conter **referências residuais ao domínio do projeto antigo** (nomes de models, dados de seed, fixtures, textos em views, prefixos de variáveis de ambiente, título da aplicação, etc.). Isso deve ser limpo de forma oportunista conforme for encontrado, mas essa limpeza **não** é uma `change` formal do OpenSpec — trate como housekeeping normal nos commits iniciais.
- Já existe uma pasta `docs/` herdada do projeto anterior, contendo **documentação pronta** (como rodar testes, convenções, notas de tooling, setup de CI, etc.). Essa documentação é majoritariamente **de nível de stack e reaproveitável como está** — deve ser revisada e mantida (não reescrita do zero), e referenciada a partir do `openspec/project.md` em vez de duplicada nele, seguindo a abordagem de higiene de contexto discutida para o OpenSpec.
- Qualquer conteúdo específico de domínio dentro dos docs herdados (nomenclatura, exemplos referenciando entidades do projeto antigo) deve ser atualizado pra linguagem de domínio do Neighbry conforme for encontrado.

---

## 1. Visão Geral do Domínio

Sistema para administração de condomínios com múltiplas torres, cobrança de taxas rateadas por metragem de unidade, comunicação síndico↔morador, e controle de acesso (com reconhecimento facial mockado).

---

## 2. Bounded Contexts

Mesmo sendo um monolito, vamos separar o Neighbry em **módulos com fronteiras explícitas** (namespaces Ruby), cada um com seu próprio modelo de domínio, evitando que um "contamine" o outro. Isso é o que Khononov chama de bounded context como limite de módulo dentro de um único deployável.

| Bounded Context | Responsabilidade |
|---|---|
| **Registry** | Torres, Unidades, Pessoas (moradores, prestadores), Papéis (proprietário/inquilino) |
| **Billing** | Taxas (recorrentes/extras), Rateio, Faturas, Boleto/PIX fake, Pagamentos |
| **Notice** | Avisos, Confirmação de leitura, Painel do admin |
| **Access** | Entrada/saída de moradores e visitantes, Reconhecimento facial (mock) |
| **CommonArea** | Cadastro de espaços comuns (reservas ficam para v2) |

Cada módulo deve ter suas próprias tabelas, e comunicação entre módulos acontece via **Domain Events** publicados internamente (ex: via `Rails.configuration.event_bus` ou uma gem tipo `wisper`), nunca via chamada direta de outro módulo. Isso simula a fronteira que existiria caso, no futuro, algum módulo vire um serviço separado (e é o motivo pelo qual a v2 poderá extrair um deles sem reescrever tudo).

---

## 3. Aggregates e Invariantes Principais

### Registry
- **Unidade** (Aggregate Root): pertence a uma Torre; tem metragem (usada no rateio); tem um Morador Titular (responsável) e pode ter Ocupantes adicionais (v2).
  - Invariante: uma Unidade sempre pertence a exatamente uma Torre.
- **Pessoa**: pode ter o papel de Proprietário, Inquilino ou Prestador de Serviço.
  - Invariante: uma Unidade tem no máximo 1 Titular ativo por vez (v1).

### Billing
- **Fatura** (Aggregate Root): agrega uma ou mais Cobranças (taxa recorrente + taxas extras vigentes no período) de uma Unidade.
  - Invariante: uma Fatura não pode ser gerada sem ao menos uma Cobrança.
  - Invariante: valor da Fatura = soma das Cobranças, cada uma calculada proporcionalmente pela metragem da Unidade em relação à metragem total do condomínio (rateio).
- **Taxa** (recorrente ou extra): Value Object com valor total a ratear + periodicidade.
- **Pagamento**: vinculado a uma Fatura; pode ser dado como pago manualmente pelo admin ou "pago" via código PIX/boleto fake.
  - Domain Event: `FaturaPaga` — dispara ao marcar pagamento, podendo no futuro notificar outros módulos.

### Notice
- **Aviso** (Aggregate Root): tem lista de Confirmações de Leitura por Pessoa.
  - Invariante: uma Pessoa só pode confirmar leitura de um Aviso uma vez.
  - Domain Event: `AvisoConfirmado` — atualiza contador no painel admin.

### Access
- **RegistroDeAcesso** (Aggregate Root): entrada ou saída, de Morador ou Visitante, com resultado do mock de reconhecimento facial (sucesso/falha) e liberação (automática ou, no futuro, manual).
  - Invariante v1: todo registro de saída de visitante deve ter um registro de entrada correspondente.

---

## 4. Fluxos Principais

**Geração de Fatura mensal:**
1. Job mensal (Sidekiq) percorre todas as Unidades ativas.
2. Calcula rateio das Taxas vigentes (recorrentes + extras) pela metragem.
3. Cria Fatura + Cobranças + gera código boleto/PIX fake.
4. Dispara evento `FaturaGerada`.

**Pagamento manual pelo Admin:**
1. Admin marca Fatura como paga no painel.
2. Sistema registra Pagamento vinculado.
3. Dispara `FaturaPaga`.

**Aviso com confirmação:**
1. Admin cria Aviso, define destinatários (todos ou por Torre/Unidade).
2. Painel admin mostra contador de confirmações em tempo real (polling ou Turbo Streams do Rails — ótima chance de aprender Hotwire/ActionCable como alternativa "nativa" ao WebSocket).

**Entrada de visitante (mock facial):**
1. Portaria (usuário logado com papel "Porteiro") registra tentativa de acesso.
2. Sistema simula captura + comparação (retorna sucesso/falha configurável ou aleatório).
3. Se sucesso → libera automaticamente e registra `RegistroDeAcesso`.
4. Se falha → v1 não tem fallback manual (fica para v2).

---

## 5. Onde aplicar conceitos de DDIA (mesmo em monolito)

- **Idempotência**: geração de Fatura mensal deve ser idempotente (rodar o job duas vezes não duplica fatura) — bom exercício de constraint única + upsert.
- **Event Sourcing leve**: o histórico de `RegistroDeAcesso` nunca é editado/apagado — é um log append-only, ótimo primeiro contato com o conceito sem precisar de infraestrutura extra.
- **CQRS leve**: separar queries pesadas do painel admin (ex: dashboard de inadimplência) em Query Objects ou até em uma view materializada no Postgres, em vez de calcular tudo on-the-fly com ActiveRecord.
- **Outbox Pattern**: ainda cabe aqui! Ao marcar Fatura como paga dentro de uma transação, grava também um registro na tabela `outbox_events`, que um job separado processa (mesmo sem microserviço, prepara terreno para v2).

---

## 6. Arquitetura Técnica (docker-compose)

```
services:
  - rails (API + views admin, Puma)
  - postgres
  - redis (cache + Sidekiq)
  - sidekiq (jobs: geração de fatura, processamento de outbox)
  - react (frontend separado, consumindo API Rails)
```

Sugestão: Rails em modo API (`--api`) para os endpoints consumidos pelo React, mas mantendo um painel admin server-side simples (Turbo/Hotwire) para o síndico — assim você pratica os dois mundos sem precisar de um segundo backend.

---

## 7. Backlog — Requisitos para Versão 2.0

Registrados aqui para não se perder, mas **fora do escopo do MVP**:

- [ ] Múltiplos ocupantes por unidade (não só 1 titular)
- [ ] Juros e multa automáticos por atraso + bloqueio de acesso a áreas comuns por inadimplência
- [ ] Conciliação bancária automática (import de extrato)
- [ ] Pagamento parcial / parcelamento de dívida
- [ ] Pagamentos do condomínio para fornecedores (contas, funcionários)
- [ ] Sistema de reservas de áreas comuns (com concorrência — bom caso para lock otimista)
- [ ] Sistema de chamados/manutenção (morador → síndico)
- [ ] Dupla alçada de aprovação na portaria (fallback manual quando reconhecimento facial falha)
- [ ] Integração real com hardware (câmeras/catracas)
- [ ] Extração de um ou mais bounded contexts para serviços separados (Go/Node), reaproveitando os Domain Events já existentes como contrato de integração

---

## 8. Próximos Passos Sugeridos

1. Modelar o schema do banco (ERD) para Registry + Billing primeiro (são a espinha dorsal).
2. Definir a estrutura de pastas dos módulos (`app/domains/registry`, `app/domains/billing`, etc.) em vez do `app/models` genérico do Rails.
3. Escolher a gem de eventos de domínio (ex: `wisper`, `dry-events`, ou uma implementação própria simples).
4. Escrever os primeiros testes de invariante do Aggregate `Fatura` (rateio correto) antes de qualquer controller.
5. Revisar a pasta `docs/` herdada do projeto scaffoldado: confirmar o que ainda é válido (setup de testes, tooling), sinalizar o que referencia o domínio antigo para limpeza, e linkar os docs relevantes a partir do `openspec/project.md`.
