# E-commerce com persistência poliglota

Implementação prática do planejamento de Banco de Dados II. O PostgreSQL é a fonte da verdade para pedidos, pagamentos e estoque; o MongoDB guarda catálogo flexível, carrinhos temporários e cache de páginas.

## O que já está implementado

- PostgreSQL com constraints, chaves estrangeiras, índices, view gerencial, stored function e triggers.
- Pedido ACID: pedido, itens e pagamento são confirmados juntos ou sofrem rollback.
- Baixa atômica de estoque: duas compras simultâneas não conseguem vender a mesma última unidade.
- Auditoria em `inventory_movements`.
- MongoDB com catálogo de atributos variáveis, carrinhos com TTL de 24 horas e cache com TTL de 10 minutos.
- Cache-Aside ao consultar produto.
- Write-Through imediato e outbox transacional para recuperar falhas de sincronização.
- API Node.js/Express dividida em Controller, Service e Repository.
- Massa de 100 mil pedidos e benchmark com e sem índice.
- Teste de carga com throughput e percentis de latência do cache.
- Docker Compose para subir os três serviços.
- Documento de arquitetura e modelagem com diagramas ER e de coleções.

## Como executar nativamente no Windows sem máquina virtual

O PostgreSQL será instalado em `E:\BancoDeDados\PostgreSQL`. O MongoDB portátil e seus dados ficarão em `E:\Dowloads\BancoDeDados`, evitando o cache obrigatório do Windows Installer no `C:`. Abra o PowerShell na pasta do projeto e execute:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\instalar-nativo-windows.ps1
```

Aceite a janela de Administrador. Depois da instalação, inicie o projeto com:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-windows.ps1
```

A interface ficará disponível em `http://localhost:3000` e a API em `http://localhost:3000/api`. Esse modo não usa WSL, Hyper-V ou máquina virtual. O Docker Compose permanece no repositório como entregável acadêmico.

Depois da primeira instalação, também é possível iniciar dando dois cliques em `INICIAR_PROJETO.cmd`.

## Como executar com Docker

Pré-requisito: Docker Desktop aberto.

```powershell
docker compose up --build
```

Quando aparecer `API disponivel`, valide:

```powershell
Invoke-RestMethod http://localhost:3000/api/health
Invoke-RestMethod http://localhost:3000/api/products/10000000-0000-0000-0000-000000000001
```

Na primeira consulta de produto, `source` será `database`; na segunda, será `cache`.

## Rotas principais

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/api/health` | Estado do PostgreSQL e MongoDB |
| GET | `/api/products/:id` | Página do produto com Cache-Aside |
| PUT | `/api/products/:id/core` | Atualiza preço, estoque ou status no PostgreSQL |
| PUT | `/api/products/:id/catalog` | Atualiza descrição, imagens e especificações no MongoDB |
| DELETE | `/api/products/:id/cache` | Invalida o cache para testes controlados |
| GET | `/api/carts/:userId` | Consulta carrinho |
| PUT | `/api/carts/:userId` | Salva carrinho com expiração de 24 horas |
| POST | `/api/users/:userId/checkout` | Finaliza pedido com transação ACID |
| GET | `/api/orders/:id` | Consulta pedido e pagamento |

## Exemplos para a apresentação

Salvar um carrinho:

```powershell
$body = @{
  items = @(
    @{ productId = '10000000-0000-0000-0000-000000000001'; quantity = 1 }
  )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Put `
  -Uri http://localhost:3000/api/carts/11111111-1111-1111-1111-111111111111 `
  -ContentType application/json -Body $body
```

Finalizar o pedido:

```powershell
$body = @{
  items = @(
    @{ productId = '10000000-0000-0000-0000-000000000001'; quantity = 1 }
  )
  paymentMethod = 'pix'
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post `
  -Uri http://localhost:3000/api/users/11111111-1111-1111-1111-111111111111/checkout `
  -ContentType application/json -Body $body
```

Demonstrar dois clientes disputando a última unidade:

```powershell
.\scripts\demo-concorrencia.ps1
```

O resultado esperado é um pedido aprovado e uma resposta HTTP 409 com estoque insuficiente. O script usa o mesmo usuário nas duas requisições porque a concorrência relevante é sobre o produto.

## Benchmark de índice

Execute dentro do contêiner da API:

```powershell
docker compose exec api npm run seed
docker compose exec api npm run benchmark
docker compose exec api npm run load-test
```

O script remove temporariamente `idx_orders_user_created_at`, mede a consulta do histórico de um cliente, recria o índice e repete a medição. O índice é sempre restaurado ao final.

O gerador cria pedidos, itens e pagamentos sintéticos. Para não alterar o estoque real nem produzir 100 mil eventos de sincronização sem utilidade, ele desativa apenas o trigger de baixa durante a carga e o reativa na mesma transação. Execute essa carga somente no ambiente de desenvolvimento do projeto.

O teste de carga invalida o cache uma vez, mede a leitura fria e depois executa 500 leituras com concorrência 25. Os valores podem ser alterados:

```powershell
docker compose exec -e TOTAL_REQUESTS=2000 -e CONCURRENCY=50 api npm run load-test
```

## Documentos do projeto

- `docs/ARQUITETURA_E_MODELAGEM.md`: diagramas, normalização, modelo de documentos e fluxos de consistência.
- `docs/ROTEIRO_DEMONSTRACAO.md`: sequência para apresentar cache, TTL, concorrência, carga e benchmark.
- `docs/CHECKLIST_REQUISITOS.md`: rastreabilidade entre a especificação e as evidências no repositório.

## Consultas para comprovação

View gerencial:

```sql
SELECT * FROM vw_order_summary ORDER BY created_at DESC LIMIT 20;
```

Auditoria do estoque:

```sql
SELECT p.sku, m.quantity, m.stock_after, m.created_at
FROM inventory_movements m
JOIN products p ON p.id = m.product_id
ORDER BY m.created_at DESC;
```

Eventos de sincronização:

```sql
SELECT id, event_type, attempts, processed_at, last_error
FROM sync_outbox
ORDER BY id DESC LIMIT 20;
```

## Decisão de consistência entre os bancos

PostgreSQL e MongoDB não participam da mesma transação distribuída. Por isso a API tenta atualizar o MongoDB imediatamente após alterar o PostgreSQL e, ao mesmo tempo, grava um evento na `sync_outbox` dentro da transação relacional. Se o MongoDB estiver indisponível, o worker repete a sincronização. A operação é idempotente: repetir o mesmo snapshot não duplica dados.

## Reiniciar os dados

Este comando apaga apenas os volumes Docker deste projeto e recria os dados de demonstração:

```powershell
docker compose down -v
docker compose up --build
```
