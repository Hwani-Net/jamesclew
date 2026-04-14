#!/bin/bash
# user-prompt-declare-warn.sh — UserPromptSubmit hook
# Warns if previous turn had declare-without-execute pattern
# Works with stop-dispatcher.sh check_declare_execute_ratio (2-file package)

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
FLAG_FILE="$STATE_DIR/declare_no_exec_flag"

# No flag = no previous declaration issue
[ ! -f "$FLAG_FILE" ] && exit 0

# Check flag age (expire after 5 minutes)
if command -v python3 &>/dev/null; then
  FLAG_AGE=$(python3 -c "import os,time; print(int(time.time()-os.path.getmtime('$FLAG_FILE')))" 2>/dev/null || echo 999)
else
  FLAG_AGE=0
fi

if [ "$FLAG_AGE" -gt 300 ]; then
  rm -f "$FLAG_FILE"
  exit 0
fi

REASON=$(cat "$FLAG_FILE" 2>/dev/null || echo "선언 후 미실행")
rm -f "$FLAG_FILE"

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":\"[DECLARE-RECUR] 직전 턴: $REASON. 이번 턴에는 선언 없이 즉시 도구 호출로 시작하세요.\"}}"
exit 0
