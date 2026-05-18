#!/usr/bin/env bash
# codex-keepalive.sh — Codex 다계정 토큰 keep-alive
#
# 목적: ~/.codex-accounts/account*.json 에 백업된 모든 계정으로 주기적으로
#       'ping' 호출 → refresh_token rotation 강제 → 14~15일 미사용 만료 회피.
#
# 가설: OAuke OAuth refresh_token 만료는 "미사용 절대시간" 기준 → keep-alive로 회피 가능.
#
# 사용법:
#   bash codex-keepalive.sh           # 모든 계정 ping
#   bash codex-keepalive.sh --check   # 마지막 실행 후 7일 경과 확인만 (cron용)
#   bash codex-keepalive.sh --dry-run # auth swap 없이 계획만 출력
#
# 트리거: 매 7일 (Windows Task Scheduler 또는 /schedule)
# 안전: 실패해도 다른 계정에 영향 0 (각 계정 독립 처리, swap 후 원래 상태 복구 X — keep-alive 결과 = 새 토큰 = 정상)
# 로그: ~/.harness-state/codex-keepalive.log (JSONL), ~/.harness-state/codex-keepalive-last
# 알림: 1개 이상 FAIL 시 텔레그램 (TELEGRAM_BOT_TOKEN 설정 시)

set -uo pipefail

ACCOUNTS_DIR="$HOME/.codex-accounts"
CODEX_AUTH="$HOME/.codex/auth.json"
STATE_DIR="$HOME/.harness-state"
LAST_FILE="$STATE_DIR/codex-keepalive-last"
LOG_FILE="$STATE_DIR/codex-keepalive.log"
INTERVAL_DAYS=7

mkdir -p "$STATE_DIR"

MODE="run"
case "${1:-}" in
  --check)   MODE="check" ;;
  --dry-run) MODE="dry"   ;;
  "")        MODE="run"   ;;
  *)         echo "Usage: $0 [--check|--dry-run]" >&2; exit 2 ;;
esac

# --check: cron 헬퍼. 마지막 실행 후 INTERVAL_DAYS 경과 시 exit 0 (실행 필요), 미경과 시 exit 1.
if [ "$MODE" = "check" ]; then
  if [ ! -f "$LAST_FILE" ]; then
    echo "[codex-keepalive] no last-run record — run needed"
    exit 0
  fi
  LAST_TS=$(cat "$LAST_FILE")
  NOW=$(date +%s)
  AGE_DAYS=$(( (NOW - LAST_TS) / 86400 ))
  if [ "$AGE_DAYS" -ge "$INTERVAL_DAYS" ]; then
    echo "[codex-keepalive] last run ${AGE_DAYS}d ago — run needed"
    exit 0
  fi
  echo "[codex-keepalive] last run ${AGE_DAYS}d ago — skip (< ${INTERVAL_DAYS}d)"
  exit 1
fi

# 계정 수집
if [ ! -d "$ACCOUNTS_DIR" ]; then
  echo "ERROR: $ACCOUNTS_DIR not found" >&2
  exit 1
fi

ACCTS=()
while IFS= read -r f; do ACCTS+=("$f"); done \
  < <(ls "$ACCOUNTS_DIR"/account*.json 2>/dev/null | sort)

if [ "${#ACCTS[@]}" -eq 0 ]; then
  echo "ERROR: no account*.json in $ACCOUNTS_DIR" >&2
  exit 1
fi

echo "[codex-keepalive] ${#ACCTS[@]} accounts found in $ACCOUNTS_DIR"
[ "$MODE" = "dry" ] && echo "[codex-keepalive] DRY RUN — no auth swap, no codex call"

# 결과 카운터
PASS=0; FAIL=0; FAIL_NAMES=()

for ACCT in "${ACCTS[@]}"; do
  ACCT_NAME=$(basename "$ACCT" .json)
  echo "[codex-keepalive] → $ACCT_NAME"

  if [ "$MODE" = "dry" ]; then
    echo "  (dry-run) would swap $ACCT → $CODEX_AUTH, then 'codex exec ping'"
    continue
  fi

  # auth swap
  if ! cp "$ACCT" "$CODEX_AUTH" 2>/dev/null; then
    echo "  FAIL: cp $ACCT → $CODEX_AUTH"
    FAIL=$((FAIL + 1)); FAIL_NAMES+=("$ACCT_NAME(cp)")
    continue
  fi

  # ping (30초 timeout)
  OUTPUT=$(timeout 30 codex exec --skip-git-repo-check "say pong" 2>&1) || true

  # 401 / refresh_token_reused 감지
  if echo "$OUTPUT" | grep -qE "refresh_token.*already used|access token could not be refreshed|401 Unauthorized|token_expired|Failed to refresh token"; then
    echo "  FAIL: $ACCT_NAME — token expired (manual /codex-refresh needed)"
    FAIL=$((FAIL + 1)); FAIL_NAMES+=("$ACCT_NAME")
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"account\":\"$ACCT_NAME\",\"status\":\"FAIL\",\"reason\":\"token_expired\"}" >> "$LOG_FILE"
    continue
  fi

  # 성공 → 갱신된 auth.json 을 백업으로 복사 (rotation 결과 보존)
  if cp "$CODEX_AUTH" "$ACCT" 2>/dev/null; then
    echo "  PASS: $ACCT_NAME — token rotated + backup updated"
    PASS=$((PASS + 1))
    echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"account\":\"$ACCT_NAME\",\"status\":\"PASS\"}" >> "$LOG_FILE"
  else
    echo "  WARN: $ACCT_NAME ping ok, but backup update failed"
    FAIL=$((FAIL + 1)); FAIL_NAMES+=("$ACCT_NAME(backup)")
  fi
done

[ "$MODE" = "dry" ] && exit 0

# 마지막 실행 시각 기록
date +%s > "$LAST_FILE"

# 요약
SUMMARY="[codex-keepalive] ${PASS}/${#ACCTS[@]} PASS, ${FAIL} FAIL"
[ "$FAIL" -gt 0 ] && SUMMARY="$SUMMARY (failed: ${FAIL_NAMES[*]})"
echo "$SUMMARY"

# 텔레그램 알림 (FAIL 1+ 시)
if [ "$FAIL" -gt 0 ] && [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=⚠️ ${SUMMARY}%0A수동 /codex-refresh 필요" \
    >/dev/null 2>&1 || true
fi

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
