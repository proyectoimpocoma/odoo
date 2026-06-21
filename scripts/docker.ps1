param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

$RootDir = Resolve-Path (Join-Path $PSScriptRoot "..")
$DbName = if ($env:ODOO_DB) { $env:ODOO_DB } else { "mi_empresa" }
$OdooConfig = if ($env:ODOO_CONFIG) { $env:ODOO_CONFIG } else { "/etc/odoo/odoo.conf" }
$DefaultModules = if ($env:ODOO_MODULES) { $env:ODOO_MODULES } else { "theme_impocoma,risk_module" }

Set-Location $RootDir

function Show-Usage {
    @"
Uso:
  pwsh ./scripts/docker.ps1 <comando> [argumentos]

Comandos:
  help                         Muestra esta ayuda
  config                       Valida docker-compose.yml
  build                        Construye la imagen de Odoo
  rebuild                      Construye la imagen de Odoo sin cache
  init                         Primera ejecucion: levanta Docker e instala $DefaultModules
  up                           Levanta Postgres y Odoo en segundo plano
  up-logs                      Levanta Postgres y Odoo en primer plano
  down                         Detiene y elimina contenedores sin borrar datos
  stop                         Detiene los servicios
  restart                      Reinicia Odoo
  logs [servicio]              Sigue logs de odoo o db
  ps                           Muestra estado de servicios
  shell                        Entra al contenedor de Odoo
  db                           Entra a psql
  db-query <sql>               Ejecuta una consulta SQL
  install <modulos>            Instala modulos, ejemplo: risk_module
  update <modulos>             Actualiza modulos, ejemplo: risk_module
  update-all                   Actualiza $DefaultModules
  module-status                Muestra estado de modulos principales
  backup                       Exporta backups/mi_empresa_YYYYmmdd_HHMMSS.sql
  restore <archivo.sql>        Restaura un SQL en $DbName
  reset                        Borra contenedores, volumenes, base y filestore

Variables opcionales:
  ODOO_DB=mi_empresa
  ODOO_MODULES=theme_impocoma,risk_module
"@
}

function Require-Arg {
    param(
        [string]$Value,
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        [Console]::Error.WriteLine("Error: $Message")
        Show-Usage
        exit 2
    }
}

function Compose {
    docker compose @args
}

function Invoke-OdooModuleCommand {
    param(
        [string]$Mode,
        [string]$Modules
    )

    Write-Host "Ejecutando -$Mode $Modules en la base $DbName..."
    Compose exec -T odoo odoo -c $OdooConfig -d $DbName "-$Mode" $Modules --stop-after-init

    Write-Host "Reiniciando Odoo..."
    Compose restart odoo
}

function Wait-Database {
    Write-Host "Esperando a que PostgreSQL este listo..."
    for ($Attempt = 1; $Attempt -le 60; $Attempt++) {
        Compose exec -T db pg_isready -U odoo -d $DbName *> $null
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Start-Sleep -Seconds 2
    }

    throw "PostgreSQL no estuvo listo a tiempo."
}

function Initialize-Environment {
    Write-Host "Levantando contenedores..."
    Compose up --build -d
    Wait-Database
    Invoke-OdooModuleCommand -Mode "i" -Modules $DefaultModules
}

function Confirm-Reset {
    Write-Host "Esto borrara contenedores, volumenes, base de datos y filestore."
    $Confirmation = Read-Host "Escribe '$DbName' para confirmar"

    if ($Confirmation -ne $DbName) {
        Write-Host "Cancelado."
        exit 1
    }
}

function Test-IsWindows {
    return $env:OS -eq "Windows_NT"
}

function Backup-Database {
    New-Item -ItemType Directory -Force -Path "backups" | Out-Null
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupFile = Join-Path "backups" "$DbName`_$Timestamp.sql"

    if (Test-IsWindows) {
        cmd.exe /c "docker compose exec -T db pg_dump -U odoo -d $DbName > `"$BackupFile`""
    } else {
        bash -lc 'docker compose exec -T db pg_dump -U odoo -d "$1" > "$2"' -- $DbName $BackupFile
    }

    Write-Host "Backup creado: $BackupFile"
}

function Restore-Database {
    param([string]$BackupFile)

    Require-Arg $BackupFile "debes indicar el archivo .sql a restaurar"

    if (-not (Test-Path $BackupFile)) {
        [Console]::Error.WriteLine("Error: no existe el archivo $BackupFile")
        exit 1
    }

    if (Test-IsWindows) {
        cmd.exe /c "docker compose exec -T db psql -U odoo -d $DbName < `"$BackupFile`""
    } else {
        bash -lc 'docker compose exec -T db psql -U odoo -d "$1" < "$2"' -- $DbName $BackupFile
    }
}

switch ($Command) {
    { $_ -in @("help", "-h", "--help") } {
        Show-Usage
        break
    }

    "config" {
        Compose config
        break
    }

    "build" {
        Compose build odoo
        break
    }

    "rebuild" {
        Compose build --no-cache odoo
        break
    }

    "init" {
        Initialize-Environment
        break
    }

    "up" {
        Compose up --build -d
        break
    }

    "up-logs" {
        Compose up --build
        break
    }

    "down" {
        Compose down
        break
    }

    "stop" {
        Compose stop
        break
    }

    "restart" {
        Compose restart odoo
        break
    }

    "logs" {
        $Service = if ($Arguments.Count -gt 0) { $Arguments[0] } else { "odoo" }
        Compose logs -f $Service
        break
    }

    { $_ -in @("ps", "status") } {
        Compose ps
        break
    }

    "shell" {
        Compose exec odoo bash
        break
    }

    "db" {
        Compose exec db psql -U odoo -d $DbName
        break
    }

    "db-query" {
        $Sql = if ($Arguments.Count -gt 0) { $Arguments -join " " } else { "" }
        Require-Arg $Sql "debes indicar una consulta SQL"
        Compose exec db psql -U odoo -d $DbName -c $Sql
        break
    }

    "install" {
        $Modules = if ($Arguments.Count -gt 0) { $Arguments[0] } else { "" }
        Require-Arg $Modules "debes indicar uno o mas modulos, separados por coma"
        Invoke-OdooModuleCommand -Mode "i" -Modules $Modules
        break
    }

    "update" {
        $Modules = if ($Arguments.Count -gt 0) { $Arguments[0] } else { "" }
        Require-Arg $Modules "debes indicar uno o mas modulos, separados por coma"
        Invoke-OdooModuleCommand -Mode "u" -Modules $Modules
        break
    }

    "update-all" {
        Invoke-OdooModuleCommand -Mode "u" -Modules $DefaultModules
        break
    }

    "module-status" {
        Compose exec db psql -U odoo -d $DbName -c "select name, state from ir_module_module where name in ('risk_module', 'theme_impocoma') order by name;"
        break
    }

    "backup" {
        Backup-Database
        break
    }

    "restore" {
        $BackupFile = if ($Arguments.Count -gt 0) { $Arguments[0] } else { "" }
        Restore-Database -BackupFile $BackupFile
        break
    }

    "reset" {
        Confirm-Reset
        Compose down -v
        break
    }

    default {
        [Console]::Error.WriteLine("Error: comando desconocido: $Command")
        Show-Usage
        exit 2
    }
}
