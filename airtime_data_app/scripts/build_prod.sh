#!/usr/bin/env bash
# Build the Flutter web app for production.
# Selects the prod AppConfig via --dart-define=PROD=true so the app targets
# the production API instead of localhost. Override the host with:
#   API_BASE_URL=https://example.com/api/v1 ./scripts/build_prod.sh
set -euo pipefail

cd "$(dirname "$0")/.."

API_BASE_URL="${API_BASE_URL:-}"

ARGS=(build web --release --dart-define=PROD=true)
if [ -n "$API_BASE_URL" ]; then
  ARGS+=(--dart-define=API_BASE_URL="$API_BASE_URL")
fi

flutter "${ARGS[@]}"

echo "Built build/web for production. Deploy with: firebase deploy --only hosting"
