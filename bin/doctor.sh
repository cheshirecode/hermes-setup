#!/usr/bin/env bash
# ==============================================================================
# Hermes Agent Doctor Diagnostics
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

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

say_ok()   { printf "  ${GREEN}OK  ${NC} %s\n" "$1"; }
say_warn() { printf "  ${YELLOW}WARN${NC} %s\n" "$1"; }
say_fail() { printf "  ${RED}FAIL${NC} %s\n" "$1"; }

echo ""
echo "=== Hermes Setup Doctor Diagnostics ==="
echo ""

# 1. System toolchains
echo "System Tools:"
command -v git >/dev/null && say_ok "git ($(git --version | head -1))" || say_fail "git not installed"
command -v curl >/dev/null && say_ok "curl ($(curl --version | head -1 | cut -d' ' -f1-2))" || say_fail "curl not installed"
command -v python3 >/dev/null && say_ok "python3 ($(python3 --version))" || say_fail "python3 not installed"
command -v uv >/dev/null && say_ok "uv ($(uv --version))" || say_warn "uv not installed (run ./bin/bootstrap.sh)"
command -v docker >/dev/null && say_ok "docker ($(docker --version))" || say_warn "docker not installed (needed for container mode)"

# 2. Hermes CLI check
echo ""
echo "Hermes Installation:"
if command -v hermes >/dev/null 2>&1; then
  say_ok "hermes CLI found at $(which hermes)"
else
  say_warn "hermes CLI not found in PATH (run ./bin/bootstrap.sh or use Docker)"
fi

if [[ -d "$HERMES_HOME" ]]; then
  say_ok "Hermes data directory exists at $HERMES_HOME"
  [[ -f "$HERMES_HOME/SOUL.md" ]] && say_ok "SOUL.md persona present" || say_warn "SOUL.md missing in $HERMES_HOME (run ./bin/sync.sh)"
  [[ -f "$HERMES_HOME/config.yaml" || -f "$HERMES_HOME/config.json" ]] && say_ok "Hermes configuration present ($( [ -f "$HERMES_HOME/config.yaml" ] && echo "config.yaml" || echo "config.json" ))" || say_warn "configuration missing in $HERMES_HOME"
  [[ -d "$HERMES_HOME/skills" ]] && say_ok "Custom skills directory present ($(ls -1 "$HERMES_HOME/skills" 2>/dev/null | wc -l | tr -d ' ') skills)" || say_warn "skills directory missing in $HERMES_HOME"
else
  say_warn "$HERMES_HOME directory not yet created (run ./bin/bootstrap.sh)"
fi

# 3. Environment & Credentials check (values masked)
echo ""
echo "Credentials & Providers:"
if [[ -f "$REPO_ROOT/.env" || -f "$HERMES_HOME/.env" ]]; then
  ACTIVE_ENV="$([ -f "$REPO_ROOT/.env" ] && echo "$REPO_ROOT/.env" || echo "$HERMES_HOME/.env")"
  say_ok "Active .env file found at $ACTIVE_ENV (mode: $(stat -c '%a' "$ACTIVE_ENV" 2>/dev/null || echo '0600'))"
  # Check if OpenRouter or other keys are populated
  if grep -qE '^OPENROUTER_API_KEY=[a-zA-Z0-9_-]+' "$ACTIVE_ENV"; then
    say_ok "OPENROUTER_API_KEY is configured (OpenRouter Free / Paid)"
  fi
  if grep -qE '^(NOUS_API_KEY|HERMES_API_KEY)=[a-zA-Z0-9_-]+' "$ACTIVE_ENV"; then
    say_ok "NOUS_API_KEY / HERMES_API_KEY is configured (Nous Portal Free / Paid)"
  fi
  if grep -qE '^OPENAI_API_KEY=[a-zA-Z0-9_-]+' "$ACTIVE_ENV"; then
    say_ok "OPENAI_API_KEY is configured"
  fi
  if grep -qE '^ANTHROPIC_API_KEY=[a-zA-Z0-9_-]+' "$ACTIVE_ENV"; then
    say_ok "ANTHROPIC_API_KEY is configured"
  fi
else
  say_warn ".env file missing (copy .env.example to .env and add API keys)"
fi

echo ""
echo "Doctor check complete."
echo ""
