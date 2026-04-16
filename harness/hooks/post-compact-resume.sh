#!/bin/bash
# post-compact-resume.sh — PostCompact hook
# Reads pending_tasks.md saved by PreCompact and injects via systemMessage
# so that compact-ed sessions auto-resume pending work without user prompt.

STATE_DIR="$HOME/.harness-state"
PENDING_FILE="$STATE_DIR/pending_tasks.md"

[ ! -f "$PENDING_FILE" ] && exit 0

if [ ! -s "$PENDING_FILE" ]; then
  rm -f "$PENDING_FILE"
  exit 0
fi

NOW=$(date +%s)
MTIME=$(stat -c %Y "$PENDING_FILE" 2>/dev/null || python3 -c "import os; print(int(os.path.getmtime('$PENDING_FILE')))" 2>/dev/null || echo "$NOW")
AGE=$((NOW - MTIME))

if [ "$AGE" -gt 7200 ]; then
  rm -f "$PENDING_FILE"
  exit 0
fi

PENDING_TRUNC=$(head -c 3000 "$PENDING_FILE")

jq -n --arg msg "[POST-COMPACT RESUME] 이전 세션 대기 작업 — 자율 진행:\n\n$PENDING_TRUNC" \
  '{"systemMessage": $msg}' 2>/dev/null || \
  python3 -c "
import sys, json
msg = '[POST-COMPACT RESUME] 이전 세션 대기 작업 — 자율 진행:\n\n' + open('$PENDING_FILE', encoding='utf-8').read(3000)
print(json.dumps({'systemMessage': msg}))
" 2>/dev/null

mv "$PENDING_FILE" "$PENDING_FILE.consumed"

exit 0
