#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

NAME="CPUSnake"
SRC="Sources/${NAME}"
BUILD="build"
BUNDLE="${BUILD}/${NAME}.saver"

rm -rf "${BUILD}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp "${SRC}/Info.plist" "${BUNDLE}/Contents/Info.plist"

if [ -d "${SRC}/Resources" ]; then
    cp -R "${SRC}/Resources/." "${BUNDLE}/Contents/Resources/"
fi

swiftc \
    -O \
    -module-name "${NAME}" \
    -framework Cocoa \
    -framework ScreenSaver \
    -framework IOKit \
    -Xlinker -bundle \
    -o "${BUNDLE}/Contents/MacOS/${NAME}" \
    "${SRC}"/*.swift

codesign --force --sign - --timestamp=none "${BUNDLE}"

echo "Built: ${BUNDLE}"
