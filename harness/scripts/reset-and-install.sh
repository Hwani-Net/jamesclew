#!/bin/bash
# JamesClaw Agent — Reset & Install Script
# Usage: bash harness/scripts/reset-and-install.sh
#
# This script:
# 1. Backs up existing Claude Code config
# 2. Removes old config (CLAUDE.md, settings, hooks, rules, agents, MCP servers)
# 3. Deploys JamesClaw harness
# 4. Registers MCP servers
# 5. Verifies installation

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/harness"
TARGET="$HOME/.claude"
BACKUP_DIR="$TARGET/backups/pre-jamesclaw-$(date +%Y%m%d-%H%M)"

echo "================================================"
echo "  JamesClaw Agent — Reset & Install"
echo "================================================"
echo ""

# --- Phase 1: Backup ---
echo "[1/5] Backing up existing config..."
mkdir -p "$BACKUP_DIR"
cp "$TARGET/CLAUDE.md" "$BACKUP_DIR/" 2>/dev/null && echo "  Backed up CLAUDE.md" || true
cp "$TARGET/settings.json" "$BACKUP_DIR/" 2>/dev/null && echo "  Backed up settings.json" || true
cp -r "$TARGET/rules/" "$BACKUP_DIR/rules/" 2>/dev/null && echo "  Backed up rules/" || true
cp -r "$TARGET/hooks/" "$BACKUP_DIR/hooks/" 2>/dev/null && echo "  Backed up hooks/" || true
cp -r "$TARGET/agents/" "$BACKUP_DIR/agents/" 2>/dev/null && echo "  Backed up agents/" || true
echo "  Backup saved to: $BACKUP_DIR"
echo ""

# --- Phase 2: Remove old config ---
echo "[2/5] Removing old config..."
rm -f "$TARGET/CLAUDE.md" "$TARGET/settings.json"
rm -rf "$TARGET/rules/" "$TARGET/hooks/" "$TARGET/agents/" "$TARGET/scripts/"
echo "  Old config removed."

# Remove old MCP servers (non-interactive)
if command -v claude &>/dev/null; then
  echo "  Removing old MCP servers..."
  claude mcp list 2>/dev/null | grep -oP '^\S+' | while read -r name; do
    [[ "$name" == "plugin:"* ]] && continue  # skip plugins
    claude mcp remove "$name" 2>/dev/null && echo "    Removed: $name" || true
  done
fi
echo ""

# --- Phase 3: Deploy harness ---
echo "[3/5] Deploying JamesClaw harness..."
bash "$HARNESS_DIR/deploy.sh"
echo ""

# --- Phase 4: Register MCP servers ---
echo "[4/5] Registering MCP servers..."

# Perplexity
if command -v claude &>/dev/null; then
  PERPLEXITY_PATH=$(npm root -g 2>/dev/null)/@perplexity-ai/mcp-server/dist/index.js
  if [ -f "$PERPLEXITY_PATH" ]; then
    claude mcp add perplexity -s user -- node "$PERPLEXITY_PATH" 2>/dev/null && echo "  Registered: perplexity" || echo "  Skip: perplexity (already registered or error)"
  else
    echo "  Skip: perplexity (not installed, run: npm install -g @perplexity-ai/mcp-server)"
  fi

  # Tavily
  if [ -f "$TARGET/tavily-rotator.mjs" ]; then
    claude mcp add tavily -s user -- node "$TARGET/tavily-rotator.mjs" 2>/dev/null && echo "  Registered: tavily" || echo "  Skip: tavily (already registered or error)"
  fi
fi
echo ""

# --- Phase 5: Verify ---
echo "[5/5] Verifying installation..."
ERRORS=0

[ -f "$TARGET/CLAUDE.md" ] && echo "  CLAUDE.md .................. OK" || { echo "  CLAUDE.md .................. MISSING"; ERRORS=$((ERRORS+1)); }
[ -f "$TARGET/settings.json" ] && echo "  settings.json .............. OK" || { echo "  settings.json .............. MISSING"; ERRORS=$((ERRORS+1)); }
[ -d "$TARGET/rules" ] && echo "  rules/ ..................... OK ($(ls "$TARGET/rules/" | wc -l) files)" || { echo "  rules/ ..................... MISSING"; ERRORS=$((ERRORS+1)); }
[ -d "$TARGET/hooks" ] && echo "  hooks/ ..................... OK ($(ls "$TARGET/hooks/" | wc -l) files)" || { echo "  hooks/ ..................... MISSING"; ERRORS=$((ERRORS+1)); }
[ -d "$TARGET/agents" ] && echo "  agents/ .................... OK ($(ls "$TARGET/agents/" | wc -l) files)" || { echo "  agents/ .................... MISSING"; ERRORS=$((ERRORS+1)); }
[ -d "$TARGET/scripts" ] && echo "  scripts/ ................... OK" || { echo "  scripts/ ................... MISSING"; ERRORS=$((ERRORS+1)); }

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "================================================"
  echo "  Installation complete! No errors."
  echo "================================================"
  echo ""
  echo "Next steps:"
  echo "  1. Set API keys (see SETUP.md Step 4)"
  echo "  2. Run: firebase login && gcloud auth login"
  echo "  3. Install plugins: claude plugin install telegram@claude-plugins-official"
  echo "  4. Reload Claude Code window"
else
  echo "================================================"
  echo "  Installation completed with $ERRORS error(s)."
  echo "  Re-run: bash harness/deploy.sh"
  echo "================================================"
fi
