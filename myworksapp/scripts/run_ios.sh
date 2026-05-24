#!/usr/bin/env bash
# Ejecutar en macOS con Xcode instalado:
#   chmod +x scripts/run_ios.sh && ./scripts/run_ios.sh
#
# Para iPhone físico, usa mejor:
#   ./scripts/install_ios_device.sh
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter devices
flutter run -d ios
