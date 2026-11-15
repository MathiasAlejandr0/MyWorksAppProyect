# Compila la app Android.
#
#   .\scripts\build-apk.ps1                 # release, una APK por arquitectura (~30 MB arm64)
#   .\scripts\build-apk.ps1 -Mode universal # release, una sola APK (~75 MB, sirve en todo)
#   .\scripts\build-apk.ps1 -Mode aab       # Android App Bundle para Google Play
#   .\scripts\build-apk.ps1 -Mode debug
#
# Release exige SUPABASE_URL y SUPABASE_ANON_KEY (si faltan, la app se cierra
# al abrir). Se leen de dart_defines.json (copia dart_defines.example.json,
# está en .gitignore) o de las variables de entorno del mismo nombre.
# DEMO_PASSWORD es opcional y solo sirve en debug.
#
# Release va ofuscada; los símbolos para leer stack traces quedan en
# build\symbols (no se suben al repo).
param(
    [ValidateSet("split", "universal", "aab", "debug")]
    [string]$Mode = "split"
)

$ErrorActionPreference = "Stop"
$flutterBin = if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT "bin\flutter.bat" } else { "flutter" }

Set-Location (Split-Path $PSScriptRoot -Parent)

$defines = @()
if (Test-Path "dart_defines.json") {
    $defines += "--dart-define-from-file=dart_defines.json"
} elseif ($env:SUPABASE_URL -and $env:SUPABASE_ANON_KEY) {
    $defines += "--dart-define=SUPABASE_URL=$($env:SUPABASE_URL)"
    $defines += "--dart-define=SUPABASE_ANON_KEY=$($env:SUPABASE_ANON_KEY)"
} elseif ($Mode -ne "debug") {
    Write-Host "Falta dart_defines.json o las variables SUPABASE_URL / SUPABASE_ANON_KEY." -ForegroundColor Red
    Write-Host "Copia dart_defines.example.json a dart_defines.json y completa los valores."
    exit 1
}

$releaseFlags = @("--release", "--obfuscate", "--split-debug-info=build\symbols")

Write-Host "==> flutter pub get"
& $flutterBin pub get

Write-Host "==> Compilando ($Mode)..."
switch ($Mode) {
    "split" {
        & $flutterBin build apk @releaseFlags --split-per-abi @defines
        $outputs = Get-ChildItem "build\app\outputs\flutter-apk\app-*-release.apk"
    }
    "universal" {
        & $flutterBin build apk @releaseFlags @defines
        $outputs = Get-ChildItem "build\app\outputs\flutter-apk\app-release.apk"
    }
    "aab" {
        & $flutterBin build appbundle @releaseFlags @defines
        $outputs = Get-ChildItem "build\app\outputs\bundle\release\app-release.aab"
    }
    "debug" {
        & $flutterBin build apk --debug @defines
        $outputs = Get-ChildItem "build\app\outputs\flutter-apk\app-debug.apk"
    }
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$destDir = "..\releases"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Write-Host ""
Write-Host "Listo:"
foreach ($file in $outputs) {
    $dest = Join-Path $destDir ("MyWorksApp-" + $file.Name)
    Copy-Item $file.FullName $dest -Force
    $mb = [Math]::Round($file.Length / 1MB, 1)
    Write-Host "  $((Resolve-Path $dest).Path)  ($mb MB)"
}
if ($Mode -eq "split") {
    Write-Host ""
    Write-Host "Para teléfonos usa app-arm64-v8a-release.apk (casi todos los Android desde 2017)."
    Write-Host "app-armeabi-v7a es para equipos viejos de 32 bits; app-x86_64 para emuladores."
}
