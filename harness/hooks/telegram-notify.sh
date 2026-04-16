#!/bin/bash
# JamesClaw Agent — Telegram notification helper
# Usage: bash telegram-notify.sh <event_type> [extra_message]

EVENT="${1:-info}"
EXTRA="${2:-}"
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

# Skip silently if not configured (for distribution)
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  exit 0
fi

# ─── Typing indicator ───
set_typing() {
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendChatAction" \
    -H "Content-Type: application/json" \
    -d "{\"chat_id\":\"${CHAT_ID}\",\"action\":\"typing\"}" > /dev/null 2>&1
}

# ─── Send message via Python (UTF-8 safe) ───
send_msg() {
  python3 -c "
import urllib.request, json, sys
text = sys.argv[1]
data = json.dumps({'chat_id':'${CHAT_ID}','text':text}).encode('utf-8')
req = urllib.request.Request('https://api.telegram.org/bot${BOT_TOKEN}/sendMessage', data=data, headers={'Content-Type':'application/json'})
try:
    urllib.request.urlopen(req, timeout=5)
except:
    pass
" "$1" 2>/dev/null
}

# ─── Usage check with caching (5min TTL) ───
get_usage() {
  # Read from statusline's JSON cache (no separate API call)
  CACHE_FILE="/tmp/.claude_usage_cache"

  if [ -f "$CACHE_FILE" ]; then
    FIVE=$(jq -r '.five_hour.utilization // .five_hour.used_percentage // empty' "$CACHE_FILE" 2>/dev/null)
    SEVEN=$(jq -r '.seven_day.utilization // .seven_day.used_percentage // empty' "$CACHE_FILE" 2>/dev/null)
    if [ -n "$FIVE" ] && [ -n "$SEVEN" ]; then
      FIVE_INT=$(printf "%.0f" "$FIVE" 2>/dev/null || echo "?")
      SEVEN_INT=$(printf "%.0f" "$SEVEN" 2>/dev/null || echo "?")
      echo "${FIVE_INT}|${SEVEN_INT}"
      return
    fi
  fi
  echo "?|?"
}

# ─── Parse usage result ───
parse_usage() {
  local USAGE="$1"
  FIVE="${USAGE%%|*}"
  SEVEN="${USAGE##*|}"
}

# ─── Usage threshold check (10% increments) ───
check_usage_threshold() {
  USAGE=$(get_usage)
  parse_usage "$USAGE"

  # Skip threshold check if usage is unknown
  if [ "$FIVE" = "?" ]; then
    echo "$USAGE"
    return
  fi

  PREV_FIVE=0
  if [ -f "$STATE_DIR/last_usage" ]; then
    PREV_FIVE=$(cat "$STATE_DIR/last_usage" 2>/dev/null || echo "0")
  fi

  echo "$FIVE" > "$STATE_DIR/last_usage"

  PREV_BUCKET=$((PREV_FIVE / 10))
  CURR_BUCKET=$((FIVE / 10))

  # Only alert at 50%+ in 10% increments
  if [ "$CURR_BUCKET" -gt "$PREV_BUCKET" ] 2>/dev/null && [ "$FIVE" -ge 50 ] 2>/dev/null; then
    WARN=""
    RESET_INFO=""
    if [ "$FIVE" -ge 80 ] 2>/dev/null; then
      WARN=$'\n🚨 위험 구간! 토큰 절약 필수'
    elif [ "$FIVE" -ge 50 ] 2>/dev/null; then
      WARN=$'\n⚠ 주의: MCP 호출 자제'
    fi
    send_msg "📈 Usage ${FIVE}% 도달 (이전 ${PREV_FIVE}%)
5H: ${FIVE}% | 7D: ${SEVEN}%${WARN}"
  fi

  echo "$USAGE"
}

# ─── Track daily session count ───
track_session() {
  TODAY=$(date +%Y-%m-%d)
  COUNT_FILE="$STATE_DIR/daily_${TODAY}"
  if [ -f "$COUNT_FILE" ]; then
    COUNT=$(cat "$COUNT_FILE")
    COUNT=$((COUNT + 1))
  else
    COUNT=1
    find "$STATE_DIR" -name "daily_*" -not -name "daily_${TODAY}" -delete 2>/dev/null
  fi
  echo "$COUNT" > "$COUNT_FILE"
  echo "$COUNT"
}

# ─── Debounce: prevent duplicate messages within N seconds ───
debounce_check() {
  local EVENT_TYPE="$1"
  local COOLDOWN="${2:-15}"
  local LOCK_FILE="$STATE_DIR/last_${EVENT_TYPE}"
  local NOW=$(date +%s)

  if [ -f "$LOCK_FILE" ]; then
    LAST_TS=$(cat "$LOCK_FILE" 2>/dev/null || echo 0)
    ELAPSED=$((NOW - LAST_TS))
    if [ "$ELAPSED" -lt "$COOLDOWN" ] 2>/dev/null; then
      return 1  # Too soon, skip
    fi
  fi

  echo "$NOW" > "$LOCK_FILE"
  return 0  # OK to send
}

# ─── Get context window usage from transcript ───
get_context() {
  # Find the latest session transcript
  local TRANSCRIPT=$(find "$HOME/.claude/projects" -name "*.jsonl" -not -path "*/subagents/*" -newer "$STATE_DIR/session_start" 2>/dev/null | head -1)
  if [ -z "$TRANSCRIPT" ]; then
    # Fallback: find most recent transcript
    TRANSCRIPT=$(ls -t "$HOME/.claude/projects"/*/????????-????-????-????-????????????.jsonl 2>/dev/null | head -1)
  fi
  if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
    echo "?"
    return
  fi
  # Extract latest cache_read_input_tokens (= approximate context size)
  local CTX=$(grep -oE '"cache_read_input_tokens":[0-9]+' "$TRANSCRIPT" 2>/dev/null | tail -1 | grep -oE '[0-9]+')
  if [ -z "$CTX" ]; then
    echo "?"
  else
    echo "$CTX"
  fi
}

# ─── Format context as percentage of 1M ───
fmt_context() {
  local CTX="$1"
  if [ "$CTX" = "?" ]; then
    echo "🧠 Context: ?"
    return
  fi
  local PCT=$((CTX * 100 / 1000000))
  local CTX_K=$((CTX / 1000))
  local WARN=""
  if [ "$PCT" -ge 70 ] 2>/dev/null; then
    WARN=" ⚠️ /compact 권장"
  elif [ "$PCT" -ge 50 ] 2>/dev/null; then
    WARN=" 💡 주의"
  fi
  echo "🧠 Context: ${CTX_K}K/${PCT}%${WARN}"
}

# ─── Format UTC ISO string to KST short ───
# Input: 2026-04-16T05:15:41Z  Output: 14:15 (today) or 4/20 11:00 (later)
fmt_kst() {
  local ISO="$1"
  [ -z "$ISO" ] && { echo ""; return; }
  python3 -c "
import datetime as dt, sys
try:
    s = sys.argv[1].replace('Z','+00:00')
    u = dt.datetime.fromisoformat(s).astimezone(dt.timezone(dt.timedelta(hours=9)))
    n = dt.datetime.now(dt.timezone(dt.timedelta(hours=9)))
    if u.date() == n.date():
        print(u.strftime('%H:%M KST'))
    else:
        print(u.strftime('%m/%d %H:%M KST'))
except Exception:
    pass
" "$ISO" 2>/dev/null
}

# ─── Format usage string (with KST reset times) ───
fmt_usage() {
  local USAGE="$1"
  parse_usage "$USAGE"
  local FIVE_RESET="" SEVEN_RESET=""
  if [ -f "$STATE_DIR/next-reset.json" ]; then
    FIVE_RESET=$(fmt_kst "$(jq -r '.five_hour.resets_at // empty' "$STATE_DIR/next-reset.json" 2>/dev/null)")
    SEVEN_RESET=$(fmt_kst "$(jq -r '.seven_day.resets_at // empty' "$STATE_DIR/next-reset.json" 2>/dev/null)")
  fi
  if [ "$FIVE" = "?" ]; then
    echo "📊 Usage: 확인 불가 (API rate limited)"
  else
    local LINE="📊 5H: ${FIVE}%"
    [ -n "$FIVE_RESET" ] && LINE="$LINE (리셋 ${FIVE_RESET})"
    LINE="$LINE | 7D: ${SEVEN}%"
    [ -n "$SEVEN_RESET" ] && LINE="$LINE (리셋 ${SEVEN_RESET})"
    echo "$LINE"
  fi
}

# ─── Event handlers ───
case "$EVENT" in
  start)
    echo "$(date +%s)" > "$STATE_DIR/session_start"
    SESSION_NUM=$(track_session)
    USAGE=$(check_usage_threshold)
    # Get current working directory from environment
    CWD="${CLAUDE_CWD:-$(pwd)}"
    PROJECT=$(basename "$CWD" 2>/dev/null || echo "?")
    send_msg "🚀 세션 시작 (#${SESSION_NUM})
📂 ${PROJECT}
$(fmt_usage "$USAGE")"
    ;;

  stop)
    RESULT_FILE="$STATE_DIR/last_result.txt"
    RESULT=""
    if [ -f "$RESULT_FILE" ]; then
      RESULT=$(cat "$RESULT_FILE")
      rm -f "$RESULT_FILE"
    fi

    if debounce_check "stop" 30; then
      USAGE=$(get_usage)
      CTX=$(get_context)
      # Calculate session duration
      DURATION=""
      if [ -f "$STATE_DIR/session_start" ]; then
        START_TS=$(cat "$STATE_DIR/session_start" 2>/dev/null || echo 0)
        NOW_TS=$(date +%s)
        ELAPSED=$((NOW_TS - START_TS))
        MINS=$((ELAPSED / 60))
        if [ "$MINS" -gt 0 ] 2>/dev/null; then
          DURATION="⏱ ${MINS}분"
        fi
      fi

      if [ -n "$RESULT" ]; then
        send_msg "✅ 작업 완료 ${DURATION}
$(fmt_usage "$USAGE")
$(fmt_context "$CTX")
${RESULT}"
      else
        send_msg "🔚 세션 종료 ${DURATION}
$(fmt_usage "$USAGE")
$(fmt_context "$CTX")"
      fi
    fi
    check_usage_threshold > /dev/null
    ;;

  compact)
    USAGE=$(get_usage)
    CTX=$(get_context)
    send_msg "🗜 컨텍스트 압축됨
$(fmt_usage "$USAGE")
$(fmt_context "$CTX")"
    ;;

  error)
    send_msg "❌ JamesClaw 오류
${EXTRA}
즉시 확인 필요"
    ;;

  heartbeat)
    # No message — just set typing indicator for bot status
    set_typing
    # Still check usage threshold (sends alert only at 50%+)
    check_usage_threshold > /dev/null
    ;;

  done)
    # Task completion — send message only on explicit "done" event
    USAGE=$(get_usage)
    CTX=$(get_context)
    send_msg "✅ 작업 완료
$(fmt_usage "$USAGE")
$(fmt_context "$CTX")
${EXTRA}"
    ;;

  usage)
    check_usage_threshold > /dev/null
    ;;

  daily)
    USAGE=$(get_usage)
    parse_usage "$USAGE"
    TODAY=$(date +%Y-%m-%d)
    COUNT_FILE="$STATE_DIR/daily_${TODAY}"
    SESSIONS=0
    if [ -f "$COUNT_FILE" ]; then SESSIONS=$(cat "$COUNT_FILE"); fi
    send_msg "📋 일일 리포트 (${TODAY})
세션: ${SESSIONS}회
$(fmt_usage "$USAGE")"
    ;;

  *)
    send_msg "[JamesClaw] ${EXTRA}"
    ;;
esac
