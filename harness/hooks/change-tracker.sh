#!/bin/bash
# change-tracker.sh — PostToolUse hook for Write|Edit
# Tracks all file changes in current session to prevent losing track
# Also warns when modifying files unrelated to current task context

INPUT=$(cat)
STATE_DIR="$HOME/.claude/hooks/state"
TRACKER_FILE="$STATE_DIR/session_changes.log"
mkdir -p "$STATE_DIR"

# Extract file path
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

BASENAME=$(basename "$FILE")
DIR=$(dirname "$FILE")
NOW=$(date +"%H:%M:%S")

# 1. Log every file change to session tracker
echo "[$NOW] $FILE" >> "$TRACKER_FILE"

# 2. Count unique files changed this session
UNIQUE_COUNT=$(sort -u "$TRACKER_FILE" 2>/dev/null | grep -v "^\[" | wc -l 2>/dev/null || echo 0)
# More reliable: count unique paths
UNIQUE_COUNT=$(sed 's/\[.*\] //' "$TRACKER_FILE" 2>/dev/null | sort -u | wc -l)

# 3. Warn if too many different files changed (possible scope creep)
WARN=""
if [ "$UNIQUE_COUNT" -gt 15 ] 2>/dev/null; then
  WARN="[⚠️ SCOPE ALERT] 이 세션에서 ${UNIQUE_COUNT}개 파일을 수정했습니다. 작업 범위가 넓어지고 있습니다. 현재 작업 목표와 관련 없는 파일을 수정하고 있지 않은지 확인하세요."
fi

# 4. Detect if editing a file far from current working directory (possible wrong file)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$CWD" ] && [ -n "$DIR" ]; then
  # Check if file is in a completely different drive/project
  FILE_DRIVE=$(echo "$FILE" | cut -c1-3)
  CWD_DRIVE=$(echo "$CWD" | cut -c1-3)

  # Different drive = likely wrong file
  if [ "$FILE_DRIVE" != "$CWD_DRIVE" ] 2>/dev/null; then
    WARN="[⚠️ WRONG FILE?] ${BASENAME}은 현재 작업 디렉토리($CWD)와 다른 드라이브($FILE_DRIVE)에 있습니다. 올바른 파일을 수정하고 있는지 확인하세요."
  fi
fi

if [ -n "$WARN" ]; then
  # Escape for JSON
  WARN_ESCAPED=$(echo "$WARN" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$WARN_ESCAPED\"}}"
fi

exit 0
