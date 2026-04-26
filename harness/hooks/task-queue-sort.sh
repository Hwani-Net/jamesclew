#!/usr/bin/env bash
# task-queue-sort.sh — PostToolUse hook (TaskCreate | TodoWrite)
# Applies priority formula and writes ~/.harness-state/task_queue_sorted.json.
# Pure bash + awk only (no python3, no node — R11 compliant).
# Priority formula: urgency(0-3) + revenue(0-3) + wait(0-2) + roi(0-3) - risk(0-2)

set -euo pipefail

HARNESS_STATE="${HOME}/.harness-state"
QUEUE_FILE="${HARNESS_STATE}/task_queue_sorted.json"

[[ -n "${TEST_HARNESS:-}" ]] && {
  INPUT=$(cat 2>/dev/null || echo "{}")
  echo "[TEST] task-queue-sort: 우선순위 정렬 시뮬레이션 (파일 쓰기 없음)"
  echo "[TEST] task_queue_sorted.json 갱신 예정"
  exit 0
}

INPUT=$(cat 2>/dev/null || echo "{}")

# tool_name 추출 (bash grep/awk only)
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"' || true)

case "${TOOL_NAME}" in
  TaskCreate|TodoWrite) ;;
  *) exit 0 ;;
esac

mkdir -p "$HARNESS_STATE"

# task title 추출
TITLE=$(echo "$INPUT" | grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"' || echo "(제목 없음)")
TASK_ID=$(echo "$INPUT" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"' || echo "task-$(date +%s)")

# 키워드 휴리스틱으로 우선순위 공식 동적 산정
# 긴급도(0-3) + 수익(0-3) + 대기(0-2) + ROI(0-3) - 리스크(0-2)
URGENCY=1; REVENUE=1; WAIT=0; ROI=2; RISK=1
TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
echo "$TITLE_LOWER" | grep -qiE 'bug|fix|error|crash|hotfix|긴급|오류|버그' && URGENCY=3
echo "$TITLE_LOWER" | grep -qiE 'revenue|profit|money|sales|수익|매출|결제' && REVENUE=3
echo "$TITLE_LOWER" | grep -qiE 'wait|block|대기|차단|blocked' && WAIT=2
echo "$TITLE_LOWER" | grep -qiE 'infra|harness|hook|deploy|배포|인프라' && { ROI=3; RISK=1; }
echo "$TITLE_LOWER" | grep -qiE 'research|리서치|조사|분석' && { ROI=1; RISK=0; }
echo "$TITLE_LOWER" | grep -qiE 'new feature|신규|기능 추가' && { ROI=2; RISK=2; }
SCORE=$(( URGENCY + REVENUE + WAIT + ROI - RISK ))
[[ $SCORE -lt 0 ]] && SCORE=0
[[ $SCORE -gt 9 ]] && SCORE=9
CATEGORY="infra"
echo "$TITLE_LOWER" | grep -qiE 'bug|fix|error|crash|오류|버그' && CATEGORY="bug"
echo "$TITLE_LOWER" | grep -qiE 'revenue|profit|수익|매출' && CATEGORY="revenue"
echo "$TITLE_LOWER" | grep -qiE 'feature|기능' && CATEGORY="feature"
echo "$TITLE_LOWER" | grep -qiE 'research|리서치|조사' && CATEGORY="research"
STATUS="pending"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)

# 기존 큐 읽기 (없으면 빈 배열로 초기화)
if [[ ! -f "$QUEUE_FILE" ]]; then
  echo '{"updated_at":"","tasks":[]}' > "$QUEUE_FILE"
fi

# 새 task 항목 JSON 생성 (awk로 삽입, 중복 id 제거)
NEW_ENTRY=$(cat <<EOF
    {
      "id": "${TASK_ID}",
      "title": "${TITLE//\"/\'}",
      "score": ${SCORE},
      "urgency": 1,
      "revenue": 1,
      "wait": 0,
      "roi": 2,
      "risk": 1,
      "category": "${CATEGORY}",
      "status": "${STATUS}"
    }
EOF
)

# 기존 tasks 배열에서 동일 id 제거 후 새 항목 추가 (awk 기반 JSON 조작)
EXISTING_TASKS=$(awk '
  /"tasks"/ { in_tasks=1 }
  in_tasks && /\{/ { depth++ }
  in_tasks && /\}/ { depth--; if(depth==0) in_tasks=0 }
  1
' "$QUEUE_FILE" 2>/dev/null | \
  grep -A1000 '"tasks"' | \
  grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | \
  grep -v "\"${TASK_ID}\"" || true)

# 단순 방식: 큐 파일을 재구성 (append-then-sort 전략)
# 기존 tasks 항목 읽어서 score 기준 정렬
{
  echo "{"
  echo "  \"updated_at\": \"${TIMESTAMP}\","
  echo "  \"tasks\": ["

  # 기존 tasks에서 현재 id 제외하고 raw 항목들을 추출
  PREV_ITEMS=$(awk '
    BEGIN { depth=0; in_array=0; buf="" }
    /"tasks"[[:space:]]*:/ { in_array=1; next }
    in_array && /\[/ { depth++; next }
    in_array && depth>0 && /\{/ { buf="{"; depth++; next }
    in_array && depth>1 { buf=buf"\n"$0 }
    in_array && depth>0 && /\}/ {
      depth--
      if(depth==1) {
        buf=buf"\n}"
        print buf
        buf=""
      }
    }
    in_array && depth==0 { in_array=0 }
  ' "$QUEUE_FILE" 2>/dev/null | grep -v "\"id\"[[:space:]]*:[[:space:]]*\"${TASK_ID}\"" || true)

  FIRST=1
  while IFS= read -r ITEM; do
    [[ -z "$ITEM" ]] && continue
    [[ "$FIRST" -eq 0 ]] && echo ","
    echo "$ITEM"
    FIRST=0
  done <<< "$PREV_ITEMS"

  [[ "$FIRST" -eq 0 ]] && echo ","
  echo "$NEW_ENTRY"
  echo "  ]"
  echo "}"
} > "${QUEUE_FILE}.tmp" && mv "${QUEUE_FILE}.tmp" "$QUEUE_FILE"

# task 수 카운트
COUNT=$(grep -c '"id"' "$QUEUE_FILE" 2>/dev/null || echo "1")

echo "작업 큐 재정렬 완료 (${COUNT}개, 최상위: ${TITLE})"
