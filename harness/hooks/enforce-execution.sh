#!/bin/bash
# enforce-execution.sh — Stop hook
# Detects two anti-patterns by reading the transcript:
# 1. "Declare but don't execute" — says "하겠습니다" but no tool calls in last turn
# 2. "Premature impossibility" — says "불가능/안 됩니다" without search/verification
#
# Hook event: Stop
# Output: JSON { "decision": "block", "reason": "..." } to prevent stopping
# Uses stop_hook_active flag to prevent infinite loops

INPUT=$(cat)

# Prevent infinite loop — if stop hook already ran, let it pass
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

# Get transcript path to read last assistant response
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

# Read last few lines of transcript (last assistant turn)
LAST_RESPONSE=$(tail -c 5000 "$TRANSCRIPT" 2>/dev/null)
[ -z "$LAST_RESPONSE" ] && exit 0

# Count tool calls in last portion of transcript
TOOL_CALLS=$(echo "$LAST_RESPONSE" | grep -cE '"tool_use"|"tool_name"|"tool_input"' 2>/dev/null)
TOOL_CALLS=${TOOL_CALLS:-0}

# === Pattern 1: Declare but don't execute ===
HAS_DECLARATION=$(echo "$LAST_RESPONSE" | grep -cE '하겠습니다|반영합니다|진행합니다|구현합니다|수정합니다|추가합니다|적용합니다|배포합니다' 2>/dev/null)
HAS_DECLARATION=${HAS_DECLARATION:-0}

if [ "${HAS_DECLARATION:-0}" -gt 0 ] 2>/dev/null && [ "${TOOL_CALLS:-0}" -eq 0 ] 2>/dev/null; then
  echo "{\"decision\":\"block\",\"reason\":\"선언-미실행 감지: 하겠습니다라고 선언했으나 도구 호출이 없습니다. 즉시 실행하세요.\"}"
  exit 0
fi

# === Pattern 2: Asking permission instead of executing ===
HAS_PERMISSION=$(echo "$LAST_RESPONSE" | grep -cE '할까요|할까 요|진행할까|원하시|괜찮으시|어떻게 할까|어떻게할까' 2>/dev/null)
HAS_PERMISSION=${HAS_PERMISSION:-0}

if [ "${HAS_PERMISSION:-0}" -gt 0 ] 2>/dev/null && [ "${TOOL_CALLS:-0}" -eq 0 ] 2>/dev/null; then
  echo "{\"decision\":\"block\",\"reason\":\"Ghost Mode 위반: 할까요? 금지. 작업이 명확하면 즉시 실행하세요.\"}"
  exit 0
fi

# === Pattern 3: Premature impossibility without verification ===
HAS_IMPOSSIBLE=$(echo "$LAST_RESPONSE" | grep -cE '불가능합니다|안 됩니다|할 수 없습니다|지원하지 않습니다|방법이 없습니다' 2>/dev/null)
HAS_IMPOSSIBLE=${HAS_IMPOSSIBLE:-0}
HAS_SEARCH=$(echo "$LAST_RESPONSE" | grep -cE '검색|조사|확인|tavily|perplexity|검증|리서치' 2>/dev/null)
HAS_SEARCH=${HAS_SEARCH:-0}

if [ "${HAS_IMPOSSIBLE:-0}" -gt 0 ] 2>/dev/null && [ "${HAS_SEARCH:-0}" -eq 0 ] 2>/dev/null && [ "${TOOL_CALLS:-0}" -lt 2 ] 2>/dev/null; then
  echo "{\"decision\":\"block\",\"reason\":\"섣부른 단정 감지: 불가능하다고 결론냈으나 검증이 부족합니다. 1) 웹 검색으로 확인 2) npm search 'keyword mcp'로 MCP 서버 검색 후 lazy-mcp에 등록 3) 3회 다른 접근 시도. 전부 실패 후에만 불가 보고.\"}"
  exit 0
fi

exit 0
