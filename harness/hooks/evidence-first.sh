#!/bin/bash
# evidence-first.sh — Stop hook
# Detects reporting without evidence (tool output)
# Pattern: "확인했습니다/완료했습니다/정상입니다" without preceding tool calls

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

LAST_RESPONSE=$(tail -c 15000 "$TRANSCRIPT" 2>/dev/null)
[ -z "$LAST_RESPONSE" ] && exit 0

# Count tool calls AND inline evidence (commit hashes, deploy output)
TOOL_CALLS=$(echo "$LAST_RESPONSE" | grep -cE '"tool_use"|"tool_name"|"tool_input"|"tool_result"|\[master [0-9a-f]|배포 완료|exit 0|rerun: b' 2>/dev/null)
TOOL_CALLS=${TOOL_CALLS:-0}

HAS_REPORT=$(echo "$LAST_RESPONSE" | grep -cE '확인했습니다|완료했습니다|정상입니다|문제없습니다|통과했습니다|검증 완료|ALL PASS|배포 완료' 2>/dev/null)
HAS_REPORT=${HAS_REPORT:-0}

if [ "${HAS_REPORT:-0}" -gt 0 ] 2>/dev/null && [ "${TOOL_CALLS:-0}" -eq 0 ] 2>/dev/null; then
  echo "{\"decision\":\"block\",\"reason\":\"Evidence-First 위반: 결과를 보고했으나 이 턴에서 도구 실행 증거가 없습니다. 도구 출력을 먼저 제시하세요.\"}"
  exit 0
fi

exit 0
