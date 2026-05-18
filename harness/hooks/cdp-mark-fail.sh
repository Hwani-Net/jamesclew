#!/bin/bash
# cdp-mark-fail.sh — PostToolUse hook: cdp-*.js Bash 명령이 실패하면
# ~/.harness-state/cdp-last-fail 타임스탬프 기록 → 다음 cdp-auto-ensure가 강제 재시작 트리거.

if [[ -n "$TEST_HARNESS" ]]; then
  echo "[cdp-mark-fail] TEST: skipped"
  exit 0
fi

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null)
command=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
exit_code=$(echo "$input" | jq -r '.tool_response.exit_code // .tool_response.code // 0' 2>/dev/null)
stderr=$(echo "$input" | jq -r '.tool_response.stderr // ""' 2>/dev/null)

[[ "$tool_name" != "Bash" ]] && exit 0

# cdp-*.js 명령만 추적
if ! echo "$command" | grep -iqE "cdp-[a-z]+\.js"; then
  exit 0
fi

# 실패 신호: exit code 비0 또는 stderr에 'Timeout'/'ECONNREFUSED'/'connectOverCDP' 포함
if [[ "$exit_code" != "0" ]] || echo "$stderr" | grep -iqE "(Timeout|ECONNREFUSED|connectOverCDP.*Timeout|browserType)"; then
  mkdir -p "$HOME/.harness-state"
  touch "$HOME/.harness-state/cdp-last-fail"
  echo "[cdp-mark-fail] fail 감지 → cdp-last-fail 기록 (다음 cdp 작업 시 강제 재시작)" >&2
fi

exit 0
