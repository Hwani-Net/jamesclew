#!/bin/bash
# tool-duration-monitor.sh — PostToolUse/PostToolUseFailure hook (2026-05-07 신설)
#
# Claude Code v2.1.119+에서 PostToolUse/PostToolUseFailure 입력에 duration_ms가 추가됨.
# 도구 실행 시간이 임계값을 넘으면 stderr 경고 + ~/.harness-state/tool_durations.jsonl에 누적.
# 성능 회귀 감지 + 느린 MCP/Bash 호출 식별에 사용.
#
# 환경변수:
#   TOOL_DURATION_WARN_MS  (default: 60000) — 경고 임계값 (ms)
#   TOOL_DURATION_LOG      (default: 1)     — 0이면 로그 비활성

set -euo pipefail

STATE_DIR="$HOME/.harness-state"
LOG_FILE="$STATE_DIR/tool_durations.jsonl"
WARN_MS="${TOOL_DURATION_WARN_MS:-60000}"
LOG_ENABLED="${TOOL_DURATION_LOG:-1}"

mkdir -p "$STATE_DIR"

[[ -n "${TEST_HARNESS:-}" ]] && {
  echo "[TEST] tool-duration-monitor.sh — duration_ms threshold check + log append (mock)"
  exit 0
}

INPUT=$(cat)

# Parse duration_ms + tool_name (silently skip if absent — older Claude Code versions)
DUR=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('duration_ms', ''))
except:
    pass
" 2>/dev/null || echo "")

[ -z "$DUR" ] && exit 0

TOOL=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', 'unknown'))
except:
    pass
" 2>/dev/null || echo "unknown")

# Numeric guard
case "$DUR" in
  ''|*[!0-9]*) exit 0 ;;
esac

# Append to log
if [ "$LOG_ENABLED" = "1" ]; then
  TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  echo "{\"ts\":\"$TS\",\"tool\":\"$TOOL\",\"duration_ms\":$DUR}" >> "$LOG_FILE"
fi

# Threshold warning
if [ "$DUR" -gt "$WARN_MS" ]; then
  SEC=$(awk -v d="$DUR" 'BEGIN{printf "%.1f", d/1000}')
  echo "[duration] $TOOL took ${SEC}s (>${WARN_MS}ms threshold) — investigate slow path" >&2
fi

exit 0
