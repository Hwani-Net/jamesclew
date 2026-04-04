#!/bin/bash
# Irreversible Action Alert — PreToolUse hook for Bash
# Detects hard-to-reverse commands and sends telegram notification BEFORE execution
# Does NOT block — just logs and alerts for auditability
#
# Usage: bash irreversible-alert.sh
# Input: stdin JSON from PreToolUse hook

INPUT=$(cat)
STATE_DIR="$HOME/.claude/hooks/state"
mkdir -p "$STATE_DIR"

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

ALERT=""
SEVERITY=""

# Detect irreversible commands
case "$CMD" in
  *"git push --force"*|*"git push -f"*)
    ALERT="git force push"
    SEVERITY="critical"
    ;;
  *"git push"*)
    # Normal push — log only, no telegram
    ALERT="git push"
    SEVERITY="medium"
    ;;
  *"npm publish"*|*"npx publish"*)
    ALERT="npm publish"
    SEVERITY="critical"
    ;;
  *"firebase deploy"*)
    # Already handled by verify-deploy.sh, just log
    ALERT="firebase deploy"
    SEVERITY="medium"
    ;;
  *"rm -rf"*|*"rm -r"*)
    # Check if it's a dangerous path
    case "$CMD" in
      *"node_modules"*|*"dist/"*|*".cache"*|*"__pycache__"*)
        # Safe cleanup targets — no alert
        exit 0
        ;;
      *)
        ALERT="rm -rf"
        SEVERITY="high"
        ;;
    esac
    ;;
  *"DROP TABLE"*|*"DROP DATABASE"*|*"TRUNCATE"*)
    ALERT="destructive SQL"
    SEVERITY="critical"
    ;;
esac

[ -z "$ALERT" ] && exit 0

# Log the action
echo "[$(date +%H:%M:%S)] IRREVERSIBLE: ${ALERT} — ${CMD}" >> "$STATE_DIR/irreversible.log"

# Debounce: same alert within 60 seconds
HASH=$(echo "$ALERT" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$ALERT" | cksum | cut -d' ' -f1)
ALERT_FILE="$STATE_DIR/irrev_alert_${HASH}"
NOW=$(date +%s)

if [ -f "$ALERT_FILE" ]; then
  LAST=$(cat "$ALERT_FILE" 2>/dev/null || echo 0)
  ELAPSED=$((NOW - LAST))
  if [ "$ELAPSED" -lt 60 ] 2>/dev/null; then
    exit 0
  fi
fi
echo "$NOW" > "$ALERT_FILE"

# Send telegram notification (non-blocking, does not wait for approval)
case "$SEVERITY" in
  critical)
    bash "$HOME/.claude/hooks/telegram-notify.sh" "" "🚨 비가역 작업 실행: ${ALERT}
${CMD}"
    ;;
  high)
    bash "$HOME/.claude/hooks/telegram-notify.sh" "" "⚠️ 비가역 작업: ${ALERT}
${CMD}"
    ;;
  medium)
    # medium은 로그만, 텔레그램 미전송
    ;;
esac

# Only inject context for high/critical, not medium
if [ "$SEVERITY" != "medium" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"📝 비가역 작업 감지됨: ${ALERT}. 텔레그램 알림 발송 완료. 진행합니다.\"}}"
fi
exit 0
