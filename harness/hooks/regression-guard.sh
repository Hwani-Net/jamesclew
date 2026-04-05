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

# === Check 1: Regression (deletions > 2x additions AND > 10 lines) ===
WARN=""
BASENAME=$(basename "$FILE")

if [ "$DELETED" -gt 10 ] 2>/dev/null && [ "$DELETED" -gt $((ADDED * 2)) ] 2>/dev/null; then
  echo "[$(date +%H:%M:%S)] REGRESSION WARN: $BASENAME +${ADDED}/-${DELETED}" >> "$STATE_DIR/regression.log"
  DELETED_LINES=$(git diff -- "$FILE" 2>/dev/null | grep "^-[^-]" | head -5 | sed 's/^-/  /')
  WARN="[⚠️ REGRESSION GUARD] ${BASENAME}: +${ADDED}/-${DELETED}. 삭제량이 추가량의 2배. git diff로 회귀 확인 필요."
fi

# === Check 2: Error Suppression (#10) ===
# Detect: adding try-catch that swallows errors, removing throw, console.error→console.log
DIFF_CONTENT=$(git diff -- "$FILE" 2>/dev/null)
ERROR_SUPPRESS=""

# Pattern: added catch block with empty body or just console.log
if echo "$DIFF_CONTENT" | grep -q "^+.*catch.*{" 2>/dev/null; then
  # Check if the catch block suppresses the error (no throw/reject after catch)
  CATCH_LINES=$(echo "$DIFF_CONTENT" | grep "^+" | grep -c "catch")
  THROW_LINES=$(echo "$DIFF_CONTENT" | grep "^+" | grep -c "throw\|reject\|console.error")
  if [ "$CATCH_LINES" -gt 0 ] && [ "$THROW_LINES" -eq 0 ] 2>/dev/null; then
    ERROR_SUPPRESS="catch 블록 추가됨 but throw/console.error 없음 — 에러 삼키기 의심"
  fi
fi

# Pattern: removed throw statements
REMOVED_THROW=$(echo "$DIFF_CONTENT" | grep "^-.*throw " | grep -v "^---" | wc -l)
ADDED_THROW=$(echo "$DIFF_CONTENT" | grep "^+.*throw " | grep -v "^+++" | wc -l)
if [ "$REMOVED_THROW" -gt "$ADDED_THROW" ] 2>/dev/null && [ "$REMOVED_THROW" -gt 0 ] 2>/dev/null; then
  ERROR_SUPPRESS="${ERROR_SUPPRESS:+$ERROR_SUPPRESS. }throw 문 ${REMOVED_THROW}개 삭제됨 — 에러 전파 차단 의심"
fi

# Pattern: console.error → console.log downgrade
if echo "$DIFF_CONTENT" | grep -q "^-.*console\.error" 2>/dev/null && echo "$DIFF_CONTENT" | grep -q "^+.*console\.log" 2>/dev/null; then
  ERROR_SUPPRESS="${ERROR_SUPPRESS:+$ERROR_SUPPRESS. }console.error→console.log 다운그레이드 감지"
fi

if [ -n "$ERROR_SUPPRESS" ]; then
  echo "[$(date +%H:%M:%S)] ERROR SUPPRESS: $BASENAME — $ERROR_SUPPRESS" >> "$STATE_DIR/regression.log"
  WARN="${WARN:+$WARN }[🚨 ERROR SUPPRESSION #10] ${BASENAME}: ${ERROR_SUPPRESS}. 에러를 숨기지 말고 제대로 처리하세요."
fi

# Output combined warnings
if [ -n "$WARN" ]; then
  WARN_ESCAPED=$(echo "$WARN" | sed 's/"/\\"/g' | tr '\n' ' ')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$WARN_ESCAPED\"}}"
fi

exit 0
