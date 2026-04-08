#!/bin/bash
# JamesClaw Agent — One-command installer for new machines
# Usage: bash install.sh

set -e

echo "🤖 JamesClaw Agent Installer"
echo "════════════════════════════════"

# ─── 1. Detect environment ───
PLATFORM="$(uname -s)"
case "$PLATFORM" in
  Linux*)   OS=linux ;;
  Darwin*)  OS=mac ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  *)        OS=unknown ;;
esac
echo "📍 Platform: $OS"

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
HARNESS_SRC="$(cd "$(dirname "$0")" && pwd)"
echo "📂 Harness source: $HARNESS_SRC"
echo "📂 Claude home: $CLAUDE_HOME"

# ─── 2. Prerequisites check ───
echo ""
echo "🔍 Checking prerequisites..."
MISSING=()
command -v node >/dev/null || MISSING+=("node")
command -v git >/dev/null || MISSING+=("git")
command -v claude >/dev/null || MISSING+=("claude (Claude Code CLI)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "❌ Missing: ${MISSING[*]}"
  echo "Install them first, then re-run this script."
  exit 1
fi
echo "✅ node, git, claude found"

# ─── 3. Environment file ───
ENV_FILE="$HOME/.harness.env"
if [ ! -f "$ENV_FILE" ]; then
  cp "$HARNESS_SRC/.env.example" "$ENV_FILE"
  echo ""
  echo "📝 Created $ENV_FILE — EDIT IT to fill in your API keys"
  echo "   Required: PERPLEXITY_API_KEY, TAVILY_API_KEY, OBSIDIAN_VAULT"
  echo "   Optional: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID"
else
  echo "✅ $ENV_FILE already exists"
fi

# ─── 4. State directory ───
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"
echo "✅ State directory: $STATE_DIR"

# ─── 5. Deploy harness to ~/.claude ───
echo ""
echo "🚀 Deploying harness to $CLAUDE_HOME..."
mkdir -p "$CLAUDE_HOME/hooks" "$CLAUDE_HOME/rules" "$CLAUDE_HOME/scripts" "$CLAUDE_HOME/agents" "$CLAUDE_HOME/commands"

cp "$HARNESS_SRC/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
cp "$HARNESS_SRC/settings.json" "$CLAUDE_HOME/settings.json"
cp -r "$HARNESS_SRC/rules/." "$CLAUDE_HOME/rules/"
cp -r "$HARNESS_SRC/hooks/." "$CLAUDE_HOME/hooks/"
cp -r "$HARNESS_SRC/scripts/." "$CLAUDE_HOME/scripts/"
[ -d "$HARNESS_SRC/agents" ] && cp -r "$HARNESS_SRC/agents/." "$CLAUDE_HOME/agents/"
[ -d "$HARNESS_SRC/commands" ] && cp -r "$HARNESS_SRC/commands/." "$CLAUDE_HOME/commands/"
[ -f "$HARNESS_SRC/PITFALLS.md" ] && cp "$HARNESS_SRC/PITFALLS.md" "$CLAUDE_HOME/PITFALLS.md"

chmod +x "$CLAUDE_HOME/hooks/"*.sh 2>/dev/null || true
chmod +x "$CLAUDE_HOME/scripts/"*.sh 2>/dev/null || true

echo "✅ Harness deployed"

# ─── 6. MCP servers (optional) ───
echo ""
echo "🧩 Recommended MCP servers (install manually as needed):"
echo "   claude mcp add perplexity -s user -- npx -y server-perplexity-ask"
echo "   claude mcp add tavily -s user -- node $CLAUDE_HOME/scripts/tavily-rotator.mjs"
echo "   claude mcp add stitch -s user -- npx -y @_davideast/stitch-mcp proxy"

# ─── 7. Final instructions ───
echo ""
echo "════════════════════════════════"
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit $ENV_FILE — fill in API keys"
echo "  2. Add to your shell rc (~/.bashrc, ~/.zshrc, or ~/.bash_profile):"
echo "       set -a; source $ENV_FILE; set +a"
echo "  3. Restart shell, then run: claude"
echo "  4. Verify: claude /audit (should show audit results)"
echo ""
echo "Documentation: $HARNESS_SRC/README.md"
