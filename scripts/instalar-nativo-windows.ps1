$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
  $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
  Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments
  exit
}

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$base = 'E:\BancoDeDados'
$postgresHome = Join-Path $base 'PostgreSQL\16'
$postgresData = Join-Path $postgresHome 'data'
$mongoRoot = 'E:\Dowloads\BancoDeDados\MongoDB'
$mongoHome = Join-Path $mongoRoot 'mongodb-win32-x86_64-windows-8.0.23'
$mongoData = 'E:\Dowloads\BancoDeDados\MongoDBData'
$mongoLogs = 'E:\Dowloads\BancoDeDados\MongoDBLogs'
$mongoZip = 'E:\Dowloads\mongodb-windows-x86_64-8.0.23.zip'
$mongoChecksum = 'E:\Dowloads\mongodb-windows-x86_64-8.0.23.zip.sha256'

New-Item -ItemType Directory -Force -Path $base, $mongoRoot, $mongoData, $mongoLogs | Out-Null

if (-not (Test-Path -LiteralPath (Join-Path $postgresHome 'bin\psql.exe'))) {
  Write-Host 'Instalando PostgreSQL 16 no E:...' -ForegroundColor Cyan
  $pgArgs = '--mode unattended --unattendedmodeui minimal --prefix "{0}" --datadir "{1}" --superpassword ecommerce --servicepassword ecommerce --serverport 5432 --disable-components pgAdmin,stackbuilder' -f $postgresHome, $postgresData
  winget install --id PostgreSQL.PostgreSQL.16 --exact --source winget --accept-source-agreements --accept-package-agreements --override $pgArgs
  if ($LASTEXITCODE -ne 0) { throw "Falha ao instalar PostgreSQL: codigo $LASTEXITCODE" }
}

if (-not (Test-Path -LiteralPath (Join-Path $mongoHome 'bin\mongod.exe'))) {
  Write-Host 'Baixando MongoDB portatil para o E:...' -ForegroundColor Cyan
  curl.exe -L --fail --output $mongoChecksum 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-8.0.23.zip.sha256'
  curl.exe -L --fail --output $mongoZip 'https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-8.0.23.zip'
  $expected = (Get-Content -LiteralPath $mongoChecksum).Split(' ')[0].Trim().ToUpperInvariant()
  $actual = (Get-FileHash -LiteralPath $mongoZip -Algorithm SHA256).Hash
  if ($expected -ne $actual) { throw 'Checksum do MongoDB nao corresponde ao oficial.' }
  Expand-Archive -LiteralPath $mongoZip -DestinationPath $mongoRoot -Force
}

$mongod = Join-Path $mongoHome 'bin\mongod.exe'
if (-not (Get-Process mongod -ErrorAction SilentlyContinue)) {
  Write-Host 'Iniciando MongoDB portatil...' -ForegroundColor Cyan
  Start-Process -FilePath $mongod -ArgumentList @(
    '--dbpath', $mongoData,
    '--logpath', (Join-Path $mongoLogs 'mongod.log'),
    '--logappend', '--bind_ip', '127.0.0.1', '--port', '27017'
  ) -WindowStyle Hidden
  Start-Sleep -Seconds 3
}

$postgresService = Get-Service -Name 'postgresql*16*' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $postgresService) { throw 'Servico PostgreSQL 16 nao encontrado.' }
if ($postgresService.Status -ne 'Running') { Start-Service -Name $postgresService.Name }

$psql = Join-Path $postgresHome 'bin\psql.exe'
$createdb = Join-Path $postgresHome 'bin\createdb.exe'
$env:PGPASSWORD = 'ecommerce'

$roleExists = & $psql -U postgres -h 127.0.0.1 -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='ecommerce'"
if (-not $roleExists) {
  & $psql -U postgres -h 127.0.0.1 -d postgres -v ON_ERROR_STOP=1 -c "CREATE ROLE ecommerce LOGIN PASSWORD 'ecommerce'"
}
$databaseExists = & $psql -U postgres -h 127.0.0.1 -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='ecommerce'"
if (-not $databaseExists) {
  & $createdb -U postgres -h 127.0.0.1 -O ecommerce ecommerce
}

$schemaExists = & $psql -U ecommerce -h 127.0.0.1 -d ecommerce -tAc "SELECT to_regclass('public.users') IS NOT NULL"
if ($schemaExists -ne 't') {
  & $psql -U ecommerce -h 127.0.0.1 -d ecommerce -v ON_ERROR_STOP=1 -f (Join-Path $projectRoot 'sql\001_schema.sql')
}
& $psql -U ecommerce -h 127.0.0.1 -d ecommerce -v ON_ERROR_STOP=1 -f (Join-Path $projectRoot 'sql\002_seed_demo.sql')

Push-Location $projectRoot
try {
  if (-not (Test-Path -LiteralPath 'node_modules')) { npm install }
  Copy-Item -LiteralPath '.env.windows' -Destination '.env' -Force
  node .\scripts\init-mongo.js
} finally {
  Pop-Location
  Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host 'Instalacao nativa concluida no E:.' -ForegroundColor Green
Write-Host 'Execute scripts\iniciar-windows.ps1 para abrir a API.' -ForegroundColor Green
Read-Host 'Pressione Enter para fechar'
