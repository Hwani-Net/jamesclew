#!/bin/bash
# bootstrap-gbrain.sh — gbrain knowledge base initializer (idempotent)
# Usage:
#   bash bootstrap-gbrain.sh
#   HARNESS_SRC=/path/to/jamesclew bash bootstrap-gbrain.sh
#
# Requires: gbrain CLI (bun install -g gbrain)

set -euo pipefail

# ─── Resolve harness source dir ───
HARNESS_SRC="${HARNESS_SRC:-}"

if [[ -z "$HARNESS_SRC" ]]; then
  # Derive from script location: scripts/ -> harness/ -> repo root
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  HARNESS_SRC="$(dirname "$SCRIPT_DIR")"
fi

PITFALLS_DIR="$HARNESS_SRC/pitfalls"
RULES_DIR="$HARNESS_SRC/rules"

echo "══════════════════════════════════════════"
echo "  gbrain Knowledge Base Bootstrap"
echo "  Harness source: $HARNESS_SRC"
echo "══════════════════════════════════════════"
echo ""

# ─── 1. Check gbrain CLI ───
if ! command -v gbrain >/dev/null 2>&1; then
  echo "ERROR: gbrain CLI not found." >&2
  echo "" >&2
  echo "  Install with:" >&2
  echo "    bun install -g gbrain" >&2
  echo "  (requires Bun: https://bun.sh)" >&2
  echo "" >&2
  echo "  Skipping gbrain setup. Re-run this script after installing." >&2
  exit 1
fi

GBRAIN_VERSION="$(gbrain --version 2>/dev/null || echo 'unknown')"
echo "  gbrain: $GBRAIN_VERSION"
echo ""

# ─── 2. Init gbrain (idempotent) ───
echo "── Step 1: Init ────────────────────────────"
GBRAIN_STATE_DIR="$HOME/.gbrain"
GBRAIN_DB="$GBRAIN_STATE_DIR/pglite"

if [[ -d "$GBRAIN_DB" ]] || [[ -f "$GBRAIN_STATE_DIR/config.json" ]]; then
  echo "  [skip] gbrain already initialized ($GBRAIN_STATE_DIR exists)"
else
  echo "  Running: gbrain init --pglite"
  if gbrain init --pglite 2>&1; then
    echo "  [ok] gbrain initialized (PGLite local mode)"
  else
    echo "  [warn] gbrain init returned non-zero. May already be initialized." >&2
    echo "  Continuing..." >&2
  fi
fi
echo ""

# ─── 3. Import pitfalls (sequential to avoid PGLite lock) ───
echo "── Step 2: Import pitfalls ─────────────────"
if [[ -d "$PITFALLS_DIR" ]]; then
  PITFALL_COUNT="$(ls -1 "$PITFALLS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$PITFALL_COUNT" -gt 0 ]]; then
    echo "  Found $PITFALL_COUNT pitfall files. Importing..."
    if gbrain import "$PITFALLS_DIR" 2>&1; then
      echo "  [ok] Pitfalls imported"
    else
      echo "  [warn] gbrain import returned non-zero for pitfalls" >&2
    fi
  else
    echo "  [skip] No .md files in $PITFALLS_DIR"
  fi
else
  echo "  [skip] $PITFALLS_DIR not found"
fi
echo ""

# ─── 4. Import rules ───
echo "── Step 3: Import rules ────────────────────"
if [[ -d "$RULES_DIR" ]]; then
  RULES_COUNT="$(ls -1 "$RULES_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$RULES_COUNT" -gt 0 ]]; then
    echo "  Found $RULES_COUNT rule files. Importing..."
    if gbrain import "$RULES_DIR" 2>&1; then
      echo "  [ok] Rules imported"
    else
      echo "  [warn] gbrain import returned non-zero for rules" >&2
    fi
  else
    echo "  [skip] No .md files in $RULES_DIR"
  fi
else
  echo "  [skip] $RULES_DIR not found"
fi
echo ""

# ─── 5. Verify with stats ───
echo "── Step 4: Verify ──────────────────────────"
if gbrain stats 2>&1; then
  echo ""
  echo "  [ok] gbrain stats returned successfully"
else
  echo "  [warn] gbrain stats failed — check gbrain server with: gbrain serve" >&2
fi

echo ""
echo "══════════════════════════════════════════"
echo "  gbrain bootstrap complete."
echo "  Next: gbrain serve (if using MCP mode)"
echo "  Query: gbrain query \"keyword\""
echo "══════════════════════════════════════════"
