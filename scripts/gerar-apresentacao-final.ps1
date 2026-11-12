$ErrorActionPreference = 'Stop'

$Project = Split-Path -Parent $PSScriptRoot
$OutputDir = Join-Path $Project 'entrega'
$QaDir = Join-Path $OutputDir 'qa\apresentacao'
$Output = Join-Path $OutputDir 'Apresentacao_Projeto_Banco_de_Dados_II.pptx'
$InterfaceImage = Join-Path $OutputDir 'interface.png'

New-Item -ItemType Directory -Force $OutputDir | Out-Null
New-Item -ItemType Directory -Force $QaDir | Out-Null

function C([int]$r, [int]$g, [int]$b) { return $r + (256 * $g) + (65536 * $b) }

$BG = C 7 10 15
$PANEL = C 17 20 27
$BLUE = C 47 107 255
$BLUE2 = C 110 155 255
$WHITE = C 242 244 248
$MUTED = C 158 163 175
$GREEN = C 54 211 153
$RED = C 248 113 113
$GRID = C 49 55 67

$ppt = New-Object -ComObject PowerPoint.Application
$ppt.Visible = -1

try {
  $pres = $ppt.Presentations.Add()
  $pres.PageSetup.SlideWidth = 960
  $pres.PageSetup.SlideHeight = 540

  function AddText($slide, [string]$text, [double]$x, [double]$y, [double]$w, [double]$h, [double]$size = 20, [int]$color = $WHITE, [bool]$bold = $false, [int]$align = 1) {
    $shape = $slide.Shapes.AddTextbox(1, $x, $y, $w, $h)
    $shape.Line.Visible = 0
    $shape.Fill.Visible = 0
    $shape.TextFrame.MarginLeft = 0
    $shape.TextFrame.MarginRight = 0
    $shape.TextFrame.MarginTop = 0
    $shape.TextFrame.MarginBottom = 0
    $shape.TextFrame.WordWrap = -1
    $shape.TextFrame.TextRange.Text = $text
    $shape.TextFrame.TextRange.Font.Name = 'Arial'
    $shape.TextFrame.TextRange.Font.Size = $size
    $shape.TextFrame.TextRange.Font.Bold = if ($bold) { -1 } else { 0 }
    $shape.TextFrame.TextRange.Font.Color.RGB = $color
    $shape.TextFrame.TextRange.ParagraphFormat.Alignment = $align
    return $shape
  }

  function AddBox($slide, [double]$x, [double]$y, [double]$w, [double]$h, [int]$fill = $PANEL, [int]$line = $GRID, [double]$radius = 5) {
    $shape = $slide.Shapes.AddShape(5, $x, $y, $w, $h)
    $shape.Fill.ForeColor.RGB = $fill
    $shape.Line.ForeColor.RGB = $line
    $shape.Line.Weight = 1
    return $shape
  }

  function AddRule($slide, [double]$x1, [double]$y1, [double]$x2, [double]$y2, [int]$color = $GRID, [double]$weight = 1) {
    $line = $slide.Shapes.AddLine($x1, $y1, $x2, $y2)
    $line.Line.ForeColor.RGB = $color
    $line.Line.Weight = $weight
    return $line
  }

  function AddArrow($slide, [double]$x1, [double]$y1, [double]$x2, [double]$y2) {
    $line = AddRule $slide $x1 $y1 $x2 $y2 $BLUE 2.5
    $line.Line.EndArrowheadStyle = 3
    return $line
  }

  function AddTitle($slide, [string]$title, [string]$section = '') {
    if ($section) { AddText $slide $section.ToUpper() 56 30 300 20 10 $BLUE2 $true | Out-Null }
    AddText $slide $title 56 53 850 52 30 $WHITE $true | Out-Null
    AddRule $slide 56 111 904 111 $GRID 1 | Out-Null
  }

  function AddSlideNumber($slide, [int]$number) {
    AddText $slide ([string]$number) 880 507 24 16 9 $MUTED $false 2 | Out-Null
  }

  function AddNotes($slide, [string]$notes) {
    try {
      $body = $slide.NotesPage.Shapes.Placeholders.Item(2)
      $body.TextFrame.TextRange.Text = $notes
    } catch { }
  }

  function NewSlide() {
    $slide = $pres.Slides.Add($pres.Slides.Count + 1, 12)
    $slide.FollowMasterBackground = 0
    $slide.Background.Fill.ForeColor.RGB = $BG
    return $slide
  }

  $s = NewSlide
  AddText $s 'BANCO DE DADOS II' 58 48 300 22 11 $BLUE2 $true | Out-Null
  AddText $s 'Persistência Poliglota em um Sistema de Gestão de Estoque' 58 125 700 145 40 $WHITE $true | Out-Null
  AddText $s 'PostgreSQL, MongoDB e API Node.js' 60 293 520 34 21 $MUTED $false | Out-Null
  AddRule $s 60 360 230 360 $BLUE 4 | Out-Null
  AddText $s "Jorge Victor Ferreira de Lima`nKarlos Eduardo Souza da Cruz" 60 386 420 62 17 $WHITE $false | Out-Null
  AddText $s 'UFAL  Unidade Educacional Penedo  2026' 60 474 600 22 11 $MUTED $false | Out-Null
  AddNotes $s 'Apresentar o projeto como um sistema de gestão de estoque integrado a um e-commerce. Explicar que o foco acadêmico está na persistência poliglota e na consistência dos dados.'

  $s = NewSlide
  AddTitle $s 'Problema e divisão de responsabilidades' 'Contexto'
  AddText $s 'DADOS TRANSACIONAIS' 70 150 330 24 12 $BLUE2 $true | Out-Null
  AddText $s "Pedidos, pagamentos e estoque exigem integridade referencial e transações ACID. Uma falha não pode confirmar apenas parte da compra." 70 186 345 120 20 $WHITE $false | Out-Null
  AddText $s 'PostgreSQL 16' 70 330 300 32 28 $WHITE $true | Out-Null
  AddText $s 'Fonte da verdade para dinheiro e estoque' 70 370 320 50 16 $MUTED $false | Out-Null
  AddRule $s 475 145 475 444 $GRID 2 | Out-Null
  AddText $s 'DADOS FLEXÍVEIS E TEMPORÁRIOS' 535 150 360 24 12 $BLUE2 $true | Out-Null
  AddText $s "As especificações variam por categoria. Carrinhos abandonados e páginas em cache precisam expirar sem limpeza manual." 535 186 350 120 20 $WHITE $false | Out-Null
  AddText $s 'MongoDB' 535 330 300 32 28 $WHITE $true | Out-Null
  AddText $s 'Catálogo, carrinhos e cache com TTL' 535 370 330 50 16 $MUTED $false | Out-Null
  AddSlideNumber $s 2
  AddNotes $s 'Comparar as duas necessidades. O PostgreSQL protege as operações críticas. O MongoDB atende a flexibilidade e a expiração automática.'

  $s = NewSlide
  AddTitle $s 'Arquitetura em camadas' 'Solução'
  AddBox $s 55 205 175 92 $PANEL $GRID | Out-Null
  AddText $s 'Interface web' 63 228 159 28 18 $WHITE $true 2 | Out-Null
  AddText $s 'Cliente e avaliador' 68 263 149 18 12 $MUTED $false 2 | Out-Null
  AddBox $s 300 165 220 170 $PANEL $BLUE | Out-Null
  AddText $s 'API Node.js' 330 190 160 26 23 $WHITE $true 2 | Out-Null
  AddText $s "Controllers`nServices`nRepositories" 335 232 150 78 16 $MUTED $false 2 | Out-Null
  AddBox $s 675 125 225 120 (C 14 28 54) $BLUE | Out-Null
  AddText $s 'PostgreSQL 16' 700 155 175 24 22 $WHITE $true 2 | Out-Null
  AddText $s 'Pedidos, pagamentos e estoque' 700 192 175 40 13 $MUTED $false 2 | Out-Null
  AddBox $s 675 335 225 120 (C 14 28 54) $BLUE | Out-Null
  AddText $s 'MongoDB' 700 365 175 24 22 $WHITE $true 2 | Out-Null
  AddText $s 'Catálogo, carrinhos e cache' 700 402 175 40 13 $MUTED $false 2 | Out-Null
  AddArrow $s 230 251 300 251 | Out-Null
  AddArrow $s 520 220 675 185 | Out-Null
  AddArrow $s 520 285 675 395 | Out-Null
  AddArrow $s 788 245 788 335 | Out-Null
  AddText $s 'ACID' 575 176 70 20 12 $BLUE2 $true 2 | Out-Null
  AddText $s 'Cache Aside' 555 365 100 20 12 $BLUE2 $true 2 | Out-Null
  AddText $s 'Outbox' 807 280 70 20 12 $BLUE2 $true 2 | Out-Null
  AddSlideNumber $s 3
  AddNotes $s 'Mostrar a separação Controller, Service e Repository. Explicar que a outbox recupera a sincronização quando o MongoDB estiver indisponível.'

  $s = NewSlide
  AddTitle $s 'Modelo relacional normalizado' 'PostgreSQL'
  $entities = @(
    @{n='USERS';x=55;y=145}, @{n='ORDERS';x=270;y=145}, @{n='ORDER ITEMS';x=485;y=145},
    @{n='PAYMENTS';x=270;y=275}, @{n='CATEGORIES';x=55;y=390}, @{n='PRODUCTS';x=270;y=390}, @{n='MOVIMENTOS';x=610;y=390}
  )
  foreach ($e in $entities) {
    AddBox $s $e.x $e.y 155 72 $PANEL $GRID | Out-Null
    AddText $s $e.n ($e.x + 8) ($e.y + 18) 139 22 16 $WHITE $true 2 | Out-Null
  }
  AddArrow $s 210 181 270 181 | Out-Null
  AddArrow $s 425 181 485 181 | Out-Null
  AddArrow $s 347 217 347 275 | Out-Null
  AddArrow $s 210 426 270 426 | Out-Null
  AddArrow $s 425 426 610 426 | Out-Null
  AddArrow $s 405 390 535 217 | Out-Null
  AddArrow $s 640 217 700 390 | Out-Null
  AddText $s '1:N' 222 160 35 16 10 $MUTED $false 2 | Out-Null
  AddText $s '1:N' 437 160 35 16 10 $MUTED $false 2 | Out-Null
  AddText $s '1:1' 357 238 35 16 10 $MUTED $false 2 | Out-Null
  AddText $s 'A função create_order confirma pedido, itens e pagamento na mesma transação. O trigger de estoque usa uma atualização condicional e registra a auditoria.' 55 480 820 42 16 $MUTED $false | Out-Null
  AddSlideNumber $s 4
  AddNotes $s 'Destacar terceira forma normal, chaves estrangeiras, restrições CHECK, função transacional, view e trigger.'

  $s = NewSlide
  AddTitle $s 'Coleções e expiração automática' 'MongoDB'
  AddText $s 'product_catalog' 70 150 250 28 24 $WHITE $true | Out-Null
  AddText $s "Descrição, imagens e especificações variáveis por categoria.`nÍndice único em productId." 70 194 250 85 17 $MUTED $false | Out-Null
  AddText $s 'carts' 365 150 180 28 24 $WHITE $true | Out-Null
  AddText $s "Itens temporários por usuário.`nTTL de 24 horas." 365 194 200 70 17 $MUTED $false | Out-Null
  AddText $s 'page_cache' 655 150 200 28 24 $WHITE $true | Out-Null
  AddText $s "Página pronta para leitura rápida.`nTTL de 10 minutos." 655 194 220 70 17 $MUTED $false | Out-Null
  AddRule $s 70 310 865 310 $GRID 2 | Out-Null
  AddText $s 'Documento ativo' 70 346 170 22 16 $WHITE $true | Out-Null
  AddRule $s 235 357 540 357 $BLUE 5 | Out-Null
  AddText $s 'expiresAt' 555 346 120 22 16 $BLUE2 $true | Out-Null
  AddArrow $s 680 357 820 357 | Out-Null
  AddText $s 'remoção automática' 690 386 160 22 14 $MUTED $false 2 | Out-Null
  AddText $s 'Os índices TTL impedem o crescimento indefinido de carrinhos abandonados e páginas vencidas.' 70 454 790 42 17 $WHITE $false | Out-Null
  AddSlideNumber $s 5
  AddNotes $s 'Mostrar no MongoDB Compass os índices expiresAt_1 durante a demonstração.'

  $s = NewSlide
  AddTitle $s 'Fluxos de leitura e sincronização' 'Consistência'
  AddText $s 'CACHE ASIDE' 65 145 180 20 11 $BLUE2 $true | Out-Null
  AddText $s '1  Consultar cache' 65 190 230 28 19 $WHITE $true | Out-Null
  AddArrow $s 285 204 390 204 | Out-Null
  AddText $s '2  Montar com os dois bancos' 410 190 270 28 19 $WHITE $true | Out-Null
  AddArrow $s 685 204 785 204 | Out-Null
  AddText $s '3  Salvar por 10 min' 800 190 130 48 17 $WHITE $true | Out-Null
  AddRule $s 65 275 895 275 $GRID 2 | Out-Null
  AddText $s 'WRITE THROUGH E OUTBOX' 65 310 250 20 11 $BLUE2 $true | Out-Null
  AddText $s '1  Confirmar no PostgreSQL' 65 355 240 28 19 $WHITE $true | Out-Null
  AddArrow $s 310 369 420 369 | Out-Null
  AddText $s '2  Gravar evento na transação' 440 355 260 28 19 $WHITE $true | Out-Null
  AddArrow $s 705 369 790 369 | Out-Null
  AddText $s '3  Atualizar MongoDB' 805 355 125 48 17 $WHITE $true | Out-Null
  AddText $s 'Se o MongoDB falhar, o worker repete o evento com upsert idempotente.' 65 449 780 34 17 $MUTED $false | Out-Null
  AddSlideNumber $s 6
  AddNotes $s 'Primeiro demonstrar a leitura database e depois cache. Na escrita, explicar que não existe transação distribuída entre os bancos.'

  $s = NewSlide
  AddTitle $s 'Interface do sistema' 'MVP'
  if (Test-Path $InterfaceImage) {
    $pic = $s.Shapes.AddPicture($InterfaceImage, 0, -1, 55, 132, 610, 350)
    $pic.Line.Visible = -1
    $pic.Line.ForeColor.RGB = $GRID
  }
  AddText $s 'Demonstração' 710 145 190 28 22 $WHITE $true | Out-Null
  AddText $s "Consulta de produtos`nCarrinho com TTL`nFinalização com PIX`nAtualização de estoque`nConsulta de pedidos" 710 190 200 190 18 $MUTED $false | Out-Null
  AddText $s 'http://localhost:3000' 710 428 200 22 14 $BLUE2 $true | Out-Null
  AddSlideNumber $s 7
  AddNotes $s 'Abrir a aplicação e demonstrar as funções. A interface é apenas a camada de apresentação. As regras permanecem na API e nos bancos.'

  $s = NewSlide
  AddTitle $s 'O índice reduziu a consulta em aproximadamente 88 vezes' 'Benchmark'
  AddText $s 'SEM ÍNDICE' 70 165 150 20 11 $MUTED $true | Out-Null
  AddBox $s 70 202 700 54 (C 50 28 31) $RED | Out-Null
  AddText $s '13,480 ms  Sequential Scan' 88 217 420 24 20 $WHITE $true | Out-Null
  AddText $s 'COM ÍNDICE' 70 305 150 20 11 $MUTED $true | Out-Null
  AddBox $s 70 342 22 54 (C 20 55 48) $GREEN | Out-Null
  AddText $s '0,153 ms  Index Scan' 110 357 360 24 20 $WHITE $true | Out-Null
  AddText $s '99.909 linhas descartadas sem indexação' 70 448 500 24 16 $MUTED $false | Out-Null
  AddText $s '100.000' 790 192 120 44 32 $WHITE $true 2 | Out-Null
  AddText $s 'pedidos de benchmark' 785 239 130 36 13 $MUTED $false 2 | Out-Null
  AddSlideNumber $s 8
  AddNotes $s 'Os tempos pertencem à execução local de 12 de novembro de 2026. O script remove o índice, mede, recria o índice e mede novamente.'

  $s = NewSlide
  AddTitle $s 'Carga do cache e concorrência de estoque' 'Testes'
  AddText $s '502,21' 65 150 180 50 34 $WHITE $true | Out-Null
  AddText $s 'requisições por segundo' 65 200 190 24 14 $MUTED $false | Out-Null
  AddText $s '34,61 ms' 285 150 180 50 34 $WHITE $true | Out-Null
  AddText $s 'percentil 50' 285 200 150 24 14 $MUTED $false | Out-Null
  AddText $s '155,66 ms' 505 150 180 50 34 $WHITE $true | Out-Null
  AddText $s 'percentil 95' 505 200 150 24 14 $MUTED $false | Out-Null
  AddText $s '500' 755 150 120 50 34 $WHITE $true | Out-Null
  AddText $s 'respostas do cache' 735 200 170 24 14 $MUTED $false 2 | Out-Null
  AddRule $s 65 270 895 270 $GRID 2 | Out-Null
  AddText $s 'DUAS COMPRAS PARA UMA UNIDADE' 65 310 300 20 11 $BLUE2 $true | Out-Null
  AddBox $s 65 355 230 72 $PANEL $GREEN | Out-Null
  AddText $s 'Pedido aprovado' 85 372 190 22 19 $WHITE $true 2 | Out-Null
  AddText $s 'estoque final 0' 85 401 190 18 13 $MUTED $false 2 | Out-Null
  AddArrow $s 295 391 430 391 | Out-Null
  AddBox $s 430 355 230 72 $PANEL $RED | Out-Null
  AddText $s 'Segunda tentativa' 450 372 190 22 19 $WHITE $true 2 | Out-Null
  AddText $s 'HTTP 409' 450 401 190 18 13 $RED $true 2 | Out-Null
  AddText $s 'Uma única baixa foi registrada na auditoria.' 700 365 190 58 16 $MUTED $false | Out-Null
  AddSlideNumber $s 9
  AddNotes $s 'O teste executou 500 leituras com concorrência 25. Depois, duas compras simultâneas disputaram a última unidade. O banco confirmou apenas uma.'

  $s = NewSlide
  AddTitle $s 'Requisitos atendidos e roteiro de demonstração' 'Entrega'
  AddText $s "✓ PostgreSQL e MongoDB`n✓ ACID, constraints, índices, view e triggers`n✓ Documentos, TTL e cache`n✓ API em camadas e sincronização`n✓ 100 mil registros e benchmark`n✓ Teste de carga e concorrência" 65 145 420 250 18 $WHITE $false | Out-Null
  AddRule $s 520 145 520 425 $GRID 2 | Out-Null
  AddText $s 'SEQUÊNCIA PARA A BANCA' 570 145 270 20 11 $BLUE2 $true | Out-Null
  AddText $s "1  Saúde dos bancos`n2  Cache miss e cache hit`n3  Carrinho com TTL`n4  Compra e atualização de estoque`n5  Concorrência da última unidade`n6  Resultados de desempenho" 570 190 310 230 18 $MUTED $false | Out-Null
  AddText $s 'O projeto não contém rota administrativa oculta ou backdoor.' 65 461 760 28 16 $GREEN $true | Out-Null
  AddSlideNumber $s 10
  AddNotes $s 'Encerrar relacionando cada demonstração a um requisito. A apresentação substitui o vídeo como entregável do MVP.'

  $pres.SaveAs($Output, 24)
  $pres.Export($QaDir, 'PNG', 1280, 720)
  Write-Output $Output
} finally {
  if ($pres) { $pres.Close() }
  $ppt.Quit()
}
