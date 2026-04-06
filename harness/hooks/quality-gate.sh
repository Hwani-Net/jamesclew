#!/bin/bash
# Quality Gate Hook
# PostToolUse (Write|Edit): 코드 파일 변경 시 "테스트 필요" 상태 기록
# PreToolUse (Bash): git commit 감지 시 테스트 실행 여부 확인 → 경고 주입
#
# 사용: settings.json에 두 곳에 등록
#   PostToolUse (Write|Edit): bash quality-gate.sh post-edit
#   PreToolUse (Bash):        bash quality-gate.sh pre-commit

ACTION="${1:-}"
INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"
DIRTY_FILE="$STATE_DIR/code_dirty"
TEST_PASS_FILE="$STATE_DIR/last_test_pass"

case "$ACTION" in
  post-edit)
    # 코드 파일 변경 감지 → dirty 상태 기록
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
    [ -z "$FILE" ] && exit 0

    # 코드 파일만 추적 (설정/문서 파일 제외)
    case "$FILE" in
      *.js|*.ts|*.jsx|*.tsx|*.py|*.go|*.rs|*.java|*.rb|*.php|*.c|*.cpp|*.h|*.cs|*.swift|*.kt)
        echo "$FILE" >> "$DIRTY_FILE"
        echo "[$(date +%H:%M:%S)] DIRTY: $FILE" >> "$STATE_DIR/quality-gate.log"
        ;;
    esac
    exit 0
    ;;

  pre-commit)
    # git commit 감지 → dirty 상태인데 테스트 미실행 시 경고
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

    # git commit인지 확인
    case "$CMD" in
      *"git commit"*|*"git merge"*) ;;
      *) exit 0 ;;
    esac

    # dirty 파일이 없으면 통과
    [ ! -f "$DIRTY_FILE" ] && exit 0
    DIRTY_COUNT=$(wc -l < "$DIRTY_FILE" 2>/dev/null || echo 0)
    [ "$DIRTY_COUNT" -eq 0 ] && exit 0

    # 최근 5분 이내 테스트 통과 기록 확인
    if [ -f "$TEST_PASS_FILE" ]; then
      LAST_TEST=$(cat "$TEST_PASS_FILE" 2>/dev/null || echo 0)
      NOW=$(date +%s)
      ELAPSED=$((NOW - LAST_TEST))
      if [ "$ELAPSED" -lt 300 ] 2>/dev/null; then
        # 5분 이내 테스트 통과 → dirty 초기화, 통과
        rm -f "$DIRTY_FILE"
        exit 0
      fi
    fi

    # 테스트 미실행 → 경고 주입 (deny가 아닌 additionalContext)
    DIRTY_LIST=$(cat "$DIRTY_FILE" | sort -u | head -5 | tr '\n' ', ')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"⚠️ QUALITY GATE: ${DIRTY_COUNT}개 코드 파일이 변경되었으나 테스트가 실행되지 않았습니다 (${DIRTY_LIST}). 커밋 전에 테스트를 실행하세요.\"}}"
    echo "[$(date +%H:%M:%S)] WARN: commit without test (${DIRTY_COUNT} dirty files)" >> "$STATE_DIR/quality-gate.log"
    exit 0
    ;;

  post-test)
    # 테스트 명령어 성공 감지 → 테스트 통과 기록 + dirty 초기화
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

    # 테스트 명령어인지 확인
    case "$CMD" in
      *"npm test"*|*"npm run test"*|*"npx jest"*|*"npx vitest"*|*"pytest"*|*"python -m pytest"*|*"go test"*|*"cargo test"*|*"bun test"*)
        echo "$(date +%s)" > "$TEST_PASS_FILE"
        rm -f "$DIRTY_FILE"
        echo "[$(date +%H:%M:%S)] TEST PASS: $CMD" >> "$STATE_DIR/quality-gate.log"
        ;;
    esac
    exit 0
    ;;
esac
