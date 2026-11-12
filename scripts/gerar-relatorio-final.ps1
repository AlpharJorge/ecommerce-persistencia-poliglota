$ErrorActionPreference = 'Stop'

$Project = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $Project 'entrega'
$Output = Join-Path $OutputDir 'Relatorio_Tecnico_Final_Banco_de_Dados_II.docx'
$ArchitectureImage = Join-Path $Project 'docs\diagrama_arquitetura.svg'
$ErImage = Join-Path $Project 'docs\diagrama_er.svg'
$InterfaceImage = Join-Path $OutputDir 'interface.png'

New-Item -ItemType Directory -Force $OutputDir | Out-Null

function Color([int]$r, [int]$g, [int]$b) {
  return $r + (256 * $g) + (65536 * $b)
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
  $doc = $word.Documents.Add()
  $doc.PageSetup.PaperSize = 2
  $doc.PageSetup.TopMargin = 72
  $doc.PageSetup.BottomMargin = 72
  $doc.PageSetup.LeftMargin = 78
  $doc.PageSetup.RightMargin = 72

  $normal = $doc.Styles.Item(-1)
  $normal.Font.Name = 'Arial'
  $normal.Font.Size = 11
  $normal.Font.Color = Color 0 0 0
  $normal.ParagraphFormat.SpaceAfter = 6
  $normal.ParagraphFormat.LineSpacingRule = 1
  $normal.ParagraphFormat.Alignment = 3

  $titleStyle = $doc.Styles.Item(-63)
  $titleStyle.Font.Name = 'Arial'
  $titleStyle.Font.Size = 22
  $titleStyle.Font.Bold = $true
  $titleStyle.Font.Color = Color 0 0 0

  $h1 = $doc.Styles.Item(-2)
  $h1.Font.Name = 'Arial'
  $h1.Font.Size = 16
  $h1.Font.Bold = $true
  $h1.Font.Color = Color 0 0 0
  $h1.ParagraphFormat.SpaceBefore = 14
  $h1.ParagraphFormat.SpaceAfter = 7

  $h2 = $doc.Styles.Item(-3)
  $h2.Font.Name = 'Arial'
  $h2.Font.Size = 13
  $h2.Font.Bold = $true
  $h2.Font.Color = Color 0 0 0
  $h2.ParagraphFormat.SpaceBefore = 10
  $h2.ParagraphFormat.SpaceAfter = 5

  $sel = $word.Selection

  function AddParagraph([string]$text, [int]$style = -1, [int]$alignment = 3, [bool]$bold = $false) {
    $sel.Style = $doc.Styles.Item($style)
    $sel.ParagraphFormat.Alignment = $alignment
    $sel.Font.Bold = $bold
    $sel.TypeText($text)
    $sel.TypeParagraph()
    $sel.Font.Bold = $false
  }

  function AddBullet([string]$text) {
    $sel.Style = $doc.Styles.Item(-1)
    $sel.ParagraphFormat.Alignment = 0
    $sel.Range.ListFormat.ApplyBulletDefault()
    $sel.TypeText($text)
    $sel.TypeParagraph()
    $sel.Range.ListFormat.RemoveNumbers()
  }

  function AddTable([string[]]$headers, [object[]]$rows, [double[]]$widths) {
    $range = $sel.Range
    $table = $doc.Tables.Add($range, $rows.Count + 1, $headers.Count)
    $table.Borders.Enable = 1
    $table.AllowAutoFit = $false
    $table.Rows.AllowBreakAcrossPages = $false
    $table.Rows.Item(1).HeadingFormat = $true
    for ($c = 1; $c -le $headers.Count; $c++) {
      $cell = $table.Cell(1, $c)
      $cell.Range.Text = $headers[$c - 1]
      $cell.Range.Font.Name = 'Arial'
      $cell.Range.Font.Size = 10
      $cell.Range.Font.Bold = $true
      $cell.Range.Font.Color = Color 255 255 255
      $cell.Shading.BackgroundPatternColor = Color 31 41 55
      $cell.VerticalAlignment = 1
      if ($widths.Count -ge $c) { $cell.Width = $widths[$c - 1] }
    }
    for ($r = 1; $r -le $rows.Count; $r++) {
      for ($c = 1; $c -le $headers.Count; $c++) {
        $cell = $table.Cell($r + 1, $c)
        $cell.Range.Text = [string]$rows[$r - 1][$c - 1]
        $cell.Range.Font.Name = 'Arial'
        $cell.Range.Font.Size = 9.5
        $cell.Range.Font.Color = Color 0 0 0
        $cell.VerticalAlignment = 1
        if ($widths.Count -ge $c) { $cell.Width = $widths[$c - 1] }
        if (($r % 2) -eq 0) { $cell.Shading.BackgroundPatternColor = Color 239 246 255 }
      }
    }
    $table.Range.ParagraphFormat.SpaceAfter = 3
    $after = $doc.Range($table.Range.End, $table.Range.End)
    $after.InsertParagraphAfter()
    $after.Collapse(0)
    $after.Select()
  }

  function AddPicture([string]$path, [double]$width) {
    if (Test-Path $path) {
      $sel.ParagraphFormat.Alignment = 1
      $shape = $sel.InlineShapes.AddPicture($path)
      $shape.LockAspectRatio = -1
      $shape.Width = $width
      $sel.TypeParagraph()
    }
  }

  AddParagraph 'UNIVERSIDADE FEDERAL DE ALAGOAS' -1 1 $true
  AddParagraph 'CAMPUS ARAPIRACA' -1 1 $true
  AddParagraph 'UNIDADE EDUCACIONAL PENEDO' -1 1 $true
  AddParagraph 'CURSO DE BACHARELADO EM SISTEMAS DE INFORMACAO' -1 1 $true
  $sel.TypeParagraph(); $sel.TypeParagraph(); $sel.TypeParagraph()
  AddParagraph 'JORGE VICTOR FERREIRA DE LIMA' -1 1 $true
  AddParagraph 'KARLOS EDUARDO SOUZA DA CRUZ' -1 1 $true
  $sel.TypeParagraph(); $sel.TypeParagraph(); $sel.TypeParagraph()
  AddParagraph 'Persistencia Poliglota em um Sistema de Gestao de Estoque para E Commerce' -63 1 $false
  AddParagraph 'Relatorio tecnico final de Banco de Dados II' -1 1 $false
  $sel.TypeParagraph(); $sel.TypeParagraph(); $sel.TypeParagraph(); $sel.TypeParagraph()
  AddParagraph 'Penedo AL' -1 1 $false
  AddParagraph '2026' -1 1 $false
  $sel.InsertBreak(7)

  AddParagraph 'Resumo' -2 0
  AddParagraph 'Este trabalho apresenta a implementacao de um sistema de gestao de estoque integrado a um comercio eletronico com persistencia poliglota. O PostgreSQL mantem os dados que exigem integridade transacional, como produtos, estoque, pedidos e pagamentos. O MongoDB armazena o catalogo flexivel, os carrinhos temporarios e o cache das paginas de produto. A API em Node.js e Express coordena os dois bancos por meio de Cache Aside, Write Through e uma outbox transacional. Os testes usaram 100.000 pedidos de benchmark, compararam uma consulta com e sem indice, mediram a carga do cache e comprovaram a protecao da ultima unidade em duas compras simultaneas.'
  AddParagraph 'Palavras chave: persistencia poliglota, PostgreSQL, MongoDB, estoque, concorrencia, cache.' -1 0 $true

  AddParagraph '1 Problema e objetivo' -2 0
  AddParagraph 'O sistema resolve duas necessidades diferentes. Pedidos, pagamentos e estoque precisam de transacoes ACID e integridade referencial. O catalogo possui atributos que mudam conforme a categoria, enquanto carrinhos e paginas em cache precisam expirar automaticamente. A solucao separa essas responsabilidades entre um banco relacional e um banco de documentos.'
  AddParagraph 'O objetivo principal foi implementar e medir uma aplicacao funcional capaz de consultar produtos, manter carrinhos, atualizar estoque, finalizar pedidos e impedir vendas acima da quantidade disponivel.'

  AddParagraph '2 Arquitetura da solucao' -2 0
  AddParagraph 'A API segue uma arquitetura em camadas. Os controllers recebem as requisicoes HTTP. Os services aplicam as regras de negocio e coordenam os bancos. Os repositories concentram consultas SQL e operacoes no MongoDB. Essa divisao permite localizar com clareza as regras de sincronizacao e de consistencia.'
  AddPicture $ArchitectureImage 445
  AddParagraph 'Figura 1 Arquitetura de persistencia poliglota' -1 1
  AddTable @('Camada','Responsabilidade','Tecnologia') @(
    @('Interface','Consulta de produtos, carrinho, pedidos e administracao de estoque','HTML, CSS e JavaScript'),
    @('API','Rotas REST, validacao e regras de negocio','Node.js e Express'),
    @('Dados core','Usuarios, produtos, estoque, pedidos, pagamentos e auditoria','PostgreSQL 16'),
    @('Dados flexiveis','Catalogo, carrinhos e cache de pagina','MongoDB'),
    @('Sincronizacao','Propagacao imediata e recuperacao de falhas','Write Through e outbox')
  ) @(105,225,125)

  AddParagraph '3 Modelo relacional' -2 0
  AddPicture $ErImage 465
  AddParagraph 'Figura 2 Diagrama entidade relacionamento do PostgreSQL' -1 1
  AddParagraph 'O modelo atende a terceira forma normal. Cada tabela representa um conceito do dominio e os atributos dependem de sua chave. Os itens ficam separados dos pedidos, o pagamento possui relacao unica com o pedido e as categorias nao se repetem nos produtos. O total do pedido permanece como um registro financeiro do valor confirmado.'
  AddParagraph '3.1 Integridade e regras criticas' -3 0
  AddBullet 'Chaves primarias UUID ou BIGSERIAL identificam os registros.'
  AddBullet 'Chaves estrangeiras protegem as relacoes entre usuarios, pedidos, produtos, itens e pagamentos.'
  AddBullet 'Restricoes CHECK impedem precos, quantidades e estoques invalidos.'
  AddBullet 'A funcao create_order confirma pedido, itens e pagamento na mesma transacao.'
  AddBullet 'O trigger trg_order_item_stock reduz o estoque por atualizacao condicional e registra a movimentacao.'
  AddBullet 'A view vw_order_summary consolida dados para consultas gerenciais.'

  AddParagraph '4 Modelo de documentos' -2 0
  AddTable @('Colecao','Conteudo','Indice principal','Expiracao') @(
    @('product_catalog','Descricao, imagens, especificacoes variaveis e snapshot do core','productId unico','Sem expiracao'),
    @('carts','Itens selecionados por usuario','userId unico','TTL de 24 horas'),
    @('page_cache','Pagina montada com dados dos dois bancos','productId unico','TTL de 10 minutos')
  ) @(105,205,100,85)
  AddParagraph 'O modelo de documentos evita colunas nulas para especificacoes diferentes. Um celular pode registrar memoria e armazenamento, enquanto uma camiseta registra tamanho e material. Os indices TTL removem automaticamente carrinhos abandonados e paginas vencidas.'

  AddParagraph '5 Consistencia entre os bancos' -2 0
  AddParagraph 'Na leitura Cache Aside, a API procura primeiro a pagina no MongoDB. Quando ocorre uma falta de cache, a API combina o preco e o estoque do PostgreSQL com a descricao e as especificacoes do MongoDB. A resposta montada recebe validade de dez minutos.'
  AddParagraph 'Na escrita, o PostgreSQL confirma a alteracao e grava um evento na sync_outbox dentro da mesma transacao. A API tenta atualizar o snapshot no MongoDB imediatamente. Se o segundo banco estiver indisponivel, o worker repete o evento. O upsert por productId permite repetir a operacao sem duplicar o documento.'

  AddParagraph '6 API e interface' -2 0
  AddPicture $InterfaceImage 465
  AddParagraph 'Figura 3 Interface do sistema em execucao' -1 1
  AddTable @('Metodo','Rota','Finalidade') @(
    @('GET','/api/health','Verifica PostgreSQL e MongoDB'),
    @('GET','/api/products/:id','Consulta produto com Cache Aside'),
    @('PUT','/api/products/:id/core','Atualiza preco, estoque e estado'),
    @('PUT','/api/products/:id/catalog','Atualiza o catalogo flexivel'),
    @('GET e PUT','/api/carts/:userId','Consulta e salva o carrinho'),
    @('POST','/api/users/:userId/checkout','Finaliza o pedido com transacao ACID'),
    @('GET','/api/orders/:id','Consulta pedido, itens e pagamento')
  ) @(65,185,250)

  AddParagraph '7 Experimentos e resultados' -2 0
  AddParagraph '7.1 Povoamento' -3 0
  AddParagraph 'O script automatizado criou 100.000 pedidos e 100.000 itens de benchmark. Depois dos testes funcionais, o banco continha 100.010 pedidos, 100.013 itens e 100.010 pagamentos.'

  AddParagraph '7.2 Comparacao de indice' -3 0
  AddTable @('Cenario','Tempo','Plano') @(
    @('Sem indice','13,480 ms','Sequential Scan e ordenacao'),
    @('Com indice','0,153 ms','Index Scan em idx_orders_user_created_at')
  ) @(145,105,250)
  AddParagraph 'O indice reduziu o tempo medido em aproximadamente 88 vezes. Sem indexacao, o PostgreSQL examinou 99.909 linhas que nao atendiam ao filtro.'

  AddParagraph '7.3 Carga do cache' -3 0
  AddTable @('Metrica','Resultado') @(
    @('Requisicoes','500'),
    @('Concorrencia','25'),
    @('Throughput','502,21 requisicoes por segundo'),
    @('Latencia fria','10,08 ms'),
    @('Percentil 50','34,61 ms'),
    @('Percentil 95','155,66 ms'),
    @('Percentil 99','202,59 ms'),
    @('Respostas do cache','500')
  ) @(245,255)

  AddParagraph '7.4 Concorrencia no estoque' -3 0
  AddParagraph 'Duas compras simultaneas disputaram uma unidade. A primeira criou um pedido pago de R$ 249,90. A segunda recebeu HTTP 409 por estoque insuficiente. O estoque terminou em zero e a auditoria registrou uma unica baixa.'

  AddParagraph '8 Atendimento aos requisitos' -2 0
  AddTable @('Requisito','Evidencia','Situacao') @(
    @('SQL e NoSQL','PostgreSQL e MongoDB integrados pela API','Atendido'),
    @('Modelo ate 3FN','Esquema relacional, constraints e chaves estrangeiras','Atendido'),
    @('ACID, view, funcao e triggers','create_order, vw_order_summary e triggers','Atendido'),
    @('Modelo de documentos e TTL','Catalogo, carrinhos e cache','Atendido'),
    @('API em camadas','Controller, Service e Repository','Atendido'),
    @('Sincronizacao','Cache Aside, Write Through e outbox','Atendido'),
    @('100 mil registros','100.000 pedidos e itens de benchmark','Atendido'),
    @('Desempenho','Benchmark de indice e teste de carga','Atendido'),
    @('Consistencia concorrente','Uma aprovacao e uma rejeicao HTTP 409','Atendido'),
    @('Docker Compose','Arquivo com API e os dois bancos','Disponivel')
  ) @(150,260,90)

  AddParagraph '9 Execucao e demonstracao' -2 0
  AddParagraph 'No Windows, o projeto inicia pelo arquivo INICIAR_PROJETO.cmd e abre a interface em http://localhost:3000. O ambiente nativo usa PostgreSQL e MongoDB no disco E e nao depende de maquina virtual. O repositorio tambem inclui Docker Compose para uma execucao padronizada em maquinas com Docker instalado.'
  AddParagraph 'A demonstracao deve seguir o roteiro existente no projeto. A sequencia recomendada mostra a saude dos bancos, a leitura fria e a leitura em cache, o carrinho com TTL, a finalizacao de pedido, o teste concorrente e os resultados de desempenho.'

  AddParagraph '10 Seguranca e escopo' -2 0
  AddParagraph 'O projeto nao implementa rota administrativa oculta, backdoor ou servico destinado a remover protecoes. A rota /v1/api/oculto_admin citada em um texto inserido na especificacao nao existe no codigo. O MVP academico tambem nao inclui autenticacao. Em uma implantacao publica, as rotas de alteracao devem exigir login e permissao administrativa.'

  AddParagraph '11 Conclusao' -2 0
  AddParagraph 'A implementacao demonstrou que a divisao de responsabilidades entre PostgreSQL e MongoDB atende ao problema proposto. O banco relacional manteve pedidos, pagamentos e estoque consistentes, inclusive sob concorrencia. O banco de documentos ofereceu flexibilidade para o catalogo e expiracao automatica para carrinhos e cache. Os resultados medidos confirmaram o ganho do indice e registraram o comportamento do cache sob carga. O projeto atende aos requisitos tecnicos e possui interface, roteiro e apresentacao para a demonstracao do MVP.'

  foreach ($section in $doc.Sections) {
    $footer = $section.Footers.Item(1)
    $footer.Range.ParagraphFormat.Alignment = 1
    $footer.Range.Font.Name = 'Arial'
    $footer.Range.Font.Size = 9
    $footer.Range.Text = 'Banco de Dados II  '
    $footer.Range.Collapse(0)
    $footer.Range.Fields.Add($footer.Range, 33) | Out-Null
  }

  $doc.Fields.Update() | Out-Null
  $doc.SaveAs2($Output, 16)
  Write-Output $Output
} finally {
  if ($doc) { $doc.Close($false) }
  $word.Quit()
}
