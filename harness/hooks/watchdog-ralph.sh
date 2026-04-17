#!/bin/bash
# JamesClaw Agent — Ralph Loop Watchdog (v2, High 4건 fix 반영)
# PostToolUse(Bash)에서 호출. 5분 debounce.
#
# 동작:
#   1. /tmp/.claude_usage_cache 읽어 5H utilization 확인
#   2. 임계(기본 85%)+ → .claude/ralph-loop.local.md → .paused.md + flag 파일
#   3. 회복(기본 70% 이하) + paused 상태 → 자동 resume
#   4. 캐시 stale(10분+)/미존재 3회 연속 → 경고 주입 (pause는 안 함)
#
# fix 반영:
#   (1) 캐시 stale: mtime > STALE_SEC이면 pause 보류 + 경고 카운터
#   (2) 캐시 미존재: miss_count 누적, 임계치 도달 시 경고
#   (3) rename race: flag 파일을 먼저 생성해서 stop-hook 실행 순서와 무관하게 pause 상태 기록
#   (4) resume 자동화: 사용량 회복 + paused 파일 존재 시 역방향 mv
#   (5) mv 실패: 실패 시 flag만 남기고 에러 알림

set -eu

STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

CHECK_MARKER="$STATE_DIR/watchdog_last_check"
MISS_COUNTER="$STATE_DIR/watchdog_cache_miss"
FLAG_FILE="$STATE_DIR/ralph_pause.flag"
REASON_FILE="$STATE_DIR/ralph_pause_reason.txt"
DEBOUNCE_SEC=300
STALE_SEC=600                # 10분 이상 된 캐시는 신뢰 안 함
MISS_THRESHOLD=3

PAUSE_THRESHOLD="${RALPH_PAUSE_THRESHOLD:-85}"
RESUME_THRESHOLD="${RALPH_RESUME_THRESHOLD:-70}"

# ──────────────────────────────────────────────────
# Debounce
NOW=$(date +%s)
if [ -f "$CHECK_MARKER" ]; then
  LAST=$(cat "$CHECK_MARKER" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -lt "$DEBOUNCE_SEC" ]; then
    exit 0
  fi
fi
echo "$NOW" > "$CHECK_MARKER"

STATE_LOCAL=".claude/ralph-loop.local.md"
STATE_PAUSED=".claude/ralph-loop.paused.md"

# ──────────────────────────────────────────────────
# Ralph 활성·pause 상태가 아니면 종료
if [ ! -f "$STATE_LOCAL" ] && [ ! -f "$STATE_PAUSED" ]; then
  exit 0
fi

# ──────────────────────────────────────────────────
# 사용량 읽기 + stale/miss 처리
CACHE_FILE="/tmp/.claude_usage_cache"
FIVE_INT=""
CACHE_STATUS="ok"

if [ ! -f "$CACHE_FILE" ]; then
  MISS=$(cat "$MISS_COUNTER" 2>/dev/null || echo 0)
  MISS=$((MISS + 1))
  echo "$MISS" > "$MISS_COUNTER"
  if [ "$MISS" -ge "$MISS_THRESHOLD" ]; then
    cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠️ watchdog: usage cache 미존재 ${MISS}회 연속. statusline 동작 확인 필요. Ralph Loop pause 판단 불가."}}
EOF
  fi
  exit 0
fi

# stale 체크 (mtime 기반)
CACHE_MTIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
CACHE_AGE=$((NOW - CACHE_MTIME))
if [ "$CACHE_AGE" -gt "$STALE_SEC" ]; then
  CACHE_STATUS="stale (${CACHE_AGE}s old)"
fi

echo 0 > "$MISS_COUNTER"   # cache 존재 시 miss counter 초기화

FIVE=$(jq -r '.five_hour.utilization // .five_hour.used_percentage // empty' "$CACHE_FILE" 2>/dev/null || echo "")
if [ -n "$FIVE" ] && [ "$FIVE" != "null" ]; then
  FIVE_INT=$(printf "%.0f" "$FIVE" 2>/dev/null || echo "")
fi

if [ -z "$FIVE_INT" ]; then
  exit 0
fi

