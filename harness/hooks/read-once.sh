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

# Check if already read this session
if grep -qF "$FILE" "$READ_LOG" 2>/dev/null; then
  MSG="[READ-ONCE] 이 파일은 이미 읽었습니다: $FILE — 서브에이전트 요약을 참조하거나 메모리에서 직접 사용하세요. 재읽기는 토큰을 낭비합니다."
  MSG_ESC=$(echo "$MSG" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$MSG_ESC\"}}"
else
  # Record first read
  echo "$FILE" >> "$READ_LOG"
fi

exit 0
