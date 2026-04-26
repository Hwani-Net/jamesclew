#!/usr/bin/env bash
# inbox-classifier.sh — Stop hook: Obsidian inbox count >= 10 시 텔레그램 알림
# PRD P4 | AC-4.1~4.5 | R9 TV-4A/B/C

set -euo pipefail

STATE_DIR="$HOME/.harness-state"
COOLDOWN_FILE="$STATE_DIR/inbox_last_notify"
mkdir -p "$STATE_DIR"

# TEST_HARNESS mock 분기
if [[ -n "${TEST_HARNESS:-}" ]]; then
    COUNT="${FAKE_INBOX_COUNT:-0}"
    VAULT="${OBSIDIAN_VAULT:-}"
    if [[ -z "$VAULT" ]]; then
        echo "[inbox-classifier] TEST: OBSIDIAN_VAULT 미설정 — skip"
        exit 0
    fi
    TODAY=$(date -u +%Y-%m-%d)
    if [[ "$COUNT" -lt 10 ]]; then
        echo "[inbox-classifier] TEST: inbox $COUNT개 < 10 — 알림 없음"
        exit 0
    fi
    PREV=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "")
    if [[ "$PREV" == "$TODAY" ]]; then
        echo "[inbox-classifier] TEST: 오늘 이미 알림 발송됨 — 쿨다운 skip"
        exit 0
    fi
    echo "[inbox-classifier] TEST: inbox $COUNT개 >= 10, 알림 mock 발송"
    echo "$TODAY" > "$COOLDOWN_FILE"
    exit 0
fi

# 실환경: OBSIDIAN_VAULT 확인
if [[ -z "${OBSIDIAN_VAULT:-}" ]]; then
    exit 0
fi

INBOX_DIR="$OBSIDIAN_VAULT/00-inbox"
if [[ ! -d "$INBOX_DIR" ]]; then
    exit 0
fi

COUNT=$(find "$INBOX_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')

if [[ "$COUNT" -lt 10 ]]; then
    exit 0
fi

TODAY=$(date -u +%Y-%m-%d)
PREV=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "")
if [[ "$PREV" == "$TODAY" ]]; then
    exit 0
fi

# 텔레그램 알림 발송
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
    MSG="[inbox-classifier] inbox ${COUNT}개 대기 중. /inbox-process 필요"
    curl -s --max-time 10 \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${MSG}" \
        > /dev/null 2>&1 || true
fi

echo "$TODAY" > "$COOLDOWN_FILE"
exit 0
