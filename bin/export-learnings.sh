#!/usr/bin/env bash
# ==============================================================================
# Hermes Learnings Exporter & Secret Sanitizer
# ==============================================================================
# Exports newly learned/improved skills and templates from ~/.hermes to the
# version-controlled git repository, with strict secret/credential scrubbing.
#
# Usage:
#   ./bin/export-learnings.sh           # Preview changes (dry-run)
#   ./bin/export-learnings.sh --apply   # Copy safe skills & stage in git
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

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -h|--help)
      echo "Usage: $0 [--apply]"
      echo "  Scans ~/.hermes/skills for newly learned/improved skills,"
      echo "  sanitizes them for secrets, and exports them to this repo."
      exit 0
      ;;
  esac
done

echo ""
echo "=== Hermes Learnings Exporter ==="
echo ""

# Secret scanning regexes
SECRET_PATTERN='(sk-[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{25,}|github_pat_[a-zA-Z0-9_]{30,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z-_]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|[0-9]{9,10}:[a-zA-Z0-9_-]{35})'

scan_file_for_secrets() {
  local file="$1"
  if grep -qE "$SECRET_PATTERN" "$file" 2>/dev/null; then
    return 1
  fi
  return 0
}

SKILLS_SRC="$HERMES_HOME/skills"
if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "No skills directory found at $SKILLS_SRC."
  exit 0
fi

COPIED_COUNT=0
REJECTED_COUNT=0

# Scan all skills in ~/.hermes/skills/
while IFS= read -r skill_dir; do
  [[ -z "$skill_dir" ]] && continue
  skill_name="$(basename "$skill_dir")"
  target_dir="$REPO_ROOT/skills/$skill_name"

  # Find all markdown / python / yaml files in this skill
  has_secret=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if ! scan_file_for_secrets "$f"; then
      echo -e "${RED}✗ REJECTED:${NC} Skill '$skill_name' contains secret-shaped strings in $(basename "$f"). Skipping."
      has_secret=1
      REJECTED_COUNT=$((REJECTED_COUNT + 1))
      break
    fi
  done < <(find "$skill_dir" -type f \( -name "*.md" -o -name "*.py" -o -name "*.json" -o -name "*.yaml" \) 2>/dev/null || true)

  if [[ $has_secret -eq 0 ]]; then
    if [[ $APPLY -eq 1 ]]; then
      mkdir -p "$target_dir"
      cp -r "$skill_dir/"* "$target_dir/"
      echo -e "${GREEN}✓ Exported:${NC} $skill_name → skills/$skill_name"
    else
      echo -e "${CYAN}→ Ready to export:${NC} $skill_name → skills/$skill_name"
    fi
    COPIED_COUNT=$((COPIED_COUNT + 1))
  fi
done < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)

# Also check if SOUL.md or AGENTS.md in ~/.hermes was improved
for cfg in "SOUL.md" "AGENTS.md"; do
  if [[ -f "$HERMES_HOME/$cfg" ]]; then
    if scan_file_for_secrets "$HERMES_HOME/$cfg"; then
      if ! cmp -s "$HERMES_HOME/$cfg" "$REPO_ROOT/config/$cfg" 2>/dev/null; then
        if [[ $APPLY -eq 1 ]]; then
          cp "$HERMES_HOME/$cfg" "$REPO_ROOT/config/$cfg"
          echo -e "${GREEN}✓ Updated:${NC} config/$cfg from $HERMES_HOME/$cfg"
        else
          echo -e "${CYAN}→ Modified:${NC} config/$cfg differs from $HERMES_HOME/$cfg"
        fi
      fi
    else
      echo -e "${RED}✗ REJECTED:${NC} $HERMES_HOME/$cfg contains secret-shaped strings. Skipping."
    fi
  fi
done

echo ""
if [[ $APPLY -eq 1 ]]; then
  echo -e "${GREEN}Learnings exported successfully ($COPIED_COUNT skills exported, $REJECTED_COUNT rejected).${NC}"
  echo "Inspect changes with: git status && git diff"
  echo "Then commit and push: git commit -am 'feat(skills): export learned improvements' && git push"
else
  echo -e "${YELLOW}Dry-run complete. Re-run with --apply to copy files into this repository.${NC}"
fi
echo ""
