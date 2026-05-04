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
    echo "[TEST] PITFALL 후보 감지: 지적 키워드 발견 (gbrain 호출 없음)"
  elif echo "$USER_MSG" | grep -qE '기억해|저장해'; then
    echo "[TEST] 기억해/저장해 감지: gbrain query/put 시뮬레이션 (실제 호출 없음)"
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
if echo "$USER_MSG" | grep -qE '기억해|저장해'; then
  KEYWORD=$(echo "$USER_MSG" | grep -oE '\S{2,20}' | head -5 | tr '\n' ' ')
  RESULT=$(gbrain query "$KEYWORD" 2>/dev/null | head -3 || echo "query failed")
  echo "[PITFALL-HOOK] 기억해/저장해 감지 → gbrain query 완료: $RESULT"
  SUMMARY=$(echo "$USER_MSG" | head -c 200)
  gbrain put --content "기억 요청: $SUMMARY" "memory-$(date -u +%Y%m%dT%H%M%SZ)" 2>/dev/null || true
  echo "[PITFALL-HOOK] gbrain put 완료"
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

# --- 이하 deprecated 분기 (2026-05-04 P-111 audit) — Stop hook으로 이관 ---
echo "[PITFALL-HOOK] 지적+동의 패턴 감지: 키워드='$CRITIQUE_MATCH'"

# 7일 이내 동일 키워드 중복 확인
SEVEN_DAYS_AGO=$(date -u -d "7 days ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
if [[ -f "$PITFALL_LOG" && -n "$SEVEN_DAYS_AGO" ]]; then
  RECENT=$(grep "$CRITIQUE_MATCH" "$PITFALL_LOG" 2>/dev/null | awk -F'\t' -v cutoff="$SEVEN_DAYS_AGO" '$1 > cutoff' | head -1 || true)
  if [[ -n "$RECENT" ]]; then
    EXISTING_SLUG=$(echo "$RECENT" | awk -F'\t' '{print $3}')
    echo "[PITFALL-HOOK] 7일 이내 동일 키워드 존재($EXISTING_SLUG) → gbrain put 즉시 실행"
    gbrain put --content "반복 지적: $CRITIQUE_MATCH / $USER_MSG" "$EXISTING_SLUG" 2>/dev/null || true
    exit 0
  fi
fi

# gbrain 중복 확인
QUERY_RESULT=$(gbrain query "$CRITIQUE_MATCH" 2>/dev/null | head -5 || echo "")
if echo "$QUERY_RESULT" | grep -q "pitfall-"; then
  FOUND_SLUG=$(echo "$QUERY_RESULT" | grep -o 'pitfall-[0-9]*-[a-z-]*' | head -1)
  echo "[PITFALL-HOOK] 기존 항목 발견: $FOUND_SLUG — 신규 생성 건너뜀"
  exit 0
fi

# 신규 PITFALL 파일 생성
LAST_NUM=$(ls "$PITFALLS_DIR"/pitfall-*.md 2>/dev/null | grep -oE 'pitfall-[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1 || echo "068")
NEW_NUM=$(printf "%03d" $((LAST_NUM + 1)))
SLUG_KEYWORD=$(echo "$CRITIQUE_MATCH" | tr ' ' '-' | tr -cd '[:alnum:]-')
SLUG="pitfall-${NEW_NUM}-${SLUG_KEYWORD}"
FILEPATH="${PITFALLS_DIR}/${SLUG}.md"

cat > "$FILEPATH" <<EOF
---
slug: ${SLUG}
title: "PITFALL ${NEW_NUM}: ${CRITIQUE_MATCH} 관련 반복 오류"
tags: [pitfall, auto-recorded]
date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---

## 증상
${USER_MSG}

## 원인
에이전트 동의 내용: ${AGREE_MATCH}

## 해결
해당 패턴 발생 시 즉시 수정 후 검증 진행

## 재발 방지
pitfall-auto-record.sh hook이 자동 감지 및 기록
EOF

gbrain import "$PITFALLS_DIR" 2>/dev/null || true

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
printf '%s\t%s\t%s\n' "$TIMESTAMP" "$CRITIQUE_MATCH" "$SLUG" >> "$PITFALL_LOG"

echo "[PITFALL-HOOK] PITFALL ${SLUG} 등록 완료"

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  curl -s --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=PITFALL ${SLUG} 자동 등록 완료" > /dev/null 2>&1 || true
fi
