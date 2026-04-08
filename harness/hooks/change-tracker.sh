#!/bin/bash
# change-tracker.sh — PostToolUse hook for Write|Edit
# Tracks all file changes in current session to prevent losing track
# Also warns when modifying files unrelated to current task context

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
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

# 3. Warn at scope milestones only (50/100/200 files) — token saving
# Each milestone fires exactly ONCE per session to avoid noise
WARN=""
MILESTONE_FILE="$STATE_DIR/scope_milestones_fired"
touch "$MILESTONE_FILE"

check_milestone() {
  local threshold=$1
  if [ "$UNIQUE_COUNT" -ge "$threshold" ] 2>/dev/null && ! grep -q "^$threshold$" "$MILESTONE_FILE"; then
    echo "$threshold" >> "$MILESTONE_FILE"
    return 0
  fi
  return 1
}

if check_milestone 200; then
  WARN="[⚠️ SCOPE ALERT 200] 200+ 파일 수정. 작업 범위 재검토 필수."
elif check_milestone 100; then
  WARN="[⚠️ SCOPE ALERT 100] 100+ 파일 수정. 의도된 범위인지 확인."
elif check_milestone 50; then
  WARN="[⚠️ SCOPE ALERT 50] 50+ 파일 수정. 작업 목표 재확인 권장."
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
