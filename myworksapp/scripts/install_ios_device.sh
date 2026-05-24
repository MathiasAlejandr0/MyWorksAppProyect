#!/usr/bin/env bash
# Instalar MyWorksApp en un iPhone físico conectado al Mac.
#
# Requisitos:
#   - macOS con Xcode (App Store)
#   - Flutter instalado (https://docs.flutter.dev/get-started/install/macos)
#   - iPhone conectado por USB + cable de confianza
#   - Apple ID en Xcode (Xcode → Settings → Accounts)
#
# Uso:
#   chmod +x scripts/install_ios_device.sh
#   ./scripts/install_ios_device.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> MyWorksApp — instalación en iPhone"
echo ""

# 1. Secrets opcionales (Google Maps)
SECRETS="$ROOT/ios/Flutter/Secrets.xcconfig"
if [[ ! -f "$SECRETS" ]]; then
  echo "⚠️  No existe ios/Flutter/Secrets.xcconfig"
  echo "    La app funciona sin mapas. Para mapas:"
  echo "    cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig"
  echo "    # y añade GOOGLE_MAPS_API_KEY=tu_clave"
  echo ""
fi

# 2. Flutter
if ! command -v flutter &>/dev/null; then
  echo "❌ Flutter no está instalado. Instálalo desde:"
  echo "   https://docs.flutter.dev/get-started/install/macos"
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

echo ""
echo "==> Comprobando entorno"
flutter doctor

echo ""
echo "==> Dispositivos disponibles"
flutter devices

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IMPORTANTE — firma en Xcode (solo la primera vez):"
echo ""
echo "  1. Abre:  open ios/Runner.xcworkspace"
echo "  2. Selecciona el target 'Runner' → Signing & Capabilities"
echo "  3. Marca 'Automatically manage signing'"
echo "  4. Elige tu Team (Apple ID)"
echo "  5. Si falla el Bundle ID, cámbialo a algo único, ej.:"
echo "     com.tunombre.myworksapp"
echo ""
echo "  En el iPhone: Ajustes → General → VPN y gestión de dispositivos"
echo "  → Confía en tu certificado de desarrollador."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -r -p "¿Ya configuraste la firma en Xcode? (s/n): " CONFIRM
if [[ "${CONFIRM,,}" != "s" && "${CONFIRM,,}" != "y" ]]; then
  echo ""
  echo "Abre Xcode ahora:"
  open ios/Runner.xcworkspace
  echo "Configura Team y vuelve a ejecutar este script."
  exit 0
fi

echo ""
echo "==> Instalando en iPhone..."
flutter run --release -d ios
