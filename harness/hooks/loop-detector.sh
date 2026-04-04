#!/bin/bash
# Loop Detector — PostToolUse hook
# Detects repetitive tool calls (same tool + same key params 3+ times)
# On detection: sends telegram alert + injects warning to agent
#
# Usage: bash loop-detector.sh
# Input: stdin JSON from PostToolUse hook

INPUT=$(cat)
STATE_DIR="$HOME/.claude/hooks/state"
mkdir -p "$STATE_DIR"
CALL_LOG="$STATE_DIR/tool_call_log"

# Extract tool name and key params
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ -z "$TOOL" ] && exit 0

# Build a fingerprint: tool + full command for Bash, first 200 chars for others
if [ "$TOOL" = "Bash" ]; then
  TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
  # Skip known repeatable commands
  case "$TOOL_INPUT" in
    *"deploy.sh"*|*"git status"*|*"git add"*|*"git diff"*|*"claude mcp list"*) exit 0 ;;
  esac
else
  TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {} | tostring' 2>/dev/null | head -c 200)
fi
FINGERPRINT="${TOOL}:${TOOL_INPUT}"
HASH=$(echo "$FINGERPRINT" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$FINGERPRINT" | cksum | cut -d' ' -f1)

# Append to log with timestamp
NOW=$(date +%s)
echo "${NOW}|${HASH}|${TOOL}" >> "$CALL_LOG"

# Clean old entries (older than 5 minutes)
if [ -f "$CALL_LOG" ]; then
  CUTOFF=$((NOW - 300))
  awk -F'|' -v cutoff="$CUTOFF" '$1 >= cutoff' "$CALL_LOG" > "${CALL_LOG}.tmp" 2>/dev/null
  mv "${CALL_LOG}.tmp" "$CALL_LOG" 2>/dev/null
fi

# Count occurrences of this hash in last 5 minutes
COUNT=$(grep -c "|${HASH}|" "$CALL_LOG" 2>/dev/null || echo 0)

if [ "$COUNT" -ge 3 ] 2>/dev/null; then
  # Check debounce (don't alert for same hash within 2 minutes)
  ALERT_FILE="$STATE_DIR/loop_alert_${HASH}"
  if [ -f "$ALERT_FILE" ]; then
    LAST_ALERT=$(cat "$ALERT_FILE" 2>/dev/null || echo 0)
    ELAPSED=$((NOW - LAST_ALERT))
    if [ "$ELAPSED" -lt 120 ] 2>/dev/null; then
      exit 0
    fi
  fi
  echo "$NOW" > "$ALERT_FILE"

  # Send telegram alert
  bash "$HOME/.claude/hooks/telegram-notify.sh" error "🔄 반복 호출 감지: ${TOOL} x${COUNT} (5분내)"

  # Inject warning to agent
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"⚠️ LOOP DETECTED: ${TOOL}을 동일 파라미터로 ${COUNT}회 반복 호출 중. 접근 방식을 변경하세요.\"}}"
fi

exit 0
