param(
    [ValidateSet('android', 'ios', 'windows', 'web', 'edge')]
    [string]$Platform = 'android',
    [switch]$LaunchEmulator,
    [string]$Device = ''
)

# Uso:
#   .\run.ps1 -Platform windows
#   .\run.ps1 -Platform web
#   .\run.ps1 -Platform edge
#   .\run.ps1 -Platform android -LaunchEmulator
# iOS (solo macOS): ./scripts/run_ios.sh

$flutterBin = "D:\flutter\bin"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "$flutterBin;$sdk\emulator;$sdk\platform-tools;$env:Path"

Set-Location $PSScriptRoot

if ($LaunchEmulator -and $Platform -eq 'android') {
    flutter emulators --launch Pixel_Demo
    Start-Sleep -Seconds 8
}

$target = switch ($Platform) {
    'windows' { 'windows' }
    'web'     { 'chrome' }
    'edge'    { 'edge' }
    'ios'     { 'ios' }
    default   { if ($Device) { $Device } else { 'emulator-5554' } }
}

flutter run -d $target
