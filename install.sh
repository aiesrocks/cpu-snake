#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

DEST="${HOME}/Library/Screen Savers"
mkdir -p "${DEST}"
rm -rf "${DEST}/CPUSnake.saver"
cp -R build/CPUSnake.saver "${DEST}/CPUSnake.saver"

echo "Installed to: ${DEST}/CPUSnake.saver"
echo "Open System Settings → Screen Saver → Other and select 'CPUSnake'."
