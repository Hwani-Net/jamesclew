#!/bin/bash
# periodic-audit.sh — PostToolUse
# Runs audit-session.sh --full every N tool calls within a session.
# Complements PreCompact audit (1x/session) with mid-session checks.
# Replaces context-percentage milestones (too noisy on Opus 4.7 1M + opusplan).

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

INTERVAL=100
SESSION_ID=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
[ -z "$SESSION_ID" ] && exit 0

COUNTER_FILE="$STATE_DIR/audit_counter_${SESSION_ID}"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Trigger only on INTERVAL multiples (100, 200, 300, ...)
if [ $((COUNT % INTERVAL)) -ne 0 ]; then
  exit 0
fi

AUDIT_OUTPUT=$(bash "$HOME/.claude/scripts/audit-session.sh" --full 2>&1 | grep -E "Score:|❌|⚠️" | head -12)
[ -z "$AUDIT_OUTPUT" ] && exit 0

# Extract score line + count FAILs
SCORE_LINE=$(echo "$AUDIT_OUTPUT" | grep "Score:" | head -1)
FAIL_COUNT=$(echo "$AUDIT_OUTPUT" | grep -c "❌")

# Single-line summary for systemMessage (keep short to avoid context bloat)
if [ "$FAIL_COUNT" -gt 0 ]; then
  SUMMARY="[🔍 PERIODIC-AUDIT @${COUNT}회] ${SCORE_LINE} — FAIL ${FAIL_COUNT}건 감지. /audit 실행하여 상세 확인 후 수정."
else
  SUMMARY="[🔍 PERIODIC-AUDIT @${COUNT}회] ${SCORE_LINE} — FAIL 없음. 계속 진행."
fi

# Log to audit history
echo "$(date '+%Y-%m-%dT%H:%M:%S')|${SESSION_ID}|${COUNT}|${FAIL_COUNT}" >> "$STATE_DIR/periodic_audit_history.log"

# Inject as systemMessage (non-blocking)
printf '{"systemMessage":"%s","continue":true}\n' "$SUMMARY"
exit 0
