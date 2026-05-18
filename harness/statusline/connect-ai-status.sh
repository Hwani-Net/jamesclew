#!/bin/bash
# connect-ai-status.sh — Claude Code statusLine
#
# 입력 (stdin JSON):
#   {"model":{"display_name":"Opus 4.7"}, "workspace":{"current_dir":"..."}, "context":..., "effort":...}
#
# 출력: 한 줄 — 14시간 디버깅 경험 반영, 자율 운영 인프라 통합
#   [모델 effort] cwd · ctx N% · 5H N% · 7D N% · CAi:✅ · DQ:N
#
# 색상: ANSI escape (Claude Code statusLine 지원)
# 토큰 비용 0 — 모든 데이터 로컬 파일 read

set -uo pipefail

# stdin JSON 한 줄 read
INPUT=$(cat)

# === 1. Model + Effort ===
MODEL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('model',{}).get('display_name','?'))" 2>/dev/null || echo "?")
EFFORT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('effort',{}).get('level','') or '')" 2>/dev/null || echo "")
EFFORT_TAG=""
[ -n "$EFFORT" ] && EFFORT_TAG=" $EFFORT"

# === 2. cwd (마지막 디렉토리 component만) ===
CWD=$(echo "$INPUT" | python3 -c "import sys,json,os; d=json.load(sys.stdin); print(os.path.basename(d.get('workspace',{}).get('current_dir','') or '.'))" 2>/dev/null || echo "?")

# === 3. Context % (heartbeat에서 기록한 값) ===
CTX_FILE="$HOME/.harness-state/context_usage.txt"
CTX="?"
[ -f "$CTX_FILE" ] && CTX=$(cat "$CTX_FILE" 2>/dev/null | tr -d ' \n' || echo "?")

# === 4. 5H limit % (heartbeat) ===
H5_FILE="$HOME/.harness-state/5h_usage.txt"
H5="?"
[ -f "$H5_FILE" ] && H5=$(cat "$H5_FILE" 2>/dev/null | tr -d ' \n' || echo "?")

# === 5. 7D limit % (heartbeat) ===
D7_FILE="$HOME/.harness-state/7d_usage.txt"
D7="?"
[ -f "$D7_FILE" ] && D7=$(cat "$D7_FILE" 2>/dev/null | tr -d ' \n' || echo "?")

# === 6. Connect AI adapter health (P17 인프라) ===
CAI_HEALTH_FILE="$HOME/.harness-state/connect-ai-health-state.json"
CAI_TAG="CAi:?"
if [ -f "$CAI_HEALTH_FILE" ]; then
  HEALTHY=$(python3 -c "import sys,json;
try:
  d=json.load(open(r'$CAI_HEALTH_FILE',encoding='utf-8'))
  print('1' if d.get('healthy') else '0')
except: print('?')" 2>/dev/null || echo "?")
  case "$HEALTHY" in
    1) CAI_TAG="CAi:✅" ;;
    0) CAI_TAG="CAi:🚨" ;;
    *) CAI_TAG="CAi:?" ;;
  esac
fi

# === 7. distress queue 미처리 건수 ===
DQ_FILE="D:/conneteailab/_shared/distress_queue.jsonl"
DQ_LAST="D:/conneteailab/_shared/distress_last_processed.txt"
DQ="?"
if [ -f "$DQ_FILE" ]; then
  if [ -f "$DQ_LAST" ]; then
    LAST=$(cat "$DQ_LAST" 2>/dev/null | head -1)
    DQ=$(python3 -c "
import json
last='$LAST'
n=0
try:
  with open(r'$DQ_FILE',encoding='utf-8') as f:
    for line in f:
      line=line.strip()
      if not line: continue
      try:
        e=json.loads(line)
        if e.get('ts_utc','')>last: n+=1
      except: pass
print(n)" 2>/dev/null || echo "?")
  else
    DQ=$(wc -l < "$DQ_FILE" 2>/dev/null | tr -d ' ' || echo "?")
  fi
fi

# === 8. Emergency mode 표시 (5H 80%+ 시) ===
EM_FILE="$HOME/.harness-state/emergency_mode.txt"
EM_TAG=""
if [ -f "$EM_FILE" ] && [ "$(cat "$EM_FILE" 2>/dev/null)" = "sonnet" ]; then
  EM_TAG=" 🚨EMERG"
fi

# === ANSI colors (회사 환경 — 한국어 안전) ===
C_RESET='\033[0m'
C_DIM='\033[2m'
C_BOLD='\033[1m'
C_BLUE='\033[34m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_RED='\033[31m'
C_CYAN='\033[36m'

# 색상 결정 (사용량 기반)
ctx_color="$C_DIM"
[ "$CTX" != "?" ] && [ "$CTX" -ge 60 ] 2>/dev/null && ctx_color="$C_YELLOW"
[ "$CTX" != "?" ] && [ "$CTX" -ge 80 ] 2>/dev/null && ctx_color="$C_RED"

h5_color="$C_DIM"
[ "$H5" != "?" ] && [ "$H5" -ge 60 ] 2>/dev/null && h5_color="$C_YELLOW"
[ "$H5" != "?" ] && [ "$H5" -ge 80 ] 2>/dev/null && h5_color="$C_RED"

d7_color="$C_DIM"
[ "$D7" != "?" ] && [ "$D7" -ge 60 ] 2>/dev/null && d7_color="$C_YELLOW"
[ "$D7" != "?" ] && [ "$D7" -ge 80 ] 2>/dev/null && d7_color="$C_RED"

dq_color="$C_DIM"
[ "$DQ" != "?" ] && [ "$DQ" -gt 0 ] 2>/dev/null && dq_color="$C_YELLOW"
[ "$DQ" != "?" ] && [ "$DQ" -gt 10 ] 2>/dev/null && dq_color="$C_RED"

# === 출력 ===
printf "${C_BOLD}${C_CYAN}%s${C_RESET}${C_DIM}%s${C_RESET} ${C_BLUE}%s${C_RESET} ${C_DIM}·${C_RESET} ctx:${ctx_color}%s%%${C_RESET} ${C_DIM}·${C_RESET} 5H:${h5_color}%s%%${C_RESET} ${C_DIM}·${C_RESET} 7D:${d7_color}%s%%${C_RESET} ${C_DIM}·${C_RESET} %s ${C_DIM}·${C_RESET} DQ:${dq_color}%s${C_RESET}%s" \
  "$MODEL" "$EFFORT_TAG" "$CWD" "$CTX" "$H5" "$D7" "$CAI_TAG" "$DQ" "$EM_TAG"
