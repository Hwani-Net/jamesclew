#!/usr/bin/env bash
# emergency-mode-check.sh — Stop hook (additive)
# Reads 5h_usage.txt written by telegram-notify.sh heartbeat.
# Triggers Sonnet delegation mode at 80%+, clears at 60%-.

set -euo pipefail

HARNESS_STATE="${HOME}/.harness-state"
USAGE_FILE="${HARNESS_STATE}/5h_usage.txt"
MODE_FILE="${HARNESS_STATE}/emergency_mode.txt"

[[ -n "${TEST_HARNESS:-}" ]] && {
  USAGE=${1:-75}
  PREV_MODE=$(cat "$MODE_FILE" 2>/dev/null || echo "normal")
  echo "[TEST] 5H usage=${USAGE}%, prev_mode=${PREV_MODE} — 파일 변경 시뮬레이션만 (텔레그램 미발송)"
  if [[ "$USAGE" -ge 80 && "$PREV_MODE" == "normal" ]]; then
    echo "[TEST] → emergency_mode.txt='sonnet' 기록 예정"
  elif [[ "$USAGE" -le 60 && "$PREV_MODE" == "sonnet" ]]; then
    echo "[TEST] → emergency_mode.txt='normal' 기록 예정"
  else
    echo "[TEST] → 상태 변화 없음"
  fi
  exit 0
}

# 5h_usage.txt 없으면 heartbeat hook 미등록 환경 — skip
[[ ! -f "$USAGE_FILE" ]] && exit 0

USAGE=$(cat "$USAGE_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
PREV_MODE=$(cat "$MODE_FILE" 2>/dev/null | tr -d '[:space:]' || echo "normal")

# 정수 변환 (소수점 버림)
USAGE_INT=${USAGE%.*}
[[ -z "$USAGE_INT" || ! "$USAGE_INT" =~ ^[0-9]+$ ]] && exit 0

send_telegram() {
  local MSG="$1"
  if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    curl -s --max-time 10 "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d "chat_id=${TELEGRAM_CHAT_ID}" \
      -d "text=${MSG}" > /dev/null 2>&1 || true
  else
    echo "[EMERGENCY-MODE] $MSG"
  fi
}

mkdir -p "$HARNESS_STATE"

if [[ "$USAGE_INT" -ge 80 && "$PREV_MODE" == "normal" ]]; then
  echo "sonnet" > "$MODE_FILE"
  send_telegram "⚠️ 5H ${USAGE_INT}%+. Sonnet 위임 모드 활성. /model sonnet 권장"
  echo "[EMERGENCY-MODE] 비상모드 진입: usage=${USAGE_INT}%"

elif [[ "$USAGE_INT" -le 60 && "$PREV_MODE" == "sonnet" ]]; then
  echo "normal" > "$MODE_FILE"
  send_telegram "✅ 5H ${USAGE_INT}%↓ 회복. Opus 복귀 가능"
  echo "[EMERGENCY-MODE] 비상모드 해제: usage=${USAGE_INT}%"

fi

# SessionStart 배너 출력 (Stop hook에서는 미출력 — SessionStart hook에서 별도 처리)
exit 0
