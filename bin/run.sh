#!/usr/bin/env bash
# ==============================================================================
# Launch Hermes Agent Interactive CLI
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env if present
if [[ -f "$REPO_ROOT/.env" ]]; then
  export $(grep -v '^#' "$REPO_ROOT/.env" | xargs -r 2>/dev/null) || true
fi

# Auto-fallback to Docker if native hermes CLI is not installed
if command -v hermes >/dev/null 2>&1; then
  exec hermes "$@"
elif command -v docker >/dev/null 2>&1; then
  echo "Hermes CLI not found locally. Launching via Docker Compose..."
  docker compose -f "$REPO_ROOT/docker-compose.yml" up -d
  exec docker compose -f "$REPO_ROOT/docker-compose.yml" exec hermes-agent hermes "$@"
else
  echo "Error: Neither 'hermes' nor 'docker' is available. Run ./bin/bootstrap.sh first." >&2
  exit 1
fi
