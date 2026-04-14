#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

mkdir -p build

swiftc \
    -O \
    -framework IOKit \
    -o build/cpu-snake \
    Sources/CPUSnake/Snake.swift \
    Sources/CPUSnake/CPUSampler.swift \
    Sources/CPUSnake/GPUSampler.swift \
    Sources/cpu-snake-cli/main.swift

echo "Built: build/cpu-snake"
