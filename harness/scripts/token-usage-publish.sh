#!/bin/bash
# token-usage-publish.sh — 컨테이너 로컬 롤업을 리포에 영속화한다.
#
# 왜 필요한가: Stop hook은 롤업을 ~/.harness-state/token_usage.jsonl 에 쌓지만,
# 원격 세션 컨테이너는 회수되면서 그 파일도 함께 사라진다. 계정 전체 세션을
# 하나의 목록으로 모으려면 공용 영속 저장소가 필요하고, 이 리포가 그 역할을 한다.
#
# 사용법:
#   bash harness/scripts/token-usage-publish.sh [작업명]
#
# 하는 일:
#   1) 현재 세션 롤업을 harness/docs/token-usage/YYYY-MM.jsonl 에 append
#   2) 통합 목록 리포트를 harness/docs/token-usage/report-YYYY-MM-DD.md 로 생성
#   3) 커밋 (push는 호출자가 판단 — 자동 push 안 함)
#
# 커밋만 하고 push를 안 하는 이유: push는 결재 대상(CLAUDE.md P-168)이라
# 스크립트가 임의로 밀지 않는다. 호출하는 쪽(예: harness-audit-daily)이 결정한다.

set -u

TASK="${1:-${HARNESS_TASK:-}}"
REPO_ROOT="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
OUT_DIR="$REPO_ROOT/harness/docs/token-usage"
SCRIPT="$REPO_ROOT/harness/scripts/token-usage-report.py"

PY=$(command -v python3 || command -v python) || { echo "python 없음"; exit 1; }
[ -f "$SCRIPT" ] || { echo "리포트 스크립트 없음: $SCRIPT"; exit 1; }

mkdir -p "$OUT_DIR"
MONTH=$(date -u +%Y-%m)
TODAY=$(date -u +%Y-%m-%d)
LEDGER="$OUT_DIR/$MONTH.jsonl"

# 1) 이번 세션 롤업 append
TMP=$(mktemp) || exit 1
if "$PY" "$SCRIPT" --emit-ledger ${TASK:+--task "$TASK"} >"$TMP" 2>/dev/null && [ -s "$TMP" ]; then
  cat "$TMP" >>"$LEDGER"
  echo "롤업 append: $LEDGER ($(wc -l <"$TMP")행)"
else
  echo "이번 세션 사용량 기록 없음 — append 건너뜀"
fi
rm -f "$TMP"

# 2) 통합 목록 리포트 생성 (리포 원장 전체 + 라이브 트랜스크립트)
"$PY" "$SCRIPT" >"$OUT_DIR/report-$TODAY.md" || { echo "리포트 생성 실패"; exit 1; }
echo "리포트 생성: $OUT_DIR/report-$TODAY.md"

# 3) 커밋 (변경 있을 때만)
cd "$REPO_ROOT" || exit 1
git add "$OUT_DIR" || exit 1
if git diff --cached --quiet -- "$OUT_DIR"; then
  echo "변경 없음 — 커밋 건너뜀"
  exit 0
fi
git commit -q -m "chore(token-usage): ${TASK:-세션} 사용량 롤업 $TODAY" \
  -m "Co-Authored-By: Claude <noreply@anthropic.com>" || exit 1
echo "커밋 완료. push는 호출자가 판단."
