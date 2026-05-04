#!/bin/bash
# build-detector.sh — UserPromptSubmit hook (2026-05-04 신설, P-111 audit fix)
#
# enforce-build-transition.sh가 의존하는 ~/.harness-state/build-{hash}/build_detected
# state 파일을 생성하는 책임 hook.
#
# 어떤 command도 이 파일을 만들지 않아 enforce-build-transition.sh가
# 항상 early-exit하던 침묵 패턴을 P-111 감사에서 발견.
#
# 동작:
#   - 사용자 프롬프트에 build 키워드 감지 (만들어/구현/빌드/개발/만들자/build/implement/feature/기능 추가)
#   - 감지 시 build_detected 파일 생성
#   - 이미 있으면 mtime 갱신만 (idempotent)

set -euo pipefail

[[ -n "${TEST_HARNESS:-}" ]] && {
  INPUT=$(cat)
  USER_MSG=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt') or d.get('user_message') or '')" 2>/dev/null || echo "")
  if echo "$USER_MSG" | grep -qiE '만들어|만들자|구현|빌드|개발|build|implement|feature|기능 추가|새 프로젝트'; then
    echo "[TEST] build 키워드 감지 → build_detected 파일 생성 시뮬레이션"
  else
    echo "[TEST] 무관 — hook 미발동"
  fi
  exit 0
}

INPUT=$(cat 2>/dev/null || echo "")
USER_MSG=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt') or d.get('user_message') or '')" 2>/dev/null || echo "")

# build 키워드 감지 (한국어 + 영어)
if ! echo "$USER_MSG" | grep -qiE '만들어|만들자|구현|빌드|개발|build|implement|feature|기능 추가|새 프로젝트|새로 만'; then
  exit 0
fi

# 프로젝트별 state 디렉토리 (enforce-build-transition.sh와 동일 hash 로직)
PROJECT_HASH=$(echo "$PWD" | md5sum | cut -c1-8)
STATE_DIR="$HOME/.harness-state/build-$PROJECT_HASH"
mkdir -p "$STATE_DIR"

# build_detected 파일 생성/갱신
DETECTED_FILE="$STATE_DIR/build_detected"
if [ ! -f "$DETECTED_FILE" ]; then
  echo "build keyword detected at $(date -u +%Y-%m-%dT%H:%M:%SZ) in $PWD" > "$DETECTED_FILE"
  echo "[BUILD-DETECTOR] build 키워드 감지 → $DETECTED_FILE 생성. /prd → /pipeline-install → /plan 진행 후 코드 작성 가능"
else
  # mtime 갱신만 (이미 진행 중인 빌드 세션)
  touch "$DETECTED_FILE"
fi

exit 0
