# Roteiro de demonstração do MVP

## Preparação

```powershell
docker compose up --build
```

Em outro terminal:

```powershell
Invoke-RestMethod http://localhost:3000/api/health
```

O resultado precisa indicar PostgreSQL e MongoDB ativos.

## 1 Arquitetura e divisão de responsabilidades

Abra `docs/ARQUITETURA_E_MODELAGEM.md` e apresente:

- PostgreSQL como fonte da verdade transacional.
- MongoDB para documentos flexíveis, carrinhos e cache.
- Controller, Service e Repository.
- Outbox para recuperação da sincronização.

## 2 Cache Aside

```powershell
$url = 'http://localhost:3000/api/products/10000000-0000-0000-0000-000000000001'
Invoke-RestMethod -Method Delete "$url/cache"
Invoke-RestMethod $url
Invoke-RestMethod $url
```

Explique que a primeira resposta vem de `database` e a segunda vem de `cache`.

## 3 Carrinho com TTL

```powershell
$body = @{
  items = @(@{
    productId = '10000000-0000-0000-0000-000000000001'
    quantity = 1
  })
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Put `
  -Uri 'http://localhost:3000/api/carts/11111111-1111-1111-1111-111111111111' `
  -ContentType 'application/json' -Body $body
```

Mostre no MongoDB Compass que `expiresAt` é uma data e que existe índice TTL na coleção.

## 4 Transação e concorrência

```powershell
.\scripts\demo-concorrencia.ps1
```

Mostre um pedido aprovado e uma tentativa rejeitada com estoque insuficiente. Em seguida, consulte `inventory_movements` para comprovar a auditoria.

## 5 Carga e benchmark

```powershell
docker compose exec api npm run seed
docker compose exec api npm run benchmark
docker compose exec api npm run load-test
```

Registre na apresentação os tempos reais obtidos na máquina usada. Não use números inventados.

## 6 Encerramento

Conclua relacionando cada evidência aos requisitos:

- integração relacional e não relacional;
- ACID, constraints, índices, view, função e trigger;
- documentos, TTL e cache;
- API e padrão de sincronização;
- 100 mil registros;
- comparação com e sem índice, latência de cache e throughput.
