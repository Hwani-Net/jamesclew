#!/bin/bash
# JamesClaw Agent — Telegram notification helper
# Usage: bash telegram-notify.sh <event_type> [extra_message]

EVENT="${1:-info}"
EXTRA="${2:-}"
BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-8670142686:AAENLGRRLmbv3gd06p0XWUuw7HbuX8LzbD8}"
CHAT_ID="${TELEGRAM_CHAT_ID:-6702395893}"
STATE_DIR="$HOME/.claude/hooks/state"
mkdir -p "$STATE_DIR"

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
  CACHE_FILE="$STATE_DIR/usage_cache"
  CACHE_TTL=60  # 1 minute

  # Use cache if fresh enough
  if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(( $(date +%s) - $(date -r "$CACHE_FILE" +%s 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
    if [ "$CACHE_AGE" -lt "$CACHE_TTL" ] 2>/dev/null; then
      cat "$CACHE_FILE"
      return
    fi
  fi

  TOKEN=$(cat "$HOME/.claude/.credentials.json" 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  if [ -z "$TOKEN" ]; then
    # Return cached value if available, otherwise unknown
    if [ -f "$CACHE_FILE" ]; then cat "$CACHE_FILE"; else echo "?|?"; fi
    return
  fi

  RESP=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  # Check for error responses
  ERROR=$(echo "$RESP" | jq -r '.error.type // empty' 2>/dev/null)
  if [ -n "$ERROR" ]; then
    # API error — return cached value or "?"
    if [ -f "$CACHE_FILE" ]; then cat "$CACHE_FILE"; else echo "?|?"; fi
    return
  fi

  FIVE=$(echo "$RESP" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  SEVEN=$(echo "$RESP" | jq -r '.seven_day.utilization // empty' 2>/dev/null)

  if [ -z "$FIVE" ] || [ -z "$SEVEN" ]; then
    if [ -f "$CACHE_FILE" ]; then cat "$CACHE_FILE"; else echo "?|?"; fi
    return
  fi

  # Convert to percentage (API returns 0.0-1.0 or 0-100)
  FIVE_INT=$(python3 -c "v=$FIVE; print(int(v*100) if v<=1 else int(v))" 2>/dev/null || echo "?")
  SEVEN_INT=$(python3 -c "v=$SEVEN; print(int(v*100) if v<=1 else int(v))" 2>/dev/null || echo "?")

  RESULT="${FIVE_INT}|${SEVEN_INT}"
  echo "$RESULT" > "$CACHE_FILE"
  echo "$RESULT"
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

# ─── Format usage string ───
fmt_usage() {
  local USAGE="$1"
  parse_usage "$USAGE"
  if [ "$FIVE" = "?" ]; then
    echo "📊 Usage: 확인 불가 (API rate limited)"
  else
    echo "📊 5H: ${FIVE}% | 7D: ${SEVEN}%"
  fi
}

# ─── Event handlers ───
case "$EVENT" in
  start)
    # No telegram notification on session start — only record state
    echo "$(date +%s)" > "$STATE_DIR/session_start"
    SESSION_NUM=$(track_session)
    check_usage_threshold > /dev/null
    ;;

  stop)
    # No telegram notification on session stop — only record state
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
