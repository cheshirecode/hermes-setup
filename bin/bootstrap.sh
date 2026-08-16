#!/usr/bin/env bash
# ==============================================================================
# Hermes Agent Universal Bootstrap Script
# ==============================================================================
# Sets up Hermes Agent on any machine (WSL, Linux, macOS, or Cloud Instance).
#
# Usage:
#   ./bin/bootstrap.sh          # Native install via uv
#   ./bin/bootstrap.sh --docker # Containerized setup via Docker Compose
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
HERMES_HOME="${HERMES_HOME/#\~/$HOME}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()    { printf "${CYAN}→ %s${NC}\n" "$1"; }
log_success() { printf "${GREEN}✓ %s${NC}\n" "$1"; }
log_warn()    { printf "${YELLOW}⚠ %s${NC}\n" "$1"; }
log_error()   { printf "${RED}✗ %s${NC}\n" "$1" >&2; }

MODE="native"
for arg in "$@"; do
  case "$arg" in
    --docker) MODE="docker" ;;
    -h|--help)
      echo "Usage: $0 [--docker]"
      exit 0
      ;;
  esac
done

echo ""
echo "=========================================================="
echo "          ⚕ Hermes Agent Universal Bootstrap              "
echo "=========================================================="
echo ""

# 1. Ensure local .env exists
if [[ ! -f "$REPO_ROOT/.env" ]]; then
  log_info "Creating .env from .env.example..."
  cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
  chmod 0600 "$REPO_ROOT/.env"

  # Auto-probe keys from environment / shell_common
  DOTFILES_QUIET=1 source "$HOME/.shell_common" >/dev/null 2>&1 || true

  OPENROUTER_KEY="${OPEN_ROUTER_API_KEY_HERMES:-${OPENROUTER_API_KEY:-}}"
  HERMES_KEY="${HERMES_API_KEY_FREE:-${NOUS_API_KEY:-${HERMES_API_KEY:-}}}"

  # Fallback: probe OpenCode auth.json for OpenRouter key if not in env
  if [[ -z "$OPENROUTER_KEY" && -s "$HOME/.local/share/opencode/auth.json" ]]; then
    OPENROUTER_KEY=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
        k = d.get("openrouter", {}).get("key")
        if k:
            print(k)
except Exception:
    pass
' "$HOME/.local/share/opencode/auth.json" 2>/dev/null || true)
  fi

  if [[ -n "$OPENROUTER_KEY" ]]; then
    log_info "Detected OpenRouter credentials. Adding to .env..."
    sed -i.bak "s|^OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=$OPENROUTER_KEY|" "$REPO_ROOT/.env" 2>/dev/null || \
      sed -i "" "s|^OPENROUTER_API_KEY=.*|OPENROUTER_API_KEY=$OPENROUTER_KEY|" "$REPO_ROOT/.env" 2>/dev/null || true
    rm -f "$REPO_ROOT/.env.bak"
  fi

  if [[ -n "$HERMES_KEY" ]]; then
    log_info "Detected Hermes/Nous Portal credentials. Adding to .env..."
    sed -i.bak "s|^NOUS_API_KEY=.*|NOUS_API_KEY=$HERMES_KEY|" "$REPO_ROOT/.env" 2>/dev/null || \
      sed -i "" "s|^NOUS_API_KEY=.*|NOUS_API_KEY=$HERMES_KEY|" "$REPO_ROOT/.env" 2>/dev/null || true
    echo "HERMES_API_KEY=$HERMES_KEY" >> "$REPO_ROOT/.env"
    rm -f "$REPO_ROOT/.env.bak"
  fi

  log_success "Created .env (permissions: 0600)"
else
  log_info "Existing .env found."
fi

# Load .env variables into current environment
# shellcheck disable=SC1091
if [[ -f "$REPO_ROOT/.env" ]]; then
  export $(grep -v '^#' "$REPO_ROOT/.env" | xargs -r 2>/dev/null) || true
  HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
  HERMES_HOME="${HERMES_HOME/#\~/$HOME}"
