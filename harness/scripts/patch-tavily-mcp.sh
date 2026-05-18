#!/usr/bin/env bash
# patch-tavily-mcp.sh — Idempotently inject `globalThis.__TAVILY_MCP_AXIOS__ = axios;`
# into tavily-mcp/build/index.js so tavily-rotator.mjs can hook the same axios instance.
#
# P-152 root cause: tavily-mcp v0.1.4+ uses axios (not fetch). Our fetch monkey-patch in
# tavily-rotator.mjs never intercepted requests, so only the first API key was ever used.
# Patching the same axios module instance via globalThis is the most direct fix.
#
# Run after every `npm install -g tavily-mcp` or `npm update -g tavily-mcp`.
# Idempotent: re-running is a no-op if already patched.

set -euo pipefail

NPM_ROOT=$(npm root -g 2>/dev/null)
TARGET="$NPM_ROOT/tavily-mcp/build/index.js"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: $TARGET not found. Run: npm install -g tavily-mcp" >&2
  exit 1
fi

MARKER="globalThis.__TAVILY_MCP_AXIOS__ = axios"

if grep -qF "$MARKER" "$TARGET"; then
  echo "[patch-tavily-mcp] already patched: $TARGET"
  exit 0
fi

# Safety: confirm the anchor line exists exactly once before patching
ANCHOR='import axios from "axios";'
COUNT=$(grep -cF "$ANCHOR" "$TARGET" || true)
if [ "$COUNT" -ne 1 ]; then
  echo "ERROR: expected exactly one occurrence of '$ANCHOR', found $COUNT in $TARGET" >&2
  exit 2
fi

# Backup
BAK="$TARGET.bak-$(date +%Y%m%d-%H%M%S)"
cp "$TARGET" "$BAK"
echo "[patch-tavily-mcp] backup: $BAK"

# Inject patch right after the axios import (sed -i works on Windows Git Bash too)
sed -i 's|^import axios from "axios";$|&\n// PATCH P-152 (JamesClaw harness): expose axios instance to globalThis so tavily-rotator.mjs\n// can monkey-patch axios.create on the same module instance tavily-mcp actually uses.\n// Re-applied by harness/scripts/patch-tavily-mcp.sh after each npm install -g tavily-mcp.\nglobalThis.__TAVILY_MCP_AXIOS__ = axios;|' "$TARGET"

# Verify
if grep -qF "$MARKER" "$TARGET"; then
  echo "[patch-tavily-mcp] ✓ patched: $TARGET"
else
  echo "ERROR: patch did not apply. Restore from $BAK if needed." >&2
  exit 3
fi
