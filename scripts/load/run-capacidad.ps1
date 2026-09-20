<#
.SYNOPSIS
  Ejecuta la batería de capacidad My Works App (k6).

.EXAMPLE
  .\scripts\load\run-capacidad.ps1 -AnonKey "eyJ..." -Profile smoke
  .\scripts\load\run-capacidad.ps1 -AnonKey "eyJ..." -Full
#>
param(
  [string]$SupabaseUrl = "https://wxqrfcqifkfgawrnqmnj.supabase.co",
  [Parameter(Mandatory = $true)]
  [string]$AnonKey,
  [ValidateSet("smoke", "baseline", "stress", "soak")]
  [string]$Profile = "baseline",
  [string]$UserJwt = "",
  [switch]$Full,
  [switch]$Ceiling
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Require-K6 {
  if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    Write-Host "k6 no está instalado. Ejecuta: winget install GrafanaLabs.k6" -ForegroundColor Yellow
    exit 1
  }
}

function Run-K6([string]$relScript, [string]$profileName, [string]$outName) {
  $outDir = Join-Path $root "scripts\load\results"
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  $export = Join-Path $outDir "$outName.json"
  $scriptPath = Join-Path $root $relScript
  $envArgs = @(
    "run",
    "-e", "SUPABASE_URL=$SupabaseUrl",
    "-e", "SUPABASE_ANON_KEY=$AnonKey",
    "-e", "PROFILE=$profileName",
    "--summary-export=$export",
    $scriptPath
  )
  if ($UserJwt) {
    $envArgs = @(
      "run",
      "-e", "SUPABASE_URL=$SupabaseUrl",
      "-e", "SUPABASE_ANON_KEY=$AnonKey",
      "-e", "PROFILE=$profileName",
      "-e", "SUPABASE_USER_JWT=$UserJwt",
      "--summary-export=$export",
      $scriptPath
    )
  }
  Write-Host "`n>>> k6 $relScript PROFILE=$profileName" -ForegroundColor Cyan
  & k6 @envArgs
  if ($LASTEXITCODE -ne 0) {
    Write-Host "k6 terminó con código $LASTEXITCODE (umbrales o errores). Revisa el resumen." -ForegroundColor Yellow
  }
  Write-Host "Resumen: $export" -ForegroundColor Green
}

Require-K6
Set-Location $root

if ($Full) {
  Run-K6 "scripts\load\k6\catalog.js" "smoke" "catalog-smoke"
  Run-K6 "scripts\load\k6\catalog.js" "baseline" "catalog-baseline"
  Run-K6 "scripts\load\k6\catalog.js" "stress" "catalog-stress"
  Run-K6 "scripts\load\k6\capacity-ceiling.js" "baseline" "capacity-ceiling"
  if ($UserJwt) {
    Run-K6 "scripts\load\k6\mixed-read.js" "baseline" "mixed-baseline"
  }
  Write-Host "`nBatería completa lista. Completa la tabla del runbook con los JSON de scripts/load/results/" -ForegroundColor Green
  exit 0
}

if ($Ceiling) {
  Run-K6 "scripts\load\k6\capacity-ceiling.js" "baseline" "capacity-ceiling"
  exit 0
}

Run-K6 "scripts\load\k6\catalog.js" $Profile "catalog-$Profile"
