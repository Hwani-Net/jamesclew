#!/usr/bin/env bash
# pitfall-auto-record-stop.sh — Stop hook (2차 검증, 2026-05-04 신설)
#
# 동작:
#   1. pitfall-auto-record.sh가 UserPromptSubmit에서 critique 감지 → pending_pitfall.json 마커
#   2. 본 hook이 Stop 이벤트에서 transcript_path로 마지막 assistant 응답 추출
#   3. 응답에 agree 키워드 매치 시 → 다음 턴에 PITFALL 자동 기록 안내 주입
#
# 외부 검수: Codex(gpt-5.5) + GPT-4.1 100% 일치 권장 (Option A+B 하이브리드)
# 참조: P-111 (코드 존재 ≠ 동작 — pitfall-auto-record가 4/17~5/4 침묵)

set -euo pipefail

[[ -n "${TEST_HARNESS:-}" ]] && {
  PENDING="${FAKE_PITFALL_PENDING:-}"
  if [[ -z "$PENDING" ]]; then
    echo "[TEST] pitfall_pending.json 없음 — 스킵"
    exit 0
  fi
  if [[ "$PENDING" == *"agree"* ]]; then
    echo "[TEST] 마커 + agree 매치 → additionalContext 주입 시뮬레이션"
  else
    echo "[TEST] 마커 있음 + agree 미매치 → 만료"
  fi
  exit 0
}

HARNESS_STATE="${HOME}/.harness-state"
PENDING_FILE="$HARNESS_STATE/pitfall_pending.json"

# pending 마커 없음 = 이번 턴 critique 없음
[ ! -f "$PENDING_FILE" ] && exit 0

# pending 데이터 + age
PENDING_DATA=$(cat "$PENDING_FILE" 2>/dev/null || echo "{}")
CRITIQUE_KW=$(echo "$PENDING_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('keyword',''))" 2>/dev/null || echo "")
USER_MSG=$(echo "$PENDING_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('user_msg',''))" 2>/dev/null || echo "")
PENDING_AGE=$(echo "$PENDING_DATA" | python3 -c "import sys,json,time; print(int(time.time()-json.load(sys.stdin).get('timestamp',0)))" 2>/dev/null || echo 9999)

# 5분 이상 만료
if [ "$PENDING_AGE" -gt 300 ]; then
  rm -f "$PENDING_FILE"
  exit 0
fi

# transcript_path 추출
INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  rm -f "$PENDING_FILE"
  exit 0
fi

# 마지막 assistant 응답 텍스트 추출 (JSONL 마지막 200줄, 마지막 5개 assistant text)
LAST_ASSISTANT_TEXT=$(tail -200 "$TRANSCRIPT" 2>/dev/null | python3 -c "
import sys, json
texts = []
for line in sys.stdin:
    try:
        obj = json.loads(line)
        if obj.get('type') == 'assistant':
            content = obj.get('message', {}).get('content', [])
            if isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get('type') == 'text':
                        texts.append(item.get('text', ''))
            elif isinstance(content, str):
                texts.append(content)
    except: pass
print(' '.join(texts[-5:]))
" 2>/dev/null || echo "")

# agree 키워드 매치
AGREE_MATCH=$(echo "$LAST_ASSISTANT_TEXT" | grep -oE '알겠습니다|기록하겠습니다|맞습니다|수정하겠습니다|동의|즉시 진행|즉시 기록|기록 완료|반영하겠습니다' | head -1 || true)

if [ -z "$AGREE_MATCH" ]; then
  # 동의 없음 → 만료
  rm -f "$PENDING_FILE"
  exit 0
fi

# 매치 → 다음 턴에 PITFALL 자동 기록 권고 주입
INSTRUCTION="[PITFALL-AUTO 검증 통과] critique '$CRITIQUE_KW' + agree '$AGREE_MATCH' 매치. 다음 응답에서 다음을 즉시 실행: (1) gbrain query로 유사 항목 확인 (2) 신규면 D:/jamesclew/harness/pitfalls/pitfall-NNN-{slug}.md 작성 (3) gbrain import 실행. 사용자 메시지 요약: ${USER_MSG:0:200}"

# Stop hook output JSON (Claude Code spec)
python3 - "$INSTRUCTION" 2>/dev/null <<'PYEOF' || true
import json, sys
out = {"hookSpecificOutput": {"hookEventName": "Stop", "additionalContext": sys.argv[1]}}
print(json.dumps(out, ensure_ascii=False))
PYEOF

# pending 정리
rm -f "$PENDING_FILE"

# 텔레그램 알림 (실패 허용)
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  curl -s --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=[PITFALL-AUTO] critique+agree 매치: ${CRITIQUE_KW} / ${AGREE_MATCH}" > /dev/null 2>&1 || true
fi

exit 0
