#!/bin/bash
# regression-guard.sh — PostToolUse hook for Write|Edit
# Detects silent regressions: when a fix inadvertently reverts other changes
#
# Strategy:
# 1. After Write/Edit, run git diff on the changed file
# 2. Count deleted lines vs added lines
# 3. If deletions > 2x additions AND deletions > 10 lines → warn
# 4. Inject context asking agent to verify no regression occurred
#
# This catches: full-file overwrites, accidental reverts, copy-paste from old versions

INPUT=$(cat)
STATE_DIR="$HOME/.claude/hooks/state"
mkdir -p "$STATE_DIR"

# Extract file path from tool input
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

# Only check files in git repos
cd "$(dirname "$FILE")" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree &>/dev/null || exit 0

# Get diff stats for this file
DIFF_STAT=$(git diff --numstat -- "$FILE" 2>/dev/null)
[ -z "$DIFF_STAT" ] && exit 0

ADDED=$(echo "$DIFF_STAT" | awk '{print $1}')
DELETED=$(echo "$DIFF_STAT" | awk '{print $2}')

# Handle binary files
[ "$ADDED" = "-" ] && exit 0

# Threshold: deletions > 2x additions AND deletions > 10
if [ "$DELETED" -gt 10 ] 2>/dev/null && [ "$DELETED" -gt $((ADDED * 2)) ] 2>/dev/null; then
  BASENAME=$(basename "$FILE")

  # Log
  echo "[$(date +%H:%M:%S)] REGRESSION WARN: $BASENAME +${ADDED}/-${DELETED}" >> "$STATE_DIR/regression.log"

  # Show what was deleted (first 5 deleted lines)
  DELETED_LINES=$(git diff -- "$FILE" 2>/dev/null | grep "^-[^-]" | head -5 | sed 's/^-/  /')

  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[⚠️ REGRESSION GUARD] ${BASENAME}: +${ADDED}줄 추가, -${DELETED}줄 삭제. 삭제량이 추가량의 2배 이상입니다. 의도하지 않은 회귀가 없는지 git diff로 확인하세요. 삭제된 내용 일부:\\n${DELETED_LINES}\"}}"
fi

exit 0
