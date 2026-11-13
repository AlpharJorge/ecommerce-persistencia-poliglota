# Checklist de requisitos e evidências

| Requisito | Situação | Evidência |
|---|---|---|
| Combinação SQL e NoSQL | Atendido | PostgreSQL e MongoDB em `docker-compose.yml` |
| Modelo relacional normalizado até 3FN | Atendido | `sql/001_schema.sql` e `ARQUITETURA_E_MODELAGEM.md` |
| Transações ACID | Atendido | Função `create_order` |
| Restrições de integridade | Atendido | PK, FK, UNIQUE e CHECK no esquema SQL |
| Índices planejados | Atendido | Índices de pedidos, itens, auditoria e outbox |
| View | Atendido | `vw_order_summary` |
| Stored procedure ou função | Atendido | `create_order` |
| Trigger de regra crítica | Atendido | `trg_order_item_stock` |
| Modelo NoSQL justificado | Atendido | Catálogo, carrinho e cache no MongoDB |
| Rotinas e índices NoSQL | Atendido | `mongo/init.js`, incluindo dois TTL indexes |
| API REST | Atendido | Node.js e Express em `src` |
| Arquitetura em camadas | Atendido | Controller, Service e Repository |
| Sincronização SQL e NoSQL | Atendido | Write-Through, Cache-Aside e outbox |
| Docker Compose | Atendido | API, PostgreSQL e MongoDB |
| Povoamento automatizado mínimo de 100 mil | Atendido e executado | 100.000 pedidos e 100.000 itens; `docs/RESULTADOS_TESTES.md` |
| Comparação com e sem índice | Atendido e executado | 13,480 ms sem índice e 0,153 ms com índice |
| Latência e throughput | Atendido e executado | 502,21 req/s; percentis registrados em `docs/RESULTADOS_TESTES.md` |
| Teste de consistência concorrente | Atendido e executado | Uma compra aprovada e uma resposta HTTP 409 |
| Diagrama ER | Atendido | Mermaid em `ARQUITETURA_E_MODELAGEM.md` |
| Diagrama de coleções | Atendido | Mermaid em `ARQUITETURA_E_MODELAGEM.md` |
| Repositório e documentação final | Em preparação | README detalhado, relatório técnico, resultados e histórico Git |