# ──────────────────────────────────────────────────
# Resume 분기: paused 상태 + 사용량 회복 → 역방향 mv
if [ -f "$STATE_PAUSED" ] && [ ! -f "$STATE_LOCAL" ]; then
  if [ "$CACHE_STATUS" = "ok" ] && [ "$FIVE_INT" -le "$RESUME_THRESHOLD" ] 2>/dev/null; then
    if mv "$STATE_PAUSED" "$STATE_LOCAL" 2>/dev/null; then
      rm -f "$FLAG_FILE"
      TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      echo "resumed_at: $TS (usage ${FIVE_INT}%)" >> "$REASON_FILE"

      if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
        python3 -c "
import urllib.request, json
data = json.dumps({'chat_id':'${TELEGRAM_CHAT_ID}','text':'🟢 Ralph Loop 자동 재개\n사용량: ${FIVE_INT}% (resume threshold ${RESUME_THRESHOLD}%)\n시각: ${TS}'}).encode('utf-8')
req = urllib.request.Request('https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage', data=data, headers={'Content-Type':'application/json'})
try: urllib.request.urlopen(req, timeout=5)
except: pass
" 2>/dev/null || true
      fi

      cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"🟢 Ralph Loop 자동 재개됨. 사용량 ${FIVE_INT}% 회복. 상태파일 복원: $STATE_LOCAL"}}
EOF
    fi
  fi
  exit 0
fi

# ──────────────────────────────────────────────────
# Pause 분기: 활성 상태 + 사용량 임계 초과
if [ ! -f "$STATE_LOCAL" ]; then
  exit 0
fi

if [ "$CACHE_STATUS" != "ok" ]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠️ watchdog: usage cache stale ($CACHE_STATUS). pause 판단 보류."}}
EOF
  exit 0
fi

if [ "$FIVE_INT" -lt "$PAUSE_THRESHOLD" ] 2>/dev/null; then
  exit 0
fi

# 임계 초과 → pause 실행
# (3) flag 파일을 **먼저** 생성: stop-hook이 상태파일 보는 타이밍과 무관하게 pause 기록됨
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REASON="5H usage ${FIVE_INT}% (pause threshold ${PAUSE_THRESHOLD}%)"
cat > "$FLAG_FILE" <<EOF
paused_at: $TS
reason: $REASON
usage_at_pause: $FIVE_INT
resume_threshold: $RESUME_THRESHOLD
EOF

# (5) mv 실패 처리
if ! mv "$STATE_LOCAL" "$STATE_PAUSED" 2>/dev/null; then
  echo "mv_failed_at: $TS" >> "$FLAG_FILE"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    python3 -c "
import urllib.request, json
data = json.dumps({'chat_id':'${TELEGRAM_CHAT_ID}','text':'🚨 watchdog: pause 시도했으나 mv 실패. 파일 잠김/권한 확인 필요.\nusage: ${FIVE_INT}% / reason: ${REASON}'}).encode('utf-8')
req = urllib.request.Request('https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage', data=data, headers={'Content-Type':'application/json'})
try: urllib.request.urlopen(req, timeout=5)
except: pass
" 2>/dev/null || true
  fi
  exit 0
fi

cat > "$REASON_FILE" <<EOF
paused_at: $TS
reason: $REASON
state_file: $STATE_PAUSED
auto_resume_at: usage <= ${RESUME_THRESHOLD}%
manual_resume: mv $STATE_PAUSED $STATE_LOCAL && rm $FLAG_FILE
EOF

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  python3 -c "
import urllib.request, json
data = json.dumps({'chat_id':'${TELEGRAM_CHAT_ID}','text':'🛑 Ralph Loop 자동 pause\n사유: ${REASON}\n자동 재개: 사용량 ${RESUME_THRESHOLD}% 이하 회복 시\n시각: ${TS}'}).encode('utf-8')
req = urllib.request.Request('https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage', data=data, headers={'Content-Type':'application/json'})
try: urllib.request.urlopen(req, timeout=5)
except: pass
" 2>/dev/null || true
fi

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠️ Ralph Loop 자동 pause. 사유: $REASON. 자동 재개 임계: ${RESUME_THRESHOLD}%. 상태파일: $STATE_PAUSED"}}
EOF

exit 0
