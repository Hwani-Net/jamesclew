#!/bin/bash
# error-telegram.sh — PostToolUse hook for Bash
# Auto-sends telegram alert when Bash exits with error (non-zero)
# Excludes common non-error exit codes (grep no match = 1, etc.)

INPUT=$(cat)
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_result.exit_code // 0' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Only trigger on actual errors (exit >= 2, or exit 1 with non-grep commands)
[ "$EXIT_CODE" = "0" ] && exit 0
[ -z "$EXIT_CODE" ] && exit 0

# Exclude grep/test/diff (exit 1 = no match, not error)
case "$COMMAND" in
  grep*|test*|diff*|which*|command*|type*) exit 0 ;;
esac

# Exclude if exit code is 1 and command is a check (not a build/deploy)
if [ "$EXIT_CODE" = "1" ]; then
  echo "$COMMAND" | grep -qE "node -c|--check|--dry-run|lint|test" && exit 0
fi

# Send telegram error alert
STDERR=$(echo "$INPUT" | jq -r '.tool_result.stderr // empty' 2>/dev/null | head -c 200)
SHORT_CMD=$(echo "$COMMAND" | head -c 80)
bash "$HOME/.claude/hooks/telegram-notify.sh" error "⚠️ Bash 에러 (exit $EXIT_CODE)\nCmd: $SHORT_CMD\n$STDERR" 2>/dev/null &

exit 0
