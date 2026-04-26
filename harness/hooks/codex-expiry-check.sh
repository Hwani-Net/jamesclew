#!/usr/bin/env bash
# codex-expiry-check.sh — SessionStart hook. Codex 6계정 OAuth 토큰 14일 경과 감지 + 텔레그램 알림.
# Cloud Cron 대용 (로컬 파일 접근 필요해서 RemoteTrigger 부적합).
# PITFALL #069 (codex logout 금지) 참조.

set -uo pipefail

ACCOUNTS_DIR="$HOME/.codex-accounts"
STATE_FILE="$HOME/.harness-state/codex_expiry_last_notify"
THRESHOLD_DAYS=14

# TEST_HARNESS=1 mock 분기
if [[ -n "${TEST_HARNESS:-}" ]]; then
  echo "[codex-expiry] TEST_HARNESS=1 — skip notification"
  exit 0
fi

# accounts 디렉토리 부재 시 skip
[ ! -d "$ACCOUNTS_DIR" ] && exit 0

# account1.json mtime 기준 (rotate 시 모두 동시 갱신되므로 대표값)
ACCT="$ACCOUNTS_DIR/account1.json"
[ ! -f "$ACCT" ] && exit 0

# 경과일 계산
NOW=$(date +%s)
MTIME=$(stat -c '%Y' "$ACCT" 2>/dev/null)
[ -z "$MTIME" ] && exit 0
DAYS=$(( (NOW - MTIME) / 86400 ))

# 14일 미만이면 skip
[ "$DAYS" -lt "$THRESHOLD_DAYS" ] && exit 0

# 24h 쿨다운 (중복 알림 방지)
if [ -f "$STATE_FILE" ]; then
  LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
  AGO=$(( NOW - LAST ))
  [ "$AGO" -lt 86400 ] && exit 0
fi

# 알림 발송
mkdir -p "$(dirname "$STATE_FILE")"
echo "$NOW" > "$STATE_FILE"

MSG="⚠️ Codex 6계정 토큰 ${DAYS}일 경과 (>=${THRESHOLD_DAYS}일). 갱신 권장: /codex-refresh"

# stdout (로컬 표시)
echo "[codex-expiry] $MSG"

# 텔레그램 알림 (TELEGRAM_BOT_TOKEN 설정된 경우만)
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  curl -s --max-time 5 -X POST \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=$MSG" >/dev/null 2>&1 || \
    echo "[codex-expiry] 텔레그램 전송 실패 — 알림 손실 허용" >&2
fi

exit 0
