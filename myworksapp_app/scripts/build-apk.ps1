param(
    [ValidateSet("release", "debug")]
    [string]$Mode = "release"
)

$flutterBin = if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT "bin\flutter.bat" } else { "flutter" }

Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "==> flutter pub get"
& $flutterBin pub get

Write-Host "==> Compilando APK ($Mode)..."
if ($Mode -eq "release") {
    & $flutterBin build apk --release
    $apk = "build\app\outputs\flutter-apk\app-release.apk"
} else {
    & $flutterBin build apk --debug
    $apk = "build\app\outputs\flutter-apk\app-debug.apk"
}

if (Test-Path $apk) {
    $destDir = "..\releases"
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $dest = Join-Path $destDir "MyWorksApp-android-$Mode.apk"
    Copy-Item $apk $dest -Force
    Write-Host ""
    Write-Host "APK lista:"
    Write-Host "  $((Resolve-Path $apk).Path)"
    Write-Host "  $((Resolve-Path $dest).Path)"
} else {
    Write-Host "Error: no se encontró el APK generado." -ForegroundColor Red
    exit 1
}
