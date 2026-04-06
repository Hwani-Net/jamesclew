#!/bin/bash
# test-manipulation-guard.sh — PostToolUse hook for Write|Edit
# Detects when test files are modified without corresponding source file changes
# This catches the #15 failure pattern: agent modifies tests to pass instead of fixing bugs
#
# Detection logic:
# 1. If modified file is a test file (*.test.*, *.spec.*, __tests__/*)
# 2. Check if any source files were also modified in this session
# 3. If only tests changed → warn "테스트 조작 의심"

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
TRACKER_FILE="$STATE_DIR/session_changes.log"
mkdir -p "$STATE_DIR"

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0

BASENAME=$(basename "$FILE")

# Is this a test file?
IS_TEST=false
case "$BASENAME" in
  *.test.*|*.spec.*|*.test|*.spec) IS_TEST=true ;;
esac
case "$FILE" in
  *__tests__/*|*__test__/*|*/tests/*|*/test/*|*/e2e/*) IS_TEST=true ;;
esac

[ "$IS_TEST" = "false" ] && exit 0

# Test file was modified — check if source files were also changed this session
if [ ! -f "$TRACKER_FILE" ]; then
  # No session tracker yet — this is the first file change
  # Can't determine if source was also changed, just log and warn
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[⚠️ TEST MANIPULATION GUARD] 테스트 파일 수정 감지: ${BASENAME}. 소스 코드도 함께 수정했는지 확인하세요. 버그를 고치지 않고 테스트만 수정하여 그린으로 만드는 것은 금지입니다.\"}}"
  exit 0
fi

# Count source vs test files changed in this session
SRC_COUNT=0
TEST_COUNT=0

while IFS= read -r line; do
  CHANGED_FILE=$(echo "$line" | sed 's/\[.*\] //')
  CHANGED_BASE=$(basename "$CHANGED_FILE")

  IS_CHANGED_TEST=false
  case "$CHANGED_BASE" in
    *.test.*|*.spec.*|*.test|*.spec) IS_CHANGED_TEST=true ;;
  esac
  case "$CHANGED_FILE" in
    *__tests__/*|*__test__/*|*/tests/*|*/test/*|*/e2e/*) IS_CHANGED_TEST=true ;;
  esac

  if [ "$IS_CHANGED_TEST" = "true" ]; then
    TEST_COUNT=$((TEST_COUNT + 1))
  else
    # Skip non-code files (md, json config, etc.)
    case "$CHANGED_BASE" in
      *.md|*.json|*.yaml|*.yml|*.toml|*.lock|*.log) ;;
      *) SRC_COUNT=$((SRC_COUNT + 1)) ;;
    esac
  fi
done < "$TRACKER_FILE"

# If tests modified but no source files → strong suspicion
if [ "$SRC_COUNT" -eq 0 ] && [ "$TEST_COUNT" -gt 0 ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[🚨 TEST MANIPULATION ALERT] 이 세션에서 테스트 파일 ${TEST_COUNT}개를 수정했지만 소스 코드는 0개 수정. 버그를 고치지 않고 테스트를 조작하여 통과시키는 패턴이 의심됩니다. 반드시 소스 코드의 실제 버그를 먼저 수정하세요.\"}}"
elif [ "$TEST_COUNT" -gt "$SRC_COUNT" ] && [ "$TEST_COUNT" -gt 2 ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[⚠️ TEST MANIPULATION WARN] 테스트 ${TEST_COUNT}개 vs 소스 ${SRC_COUNT}개 수정. 테스트 수정이 소스보다 많습니다. 테스트를 통과시키기 위해 assertion을 약화시키거나 mock을 과도하게 사용하고 있지 않은지 확인하세요.\"}}"
fi

exit 0
