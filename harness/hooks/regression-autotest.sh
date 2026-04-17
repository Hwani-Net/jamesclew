#!/bin/bash
# ============================================================================
# REGRESSION AUTO-TEST HOOK
# PostToolUse Write|Edit 트리거 — 변경된 파일 기반으로 관련 테스트를 자동 실행.
#
# 기존 regression-guard.sh: diff 패턴 감지 (회귀 탐지)
# 이 훅: 실제 테스트 실행 (회귀 방지)
#
# 동작:
#   1. 변경된 파일 경로 추출
#   2. 프로젝트 루트에서 테스트 명령 자동 감지
#   3. 관련 테스트만 실행 (affected 전략)
#   4. 실패 시 로그 + 텔레그램 알림
#   5. 타임아웃 60초 이내
# ============================================================================

set -uo pipefail

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"
FAILED_LOG="$STATE_DIR/regression-failed.log"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ── 변경 파일 경로 추출 ──────────────────────────────────────────────────
FILE=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || true)
if [ -z "$FILE" ]; then
  FILE=$(echo "$INPUT" | grep -oP '"path"\s*:\s*"\K[^"]+' 2>/dev/null || true)
fi

[ -z "$FILE" ] && exit 0

# 정규화
FILE=$(echo "$FILE" | tr '\\' '/')

# ── 테스트·설정 파일은 스킵 (무한루프 방지) ──────────────────────────────
case "$FILE" in
  *.test.*|*.spec.*|*__tests__*|*__mocks__*|*.md|*.json|*.yaml|*.yml|*.sh|*.env*|*CLAUDE.md*)
    exit 0
    ;;
esac

# ── 구현 코드 파일만 처리 ────────────────────────────────────────────────
case "$FILE" in
  *.py|*.ts|*.tsx|*.js|*.jsx|*.go|*.rs|*.java|*.rb|*.php|*.cs)
    : # 처리 계속
    ;;
  *)
    exit 0
    ;;
esac

# ── 프로젝트 루트 탐색 ───────────────────────────────────────────────────
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || dirname "$FILE")

# ── 테스트 명령 감지 ─────────────────────────────────────────────────────
TEST_CMD=""
TEST_ARGS=""
BASENAME=$(basename "$FILE" | sed 's/\.[^.]*$//')

if [ -f "$PROJECT_ROOT/package.json" ]; then
  # Node.js 프로젝트
  if grep -q '"test"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
    # Jest/Vitest affected 전략
    if grep -qE '"jest"|"vitest"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
      TEST_CMD="npm test --"
      TEST_ARGS="--testPathPattern=${BASENAME} --passWithNoTests"
    else
      TEST_CMD="npm test"
      TEST_ARGS=""
    fi
  fi
elif [ -f "$PROJECT_ROOT/pytest.ini" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ] || find "$PROJECT_ROOT" -name "test_*.py" -maxdepth 3 | grep -q .; then
  # Python 프로젝트
  TEST_CMD="python -m pytest"
  TEST_ARGS="-k ${BASENAME} --no-header -q"
elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
  # Rust 프로젝트
  TEST_CMD="cargo test"
  TEST_ARGS=""
elif [ -f "$PROJECT_ROOT/go.mod" ]; then
  # Go 프로젝트
  PKG_DIR=$(dirname "$FILE")
  TEST_CMD="go test"
  TEST_ARGS="-timeout 30s ./..."
fi

# 테스트 명령 없으면 스킵
if [ -z "$TEST_CMD" ]; then
  exit 0
fi

# ── 테스트 실행 (타임아웃 60초) ──────────────────────────────────────────
echo "[regression-autotest] 변경 파일: $FILE"
echo "[regression-autotest] 테스트 실행: $TEST_CMD $TEST_ARGS"

cd "$PROJECT_ROOT" || exit 0

# 타임아웃 60초로 실행, 에러만 캡처
TEST_OUTPUT=$(timeout 60 bash -c "$TEST_CMD $TEST_ARGS 2>&1" || echo "EXIT_CODE:$?")

if echo "$TEST_OUTPUT" | grep -qiE "fail|error|FAIL|ERROR" && ! echo "$TEST_OUTPUT" | grep -qiE "0 failed|passed"; then
  # 실패 감지
  echo "[regression-autotest] 테스트 실패 감지 — 로그 기록"
  echo "${TIMESTAMP} | FILE: ${FILE} | CMD: ${TEST_CMD} ${TEST_ARGS}" >> "$FAILED_LOG"
  echo "$TEST_OUTPUT" | grep -iE "fail|error|FAIL|ERROR" | head -20 >> "$FAILED_LOG"
  echo "---" >> "$FAILED_LOG"

  # 텔레그램 알림 (스크립트 존재 시)
  if [ -f "$HOME/.claude/hooks/telegram-notify.sh" ]; then
    bash "$HOME/.claude/hooks/telegram-notify.sh" "regression-fail" \
      "회귀 테스트 실패: $(basename "$FILE")\n$(echo "$TEST_OUTPUT" | grep -iE "fail|error" | head -3)" 2>/dev/null || true
  fi

  # 에이전트에게 경고 주입
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"[REGRESSION-AUTOTEST] 테스트 실패 감지. 파일: ${FILE}. 로그: ${FAILED_LOG}. 즉시 확인하세요.\"}}" >&2
else
  # 성공 또는 관련 테스트 없음 — 조용히 종료
  echo "[regression-autotest] 테스트 통과 또는 관련 테스트 없음"
fi

exit 0
