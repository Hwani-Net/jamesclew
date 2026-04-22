#!/bin/bash
# stitch-drift-guard.sh — PostToolUse hook for mcp__stitch__fetch_screen_code
#
# Purpose: Stitch에서 디자인 코드를 가져온 직후 drift-guard init을 유도.
#   1. 프로젝트에 drift-guard snapshot(.drift-guard.json)이 없으면 init 안내
#   2. 이미 snapshot이 있으면 check 실행으로 drift 즉시 검출
#   3. @stayicon/drift-guard 미설치 시 설치 안내
#
# 설계: P-054(stitch-design-to-code-gap) 재발 방지.
#   `/design-review` Vision 검토는 사후 시각적 gate, drift-guard는 토큰/DOM 구조 gate.
#   두 레이어 병행.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
case "$TOOL" in
  mcp__stitch__fetch_screen_code|mcp__stitch__generate_screen_from_text|mcp__stitch__edit_screens|mcp__stitch__apply_design_system)
    ;;
  *) exit 0 ;;
esac

# Debounce: 같은 세션에서 중복 주입 방지 (10분 간격)
DEBOUNCE_FILE="$STATE_DIR/stitch_drift_guard_last"
NOW=$(date +%s)
if [ -f "$DEBOUNCE_FILE" ]; then
  LAST=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -lt 600 ]; then
    exit 0
  fi
fi
echo "$NOW" > "$DEBOUNCE_FILE"

# drift-guard 설치 여부
if ! command -v drift-guard >/dev/null 2>&1 && ! npx --no-install drift-guard --version >/dev/null 2>&1; then
  MSG="[STITCH+DRIFT-GUARD] Stitch 디자인 수신 감지. drift-guard 미설치 — \`npm install -g @stayicon/drift-guard\` 먼저 실행. P-054 재발 방지 필수."
  MSG_ESC=$(echo "$MSG" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$MSG_ESC\"}}"
  exit 0
fi

# 프로젝트 루트 판정: CWD 또는 상위에 package.json
PROJECT_ROOT=""
D="$PWD"
for _ in 1 2 3 4 5; do
  if [ -f "$D/package.json" ]; then PROJECT_ROOT="$D"; break; fi
  D=$(dirname "$D")
done
PROJECT_ROOT=${PROJECT_ROOT:-$PWD}

SNAPSHOT="$PROJECT_ROOT/.drift-guard.json"

if [ ! -f "$SNAPSHOT" ]; then
  MSG="[STITCH+DRIFT-GUARD] Stitch 디자인 수신. 이 프로젝트에 drift-guard snapshot 없음. 즉시 실행:
  1. Stitch export를 \`$PROJECT_ROOT/design.html\`로 저장 후
  2. cd \"$PROJECT_ROOT\" && npx drift-guard init --from design.html
  3. npx drift-guard rules  (CLAUDE.md/.cursorrules에 FORBIDDEN 토큰 규칙 주입)
이후 구현·배포 직전 \`npx drift-guard check\`로 drift 감지. P-054 재발 차단."
else
  MSG="[STITCH+DRIFT-GUARD] 기존 snapshot($SNAPSHOT) 감지. Stitch 재생성이 디자인 토큰을 바꾸는지 확인:
  cd \"$PROJECT_ROOT\" && npx drift-guard check
실패 시 (a) 의도된 변경이면 \`npx drift-guard init --from <new-design.html>\`로 lock 갱신 (b) 의도외면 Stitch 출력 수정."
fi

MSG_ESC=$(echo "$MSG" | sed 's/"/\\"/g' | tr '\n' ' ')
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$MSG_ESC\"}}"
exit 0
