#!/usr/bin/env bash
# emergency-banner.sh — SessionStart hook (AC-2.3)
# Outputs banner if emergency_mode.txt == "sonnet" at session start.

set -euo pipefail

[[ -n "${TEST_HARNESS:-}" ]] && {
  MODE=${1:-sonnet}
  if [[ "$MODE" == "sonnet" ]]; then
    echo '[TEST] {"systemMessage":"⚠️ [비상모드 활성] Sonnet 위임 권장. /model sonnet"}'
  else
    echo "[TEST] emergency_mode=normal — 배너 미출력"
  fi
  exit 0
}

MODE_FILE="${HOME}/.harness-state/emergency_mode.txt"
[[ ! -f "$MODE_FILE" ]] && exit 0

MODE=$(cat "$MODE_FILE" 2>/dev/null | tr -d '[:space:]')
[[ "$MODE" != "sonnet" ]] && exit 0

echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"⚠️ [비상모드 활성] Sonnet 위임 권장. /model sonnet 입력 후 작업 진행."}}'
