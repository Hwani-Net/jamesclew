#!/usr/bin/env bash
# distress-queue-loader.sh — SessionStart hook
# Connect AI 에이전트의 미처리 distress_queue를 세션 시작 시 read하여
# systemMessage(additionalContext)로 주입. Claude Code(메인 세션)가 즉시 인지하고 자율 처리.
#
# 자율 운영 모드: 강 (4시간 cron + SessionStart 보완)
# 등록일: 2026-05-08

set -uo pipefail

# Windows hook runners may start Python with a CP949 stdout. Force UTF-8 before
# any Python subprocess emits Korean text that Claude stores in session JSONL.
export PYTHONIOENCODING="${PYTHONIOENCODING:-utf-8}"
export PYTHONUTF8="${PYTHONUTF8:-1}"

QUEUE_FILE="D:/conneteailab/_shared/distress_queue.jsonl"
LAST_FILE="D:/conneteailab/_shared/distress_last_processed.txt"

# 큐 파일 부재 시 조용히 skip
if [[ ! -f "$QUEUE_FILE" ]]; then
  echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":""}}'
  exit 0
fi

# 마지막 처리 시각 (없으면 24h 전)
if [[ -f "$LAST_FILE" ]]; then
  LAST_TS=$(cat "$LAST_FILE" 2>/dev/null | head -1)
else
  LAST_TS=""
fi

# 큐 entry 카운트 (전체)
TOTAL=$(wc -l < "$QUEUE_FILE" 2>/dev/null | tr -d ' ' || echo 0)

# 미처리 entry 카운트 (last_ts 이후)
if [[ -z "$LAST_TS" ]]; then
  UNPROCESSED=$TOTAL
else
  # JSON Lines에서 ts_utc > LAST_TS 카운트 (python으로 안전 비교)
  UNPROCESSED=$(python3 -c "
import json, sys
last = '$LAST_TS'
count = 0
try:
    with open('$QUEUE_FILE', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get('ts_utc', '') > last:
                    count += 1
            except Exception:
                continue
    print(count)
except Exception:
    print(0)
" 2>/dev/null || echo 0)
fi

if [[ "$UNPROCESSED" -eq 0 ]]; then
  CONTEXT="[자율운영-강] distress_queue 미처리 0건. 정상."
else
  # 상위 3건 요약 추출
  TOP3=$(python3 -c "
import json
last = '$LAST_TS'
items = []
try:
    with open('$QUEUE_FILE', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get('ts_utc', '') > last:
                    items.append(entry)
            except Exception:
                continue
    for e in items[:3]:
        agent = e.get('agent', '?')
        report = e.get('report', '?')
        hits = e.get('hits', [])
        kinds = ','.join(set(h.get('kind', '?') for h in hits[:5]))
        print(f'  - {agent} ({report}) — kinds: {kinds}, hits: {len(hits)}')
except Exception:
    pass
" 2>/dev/null)

  CONTEXT="[자율운영-강 ⚠️] Connect AI distress_queue 미처리 ${UNPROCESSED}건 감지. 즉시 자율 처리 시작 권장.
처리 절차: 1) distress_queue.jsonl 의 ts_utc > '${LAST_TS}' entry read → 2) kind별 분류(api_key/permission/missing/speculation/exec_failure/need/request) → 3) 안전 작업 자율 처리 + 위험/비용 작업 텔레그램 승인 요청 → 4) _shared/decisions.md 기록 → 5) distress_last_processed.txt 갱신 → 6) 텔레그램 요약.
상위 3건:
${TOP3}"
fi

# JSON escape (개행, 따옴표). If Python is unavailable, keep stdout ASCII-only
# instead of falling back to raw Korean text.
CONTEXT_ESCAPED=$(printf '%s' "$CONTEXT" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read(), ensure_ascii=True))" 2>/dev/null)
if [[ -z "$CONTEXT_ESCAPED" ]]; then
  CONTEXT_ESCAPED='"[distress-queue-loader] context unavailable: json escape failed"'
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$CONTEXT_ESCAPED"
exit 0
