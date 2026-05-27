#!/usr/bin/env bash
# pitfall-auto-record.sh — UserPromptSubmit hook
# Detects user correction + agent agreement, then auto-records PITFALL to gbrain.
# Also handles "기억해" / "저장해" direct save requests.

set -euo pipefail

[[ -n "${TEST_HARNESS:-}" ]] && {
  # Determine which scenario to simulate based on stdin
  INPUT=$(cat)
  USER_MSG=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt') or d.get('user_message') or '')" 2>/dev/null || echo "")
  # Simulate keyword detection output only
  if echo "$USER_MSG" | grep -qE '작업 정렬|큐 정렬|task sort'; then
    echo "[TEST] 작업 정렬 요청 감지: task_queue_sorted.json 마크다운 테이블 출력 시뮬레이션"
  elif echo "$USER_MSG" | grep -qE '다시는|하지마|하지 마|고쳐|문제|틀렸|잘못'; then
    echo "[TEST] PITFALL 후보 감지: 지적 키워드 발견 (agentmemory 호출 없음)"
  elif echo "$USER_MSG" | grep -qE '기억해|저장해'; then
    echo "[TEST] 기억해/저장해 감지: agentmemory memory_save 시뮬레이션 (실제 호출 없음)"
  else
    echo "[TEST] 무관 대화 — hook 미발동"
  fi
  exit 0
}

HARNESS_STATE="${HOME}/.harness-state"
mkdir -p "$HARNESS_STATE"
PITFALL_LOG="${HARNESS_STATE}/pitfall_recent.log"
PITFALLS_DIR="D:/jamesclew/harness/pitfalls"

INPUT=$(cat)
# 2026-05-04 fix (P-111 audit):
#   - 'user_message' → 'prompt' OR 'user_message' fallback (Claude Code UserPromptSubmit 공식 spec은 'prompt')
#   - 'assistant_response' 필드는 UserPromptSubmit stdin에 존재하지 않음 → 제거
#   - 이벤트-1 동의 검증은 신규 pitfall-auto-record-stop.sh (Stop hook)가 transcript_path로 수행
USER_MSG=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt') or d.get('user_message') or '')" 2>/dev/null || echo "")

# --- 이벤트-3: 작업 정렬 요청 (AC-3.3) ---
if echo "$USER_MSG" | grep -qE '작업 정렬|큐 정렬|task sort'; then
  QUEUE_FILE="${HARNESS_STATE}/task_queue_sorted.json"
  if [[ ! -f "$QUEUE_FILE" ]]; then
    echo "[TASK-SORT] task_queue_sorted.json 없음 — 정렬된 작업 없습니다."
    exit 0
  fi
  echo "### 작업 큐 (우선순위 순)"
  echo ""
  echo "| 순위 | ID | 제목 | 점수 | 카테고리 | 상태 |"
  echo "|------|-----|------|------|----------|------|"
  awk '
    /"id"/ { gsub(/[",]/, "", $2); id=$2 }
    /"title"/ { gsub(/[",]/, "", $2); title=$2 }
    /"score"/ { gsub(/[",]/, "", $2); score=$2 }
    /"category"/ { gsub(/[",]/, "", $2); cat=$2 }
    /"status"/ {
      gsub(/[",]/, "", $2); status=$2
      if (id != "") {
        rank++
        printf "| %d | %s | %s | %s | %s | %s |\n", rank, id, title, score, cat, status
        id=""; title=""; score=""; cat=""
      }
    }
  ' "$QUEUE_FILE"
  exit 0
fi

# --- 이벤트-2: 기억해/저장해 ---
# DEPRECATED 2026-05-19 (P-172): gbrain query/put 제거. agentmemory MCP로 대체.
# 실제 저장은 Claude Code가 mcp__agentmemory__memory_save 직접 호출.
if echo "$USER_MSG" | grep -qE '기억해|저장해'; then
  SUMMARY=$(echo "$USER_MSG" | head -c 200)
  echo "[PITFALL-HOOK] 기억해/저장해 감지 — agentmemory memory_save 필요: ${SUMMARY}"
  exit 0
fi

# --- 이벤트-1: 지적 감지 (1차 게이트, 2026-05-04 P-111 audit fix) ---
# UserPromptSubmit에는 직전 assistant 응답 접근 불가 → critique 키워드만 1차 감지
# 마커 파일 저장 → pitfall-auto-record-stop.sh (Stop hook)가 transcript에서 동의 검증 + 자동 기록
CRITIQUE_MATCH=$(echo "$USER_MSG" | grep -oE '다시는|하지마|하지 마|고쳐|문제|틀렸|잘못' | head -1 || true)

if [[ -n "$CRITIQUE_MATCH" ]]; then
  PENDING_FILE="$HARNESS_STATE/pitfall_pending.json"
  python3 - "$CRITIQUE_MATCH" "$USER_MSG" "$PENDING_FILE" 2>/dev/null <<'PYEOF' || true
import json, sys, time
keyword, user_msg, pending_file = sys.argv[1], sys.argv[2][:500], sys.argv[3]
with open(pending_file, 'w', encoding='utf-8') as f:
    json.dump({'timestamp': time.time(), 'keyword': keyword, 'user_msg': user_msg}, f, ensure_ascii=False)
PYEOF
  echo "[PITFALL-HOOK] critique 감지: '$CRITIQUE_MATCH' → Stop hook 검증 대기"
fi
exit 0
