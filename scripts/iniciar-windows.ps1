$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

$postgresService = Get-Service -Name 'postgresql*16*' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $postgresService) { throw 'PostgreSQL 16 nao esta instalado. Execute instalar-nativo-windows.ps1.' }
if ($postgresService.Status -ne 'Running') { Start-Service -Name $postgresService.Name }

$mongod = 'E:\Dowloads\BancoDeDados\MongoDB\mongodb-win32-x86_64-windows-8.0.23\bin\mongod.exe'
if (-not (Test-Path -LiteralPath $mongod)) { throw 'MongoDB portatil nao foi encontrado. Execute instalar-nativo-windows.ps1.' }
if (-not (Get-Process mongod -ErrorAction SilentlyContinue)) {
  Start-Process -FilePath $mongod -ArgumentList @(
    '--dbpath', 'E:\Dowloads\BancoDeDados\MongoDBData',
    '--logpath', 'E:\Dowloads\BancoDeDados\MongoDBLogs\mongod.log',
    '--logappend', '--bind_ip', '127.0.0.1', '--port', '27017'
  ) -WindowStyle Hidden
  Start-Sleep -Seconds 3
}

Set-Location $projectRoot
if (-not (Test-Path -LiteralPath '.env')) { Copy-Item -LiteralPath '.env.windows' -Destination '.env' }
if (-not (Test-Path -LiteralPath 'node_modules')) { npm install }
npm start