fi

# 2. Setup Mode
if [[ "$MODE" == "docker" ]]; then
  log_info "Setting up Hermes Agent in Docker mode..."
  if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker is not installed or not in PATH."
    exit 1
  fi
  mkdir -p "$REPO_ROOT/workspace"
  docker compose -f "$REPO_ROOT/docker-compose.yml" build
  log_success "Docker image built successfully."
  echo ""
  echo "Start Hermes Agent with:"
  echo "  docker compose up -d"
  echo "  docker compose exec hermes-agent hermes"
  exit 0
fi

# Native Mode Setup
log_info "Setting up Hermes Agent in Native mode..."

# Ensure Astral uv is installed
if ! command -v uv >/dev/null 2>&1; then
  log_info "Installing Astral uv..."
  curl -fsSL https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh 2>/dev/null || \
    curl -fsSL https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi
log_success "Astral uv ready: $(uv --version)"

# Install hermes-agent CLI via managed virtualenv
log_info "Installing / updating Hermes Agent using uv..."
mkdir -p "$HERMES_HOME" "$HOME/.local/bin"
uv venv "$HERMES_HOME/venv" --python python3.11 2>/dev/null || uv venv "$HERMES_HOME/venv" --python python3
uv pip install --python "$HERMES_HOME/venv" --quiet hermes-agent
ln -sf "$HERMES_HOME/venv/bin/hermes" "$HOME/.local/bin/hermes"
export PATH="$HOME/.local/bin:$HERMES_HOME/venv/bin:$PATH"
log_success "Hermes CLI ready: $("$HERMES_HOME/venv/bin/hermes" --version | head -1)"

# Ensure ~/.hermes directory exists and sync repo config
log_info "Syncing configurations, personas, and custom skills to $HERMES_HOME..."
mkdir -p "$HERMES_HOME/skills"

# Copy SOUL.md and AGENTS.md
cp "$REPO_ROOT/config/SOUL.md" "$HERMES_HOME/SOUL.md"
cp "$REPO_ROOT/config/AGENTS.md" "$HERMES_HOME/AGENTS.md"

# Copy custom skills
cp -r "$REPO_ROOT/skills/"* "$HERMES_HOME/skills/"

# Sync config.yaml (seeding keys if needed)
if [[ -f "$REPO_ROOT/config/config.template.yaml" ]]; then
  HERMES_KEY="${HERMES_API_KEY_FREE:-${NOUS_API_KEY:-${HERMES_API_KEY:-}}}"
  if [[ -n "$HERMES_KEY" ]]; then
    python3 -c '
import yaml, os, sys

template_path = sys.argv[1]
output_path = sys.argv[2]
hermes_key = sys.argv[3]

with open(template_path) as f:
    cfg = yaml.safe_load(f)

for cp in cfg.get("custom_providers", []):
    if cp.get("name") == "hermes_portal":
        cp["api_key"] = hermes_key

with open(output_path, "w") as f:
    yaml.dump(cfg, f, default_flow_style=False)
' "$REPO_ROOT/config/config.template.yaml" "$HERMES_HOME/config.yaml" "$HERMES_KEY"
  else
    cp "$REPO_ROOT/config/config.template.yaml" "$HERMES_HOME/config.yaml"
  fi
  chmod 0600 "$HERMES_HOME/config.yaml"
fi

# Write ~/.hermes/.env
if [[ -f "$REPO_ROOT/.env" ]]; then
  cp "$REPO_ROOT/.env" "$HERMES_HOME/.env"
  chmod 0600 "$HERMES_HOME/.env"
fi

log_success "Hermes Agent configuration and skills synced."
echo ""
echo "=========================================================="
echo "          Hermes Agent is ready to use!                   "
echo "=========================================================="
echo "Run doctor diagnostics:"
echo "  ./bin/doctor.sh"
echo ""
echo "Start chatting:"
echo "  ./bin/run.sh      # or simply 'hermes'"
echo ""
