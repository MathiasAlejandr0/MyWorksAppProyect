# Link + dump/pull del schema remoto Supabase.
# Requiere: npx supabase login (ya hecho) y Docker Desktop para dump/pull.
#
# Uso (Windows PowerShell 5.1 o 7):
#   powershell -ExecutionPolicy Bypass -File .\scripts\supabase-db-pull.ps1
#   # o si tienes PowerShell 7:
#   pwsh -File .\scripts\supabase-db-pull.ps1

param(
  [Parameter(Mandatory = $false)]
  [string]$ProjectRef = "wxqrfcqifkfgawrnqmnj"
)

$ErrorActionPreference = "Stop"
$appDir = Join-Path $PSScriptRoot "..\myworksapp_app" | Resolve-Path

Write-Host "Working directory: $appDir"
Set-Location $appDir

Write-Host "1) Verificando CLI..."
npx supabase --version

$dockerOk = $false
try {
  $null = Get-Command docker -ErrorAction Stop
  docker info 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { $dockerOk = $true }
} catch {
  $dockerOk = $false
}

if (-not $dockerOk) {
  Write-Host ""
  Write-Host "ERROR: Docker Desktop no esta disponible." -ForegroundColor Red
  Write-Host "Instalalo desde https://docs.docker.com/desktop/ y reinicia la terminal."
  Write-Host "Sin Docker, supabase db pull / db dump no pueden exportar el schema en Windows."
  Write-Host ""
  Write-Host "Mientras tanto el inventario de migraciones esta en:"
  Write-Host "  myworksapp_app/supabase/MIGRATIONS_INVENTORY.md"
  exit 2
}

Write-Host "2) Link al proyecto $ProjectRef..."
npx supabase link --project-ref $ProjectRef

Write-Host "3) Dump schema publico (recomendado si hay conflicto de historial)..."
npx supabase db dump --schema public -f supabase/schema_remote_dump.sql

if (-not (Test-Path "supabase/schema_remote_dump.sql") -or (Get-Item "supabase/schema_remote_dump.sql").Length -lt 100) {
  Write-Host "Dump vacio. Intentando db pull..."
  npx supabase db pull
}

Write-Host "Listo. Revisa supabase/schema_remote_dump.sql o migrations/ y haz commit."
