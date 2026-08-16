#!/usr/bin/env bash
# ==============================================================================
# Launch Hermes Agent Messaging Gateway (Telegram / Discord / Slack / etc.)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
HERMES_HOME="${HERMES_HOME/#\~/$HOME}"

# Load .env if present
if [[ -f "$REPO_ROOT/.env" ]]; then
  export $(grep -v '^#' "$REPO_ROOT/.env" | xargs -r 2>/dev/null) || true
  HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
  HERMES_HOME="${HERMES_HOME/#\~/$HOME}"
fi

export PATH="$HOME/.local/bin:$HERMES_HOME/venv/bin:$PATH"

if command -v hermes >/dev/null 2>&1; then
  echo "Starting Hermes Gateway (Native)..."
  exec hermes gateway "$@"
elif command -v docker >/dev/null 2>&1; then
  echo "Starting Hermes Gateway (Docker)..."
  docker compose -f "$REPO_ROOT/docker-compose.yml" up -d
  exec docker compose -f "$REPO_ROOT/docker-compose.yml" exec hermes-agent hermes gateway "$@"
else
  echo "Error: Neither 'hermes' nor 'docker' is available. Run ./bin/bootstrap.sh first." >&2
  exit 1
fi
