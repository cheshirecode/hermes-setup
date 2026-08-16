#!/usr/bin/env bash
# ==============================================================================
# Sync Hermes Configurations and Skills to ~/.hermes
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}→ Syncing persona, guidelines, and skills to $HERMES_HOME...${NC}"
mkdir -p "$HERMES_HOME/skills"

# Sync SOUL.md and AGENTS.md
cp "$REPO_ROOT/config/SOUL.md" "$HERMES_HOME/SOUL.md"
cp "$REPO_ROOT/config/AGENTS.md" "$HERMES_HOME/AGENTS.md"

# Sync skills without deleting other user skills
cp -r "$REPO_ROOT/skills/"* "$HERMES_HOME/skills/"

echo -e "${GREEN}✓ Sync completed successfully.${NC}"
