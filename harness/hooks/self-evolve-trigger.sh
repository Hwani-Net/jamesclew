#!/usr/bin/env bash
# self-evolve-trigger.sh — Stop hook: 컨텍스트 마일스톤(20/40/60/80%) 도달 시 GPT-4.1 자동 검수
# PRD P5 | AC-5.1~5.5 | R9 TV-5A/B/C
# BLOCKER-1 해결: FAKE_CONTEXT_PCT → CLAUDE_CONTEXT → context_usage.txt → skip
# BLOCKER-2 해결: 텔레그램 실패 시 stderr 로그 후 exit 0

set -euo pipefail

STATE_DIR="$HOME/.harness-state"
MILESTONE_FILE="$STATE_DIR/last_evolve_milestone.txt"
CONTEXT_FILE="$STATE_DIR/context_usage.txt"
mkdir -p "$STATE_DIR"

# 컨텍스트 % 추출 (우선순위: FAKE_CONTEXT_PCT → CLAUDE_CONTEXT → context_usage.txt → skip)
if [[ -n "${TEST_HARNESS:-}" ]]; then
    PCT="${FAKE_CONTEXT_PCT:-}"
    if [[ -z "$PCT" ]]; then
        echo "[self-evolve] TEST: FAKE_CONTEXT_PCT 미설정 — skip"
        exit 0
    fi
else
    if [[ -n "${CLAUDE_CONTEXT:-}" ]]; then
        PCT=$(echo "$CLAUDE_CONTEXT" | grep -oP '\d+(?=%)' | head -1 || echo "")
    elif [[ -f "$CONTEXT_FILE" ]]; then
        PCT=$(cat "$CONTEXT_FILE" 2>/dev/null | grep -oP '^\d+' | head -1 || echo "")
    else
        exit 0
    fi
fi

if [[ -z "$PCT" ]] || ! [[ "$PCT" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# 마일스톤 계산 (20,40,60,80 중 PCT 이상인 가장 작은 값)
MILESTONE=0
for M in 20 40 60 80; do
    if [[ "$PCT" -ge "$M" ]]; then
        MILESTONE=$M
    fi
done

if [[ "$MILESTONE" -eq 0 ]]; then
    exit 0
fi

# 중복 차단: 동일 마일스톤 처리 여부 확인
LAST=$(cat "$MILESTONE_FILE" 2>/dev/null || echo "0")
if [[ "$LAST" -eq "$MILESTONE" ]]; then
    exit 0
fi

# TEST_HARNESS mock 분기
if [[ -n "${TEST_HARNESS:-}" ]]; then
    echo "[self-evolve] TEST: 컨텍스트 ${PCT}% — 마일스톤 ${MILESTONE}% 도달, GPT-4.1 mock 호출"
    echo "$MILESTONE" > "$MILESTONE_FILE"
    exit 0
fi

# GPT-4.1 호출 (copilot-api, timeout 30s)
PAYLOAD=$(printf '{"model":"gpt-4.1","messages":[{"role":"user","content":"세션 컨텍스트 %d%% 도달. 현재까지 진행 상황과 품질을 200자 이내로 검수하라."}]}' "$PCT")
RESPONSE=$(curl -s --max-time 30 \
    http://localhost:4141/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" 2>/dev/null || echo "")

if [[ -z "$RESPONSE" ]]; then
    echo "[self-evolve] copilot-api 미응답 — 수동 검수 필요" >&2
    REVIEW_TEXT="[self-evolve] 컨텍스트 ${PCT}% 도달. GPT-4.1 미응답 — 수동 검수 필요"
else
    REVIEW_TEXT=$(echo "$RESPONSE" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])" \
        2>/dev/null || echo "")
    if [[ -z "$REVIEW_TEXT" ]]; then
        REVIEW_TEXT="[self-evolve] 컨텍스트 ${PCT}% — GPT-4.1 응답 파싱 실패"
    fi
    echo "[self-evolve] ${PCT}% 마일스톤: $REVIEW_TEXT"
fi

# 텔레그램 전송 (실패 허용 — BLOCKER-2)
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    MSG="[self-evolve ${PCT}%] $REVIEW_TEXT"
    curl -s --max-time 10 \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${MSG}" \
        > /dev/null 2>&1 || echo "[self-evolve] 텔레그램 전송 실패 — 알림 손실 허용" >&2
fi

# 마일스톤 갱신
echo "$MILESTONE" > "$MILESTONE_FILE"
exit 0
