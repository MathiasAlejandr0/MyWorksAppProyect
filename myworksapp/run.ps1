param(
    [switch]$LaunchEmulator,
    [string]$Device = "emulator-5554"
)

# iOS (solo macOS): ./scripts/run_ios.sh

$flutterBin = "D:\flutter\bin"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$env:Path = "$flutterBin;$sdk\emulator;$sdk\platform-tools;$env:Path"

Set-Location $PSScriptRoot

if ($LaunchEmulator) {
    flutter emulators --launch Pixel_Demo
    Start-Sleep -Seconds 8
}

flutter run -d $Device
