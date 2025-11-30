#!/usr/bin/env bash
set -euo pipefail

echo "=== Netlify Flutter build script ==="

# Diretório onde o SDK será instalado no ambiente de build
FLUTTER_ROOT="$HOME/flutter"

if [ ! -d "$FLUTTER_ROOT" ]; then
  echo "Clonando Flutter (canal stable)..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
else
  echo "Flutter já presente em $FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

echo "Flutter versão:"; flutter --version || true

echo "Desabilitando analytics e preparando toolchain..."
flutter config --no-analytics
flutter precache --web

echo "Rodando flutter pub get"
flutter pub get

echo "Construindo app web (release)..."
flutter build web --release --base-href /

echo "Build concluído. Diretório de publicação: build/web"
