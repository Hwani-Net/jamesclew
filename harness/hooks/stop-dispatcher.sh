#!/bin/bash
# stop-dispatcher.sh — Single Stop hook dispatcher
# Replaces 5 separate Stop hooks with 1 sequential dispatcher.
# Reduces hook chain latency and prevents deadlock cascades.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"

# 1. enforce-execution (block capable)
RESULT=$(echo "$INPUT" | bash "$HOME/.claude/hooks/enforce-execution.sh" 2>&1)
if echo "$RESULT" | grep -q '"decision":"block"'; then
  echo "$RESULT"
  exit 0
fi

# 2. evidence-first (block capable)
RESULT=$(echo "$INPUT" | bash "$HOME/.claude/hooks/evidence-first.sh" 2>&1)
if echo "$RESULT" | grep -q '"decision":"block"'; then
  echo "$RESULT"
  exit 0
fi

# 3. self-evolve (non-blocking, background-safe)
bash "$HOME/.claude/scripts/self-evolve.sh" --apply >/dev/null 2>&1 &

# 4. curation (non-blocking, skip if MEMORY_CURATOR_ACTIVE)
if [ "$MEMORY_CURATOR_ACTIVE" != "1" ]; then
  node --experimental-strip-types "$HOME/.claude/hooks/curation.ts" <<< "$INPUT" >/dev/null 2>&1 &
fi

# 5. telegram stop (non-blocking)
RESULT_FILE="$STATE_DIR/last_result.txt"
if [ -f "$RESULT_FILE" ]; then
  RESULT_CONTENT=$(cat "$RESULT_FILE")
  rm -f "$RESULT_FILE"
  if [ -n "$RESULT_CONTENT" ]; then
    bash "$HOME/.claude/hooks/telegram-notify.sh" done "$RESULT_CONTENT" >/dev/null 2>&1 &
  fi
fi

# Wait for background jobs (max 5s)
wait -n 2>/dev/null
exit 0
