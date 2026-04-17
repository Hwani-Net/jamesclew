#!/bin/bash
# read-once.sh — PostToolUse hook for Read
# Warns when the same file is read more than once in a session.
# Does NOT block — warning only via additionalContext.
# Token savings: prevents redundant context inflation from repeated file reads.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
READ_LOG="$STATE_DIR/read_files.log"
mkdir -p "$STATE_DIR"
touch "$READ_LOG"

# Extract file_path from tool input JSON
FILE=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null)
if [ -z "$FILE" ]; then
  exit 0
fi

# Log format: "<epoch>|<file>"
NOW=$(date +%s)
WINDOW=300  # 5분 이내 재읽기만 경고

LAST_TS=$(grep -F "|$FILE" "$READ_LOG" 2>/dev/null | tail -1 | cut -d'|' -f1)
if [ -n "$LAST_TS" ]; then
  DIFF=$((NOW - LAST_TS))
  if [ "$DIFF" -lt "$WINDOW" ]; then
    MSG="[READ-ONCE] 최근 5분 내 동일 파일 재읽기: $FILE — 메모리 참조 권장."
    MSG_ESC=$(echo "$MSG" | sed 's/"/\\"/g')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$MSG_ESC\"}}"
  fi
fi

echo "$NOW|$FILE" >> "$READ_LOG"

exit 0
