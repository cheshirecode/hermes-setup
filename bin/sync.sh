#!/usr/bin/env bash
# ==============================================================================
# Sync Hermes Configurations and Skills to ~/.hermes
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

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}→ Syncing persona, guidelines, and skills to $HERMES_HOME...${NC}"
mkdir -p "$HERMES_HOME/skills"

# Sync SOUL.md and AGENTS.md
cp "$REPO_ROOT/config/SOUL.md" "$HERMES_HOME/SOUL.md"
cp "$REPO_ROOT/config/AGENTS.md" "$HERMES_HOME/AGENTS.md"

# Sync config.yaml if present in repo and missing or requested
if [[ -f "$REPO_ROOT/config/config.template.yaml" && ! -f "$HERMES_HOME/config.yaml" ]]; then
  cp "$REPO_ROOT/config/config.template.yaml" "$HERMES_HOME/config.yaml"
  chmod 0600 "$HERMES_HOME/config.yaml"
fi

# Sync skills without deleting other user skills
cp -r "$REPO_ROOT/skills/"* "$HERMES_HOME/skills/"

echo -e "${GREEN}✓ Sync completed successfully.${NC}"
