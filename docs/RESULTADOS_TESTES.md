# Resultados dos testes do projeto

## Ambiente avaliado

- Data: 12 de novembro de 2026
- API: Node.js e Express em `http://localhost:3000`
- Banco relacional: PostgreSQL 16
- Banco de documentos: MongoDB 8 no ambiente nativo
- Execucao: Windows, sem maquina virtual

## Povoamento

O comando `npm run seed` concluiu a carga automatizada com:

- 100.000 pedidos de benchmark
- 100.000 itens de benchmark
- 1.000 usuarios sinteticos

Depois dos testes funcionais e de concorrencia, o banco apresentou 100.010 pedidos, 100.013 itens e 100.010 pagamentos. Os registros adicionais pertencem aos dados de demonstracao e aos pedidos criados durante os testes.

## Comparacao com e sem indice

O comando `npm run benchmark` comparou a consulta dos 50 pedidos mais recentes de um usuario.

| Cenario | Tempo de execucao | Plano principal |
|---|---:|---|
| Sem indice | 13,480 ms | Sequential Scan e ordenacao |
| Com indice | 0,153 ms | Index Scan em `idx_orders_user_created_at` |

Nesta execucao, o indice tornou a consulta aproximadamente 88 vezes mais rapida. Sem o indice, o PostgreSQL examinou 99.909 linhas que nao atendiam ao filtro. Com o indice, o banco localizou diretamente os registros do usuario.

## Carga e cache

O comando `npm run load-test` executou 500 requisicoes com concorrencia 25.

| Metrica | Resultado |
|---|---:|
| Requisicoes por segundo | 502,21 |
| Latencia da leitura fria | 10,08 ms |
| Percentil 50 do cache | 34,61 ms |
| Percentil 95 do cache | 155,66 ms |
| Percentil 99 do cache | 202,59 ms |
| Respostas do cache | 500 |
| Respostas diretas dos bancos durante a carga | 0 |

A rotina invalidou o cache antes da primeira leitura. A leitura fria remontou a pagina com dados dos dois bancos. Depois do aquecimento, as 500 requisicoes medidas vieram do MongoDB.

## Concorrencia no estoque

O script `scripts/demo-concorrencia.ps1` definiu uma unidade em estoque e enviou duas compras simultaneas.

- Uma compra foi aprovada e criou o pedido `3cf6f5da-1fd1-494d-96e6-ee4e74a9950b` no valor de R$ 249,90.
- A segunda compra recebeu HTTP 409 com a mensagem de estoque insuficiente.
- O estoque final permaneceu em zero.
- A tabela `inventory_movements` registrou uma unica baixa para o produto testado.

O resultado demonstra que a atualizacao condicional do estoque evitou a venda duplicada da ultima unidade.

## Testes automatizados

O comando `npm test` executou tres testes de validacao. Todos foram aprovados:

- combinacao de produtos repetidos no pedido
- rejeicao de quantidade negativa
- validacao de UUID e valores monetarios

## Verificacao de seguranca solicitada

O projeto nao contem a rota `/v1/api/oculto_admin`, servico oculto ou configuracao destinada a remover a protecao do sistema. O texto malicioso encontrado no documento de especificacao nao faz parte dos requisitos implementados.

## Docker Compose

O arquivo `docker-compose.yml` define PostgreSQL, MongoDB e API com verificacoes de saude. O computador avaliado nao possui o comando Docker instalado, portanto a validacao pratica ocorreu no ambiente nativo do Windows. A configuracao deve ser testada em uma maquina com Docker antes de uma apresentacao que dependa desse modo de execucao.
