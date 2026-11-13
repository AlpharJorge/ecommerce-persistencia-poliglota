# E-commerce com persistência poliglota

Implementação prática do planejamento de Banco de Dados II. O PostgreSQL é a fonte da verdade para pedidos, pagamentos e estoque; o MongoDB guarda catálogo flexível, carrinhos temporários e cache de páginas.


## Execução para avaliação no Windows (sem Docker)

Este é o procedimento recomendado para executar o projeto em um computador novo. Ele não depende do disco `E:` nem de máquina virtual.

### 1. Instalar os pré-requisitos

Instale os programas abaixo usando as opções padrão:

- [Node.js](https://nodejs.org/en/download) versão 20 ou superior
- [PostgreSQL para Windows](https://www.postgresql.org/download/windows/) versão 16 ou superior
- [MongoDB Community Server](https://www.mongodb.com/try/download/community) versão 7 ou superior

Durante a instalação do PostgreSQL, mantenha a porta `5432` e anote a senha escolhida para o usuário administrador `postgres`. Durante a instalação do MongoDB, marque a opção para executá-lo como serviço do Windows e mantenha a porta `27017`.

Como alternativa aos links acima, o PostgreSQL e o MongoDB podem ser baixados e instalados pelo terminal. Abra o PowerShell como Administrador e execute:

```powershell
winget install --id PostgreSQL.PostgreSQL.16 --exact --interactive
winget install --id MongoDB.Server --exact --interactive
```

Os instaladores ainda solicitarão as opções mencionadas acima. O `winget` instala os programas, mas as estruturas e os dados específicos deste projeto são preparados nas etapas 3 e 4.

### 2. Baixar o projeto

Abra o PowerShell e execute:

```powershell
git clone https://github.com/AlpharJorge/ecommerce-persistencia-poliglota.git
cd ecommerce-persistencia-poliglota
npm.cmd install
```

O uso de `npm.cmd` evita o bloqueio de scripts que algumas instalações do PowerShell aplicam ao comando `npm`.

### 3. Criar o usuário e o banco no PostgreSQL

Abra o programa **SQL Shell (psql)** instalado com o PostgreSQL. Aceite servidor, banco e porta padrão pressionando Enter, informe `postgres` como usuário e digite a senha definida durante a instalação. Depois execute:

```sql
CREATE ROLE ecommerce WITH LOGIN PASSWORD 'ecommerce';
CREATE DATABASE ecommerce OWNER ecommerce;
```

Esses dois comandos são executados somente na primeira instalação. Digite `\q` para sair do SQL Shell.

De volta ao PowerShell, dentro da pasta do projeto, localize o `psql` e carregue a estrutura e os dados de demonstração:

```powershell
$psql = (Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin\psql.exe' |
  Sort-Object FullName -Descending |
  Select-Object -First 1).FullName

$env:PGPASSWORD = 'ecommerce'
& $psql -U ecommerce -h 127.0.0.1 -d ecommerce -v ON_ERROR_STOP=1 -f .\sql\001_schema.sql
& $psql -U ecommerce -h 127.0.0.1 -d ecommerce -v ON_ERROR_STOP=1 -f .\sql\002_seed_demo.sql
Remove-Item Env:PGPASSWORD
```

Os dois comandos devem terminar sem mensagens de erro. O primeiro cria tabelas, índices, triggers, função transacional e view; o segundo inclui usuários e produtos de demonstração.

### 4. Preparar o MongoDB e as configurações

Confirme que o serviço do MongoDB está iniciado. Em seguida execute, ainda na pasta do projeto:

```powershell
Copy-Item .env.windows .env -Force
node .\scripts\init-mongo.js
```

O resultado esperado contém a mensagem `MongoDB inicializado com colecoes, indices TTL e catalogo de exemplo.`

### 5. Iniciar e verificar

```powershell
npm.cmd start
```

Mantenha essa janela aberta. Acesse a interface em `http://localhost:3000` e, em outro PowerShell, verifique os dois bancos:

```powershell
Invoke-RestMethod http://localhost:3000/api/health
```

O resultado esperado é `status: ok`, `postgres: True` e `mongo: True`.

Para comprovar o Cache-Aside, consulte duas vezes:

```powershell
Invoke-RestMethod http://localhost:3000/api/products/10000000-0000-0000-0000-000000000001
Invoke-RestMethod http://localhost:3000/api/products/10000000-0000-0000-0000-000000000001
```

A primeira resposta deve indicar `source: database` e a segunda, `source: cache`.

### Solução de problemas

- `npm.ps1 não pode ser carregado`: use `npm.cmd install` e `npm.cmd start`.
- `ECONNREFUSED 127.0.0.1:5432`: inicie o serviço do PostgreSQL.
- `ECONNREFUSED 127.0.0.1:27017`: inicie o serviço do MongoDB.
- A porta `3000` já está em uso: encerre o outro programa ou altere `PORT` no arquivo `.env`.
- A role ou o banco `ecommerce` já existe: não repita os dois comandos de criação; prossiga para a carga dos arquivos SQL.

## Instalação automatizada usada no ambiente de desenvolvimento (`E:`)

Esta alternativa foi criada para a máquina original do projeto e exige que o disco `E:` exista. Para outro computador, prefira o procedimento de avaliação acima. O PostgreSQL será instalado em `E:\BancoDeDados\PostgreSQL`. O MongoDB portátil e seus dados ficarão em `E:\Dowloads\BancoDeDados`. Abra o PowerShell na pasta do projeto e execute:

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
