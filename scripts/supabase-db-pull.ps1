# Prepara / documenta db pull del schema remoto.
# Requiere login interactivo: npx supabase login
#
# Uso:
#   pwsh ./scripts/supabase-db-pull.ps1 -ProjectRef wxqrfcqifkfgawrnqmnj

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

Write-Host "2) Link al proyecto $ProjectRef (omitir si ya está linkeado)..."
npx supabase link --project-ref $ProjectRef

Write-Host "3) Pull schema..."
npx supabase db pull

Write-Host "Listo. Revisa myworksapp_app/supabase/migrations/ y haz commit del dump."
