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

# Safety: max 3 consecutive blocks, then force pass to prevent deadlock
BLOCK_COUNTER_FILE="$HOME/.harness-state/enforce_block_count"
BLOCK_COUNT=0
[ -f "$BLOCK_COUNTER_FILE" ] && BLOCK_COUNT=$(cat "$BLOCK_COUNTER_FILE" 2>/dev/null || echo 0)
if [ "$BLOCK_COUNT" -ge 3 ] 2>/dev/null; then
  echo "0" > "$BLOCK_COUNTER_FILE"
  exit 0  # Force pass after 3 consecutive blocks
fi

# Get transcript path to read last assistant response
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

# Read last portion of transcript (wider window to catch tool calls that precede text)
LAST_RESPONSE=$(tail -c 4000 "$TRANSCRIPT" 2>/dev/null)
[ -z "$LAST_RESPONSE" ] && exit 0

# Count tool calls in last portion of transcript
TOOL_CALLS=$(echo "$LAST_RESPONSE" | grep -cE '"tool_use"|"tool_name"|"tool_input"' 2>/dev/null)
TOOL_CALLS=${TOOL_CALLS:-0}

# === Exception: analysis/comparison context — not actual declarations ===
HAS_ANALYSIS=$(echo "$LAST_RESPONSE" | grep -cE '비교|분석|검토|판단|충돌|오버엔지니어링|Nyongjong|평가축' 2>/dev/null)
HAS_ANALYSIS=${HAS_ANALYSIS:-0}

# === Exception: PRD/plan question phase — intentionally no tool calls ===
HAS_PRD_QUESTION=$(echo "$LAST_RESPONSE" | grep -cE '구체화 질문|확인 질문|질문.*개|PRD.*질문|어떤.*것이.*중요|사용 환경|핵심 정보|어떤.*원하' 2>/dev/null)
HAS_PRD_QUESTION=${HAS_PRD_QUESTION:-0}
[ "${HAS_PRD_QUESTION:-0}" -gt 0 ] && exit 0

# === Exception: Conditional future — "~실 때/~시면/~요청 시 ...하겠습니다" ===
# Declaration inside a conditional clause = future intent, not immediate action
HAS_CONDITIONAL=$(echo "$LAST_RESPONSE" | grep -cE '있으실 때|있을 때|주시면|지시.*시|요청.*시|필요.*시|명시.*후|명시.*하시면|하시면[^가-힣]*(진행|반영|적용|수정|배포|추가)' 2>/dev/null)
HAS_CONDITIONAL=${HAS_CONDITIONAL:-0}
[ "${HAS_CONDITIONAL:-0}" -gt 0 ] && exit 0

# === Exception: Negative declaration — "안 하겠/하지 않겠/미실행" ===
HAS_NEGATIVE=$(echo "$LAST_RESPONSE" | grep -cE '안 하겠|하지 않겠|않겠습니다|미실행|실행하지 않|진행하지 않' 2>/dev/null)
HAS_NEGATIVE=${HAS_NEGATIVE:-0}
[ "${HAS_NEGATIVE:-0}" -gt 0 ] && exit 0

# === Exception: Session close context — "마무리/완료/종료" with summary ===
HAS_CLOSE_CONTEXT=$(echo "$LAST_RESPONSE" | grep -cE '마무리|세션 종료|커밋 완료|작업 완료|배포 완료|전부 완료|이번 세션.*성과|최종 상태' 2>/dev/null)
HAS_CLOSE_CONTEXT=${HAS_CLOSE_CONTEXT:-0}
[ "${HAS_CLOSE_CONTEXT:-0}" -gt 0 ] && exit 0

# === Pattern 1: Declare but don't execute ===
# Only match future-tense declarations (not past-tense reports)
# "~합니다" ending = present/report, "~하겠" = future intent without action
HAS_DECLARATION=$(echo "$LAST_RESPONSE" | grep -cE '하겠습니다|반영하겠|진행하겠|구현하겠|수정하겠|추가하겠|적용하겠|배포하겠' 2>/dev/null)
HAS_DECLARATION=${HAS_DECLARATION:-0}

if [ "${HAS_DECLARATION:-0}" -gt 0 ] 2>/dev/null && [ "${TOOL_CALLS:-0}" -eq 0 ] 2>/dev/null && [ "${HAS_ANALYSIS:-0}" -lt 2 ] 2>/dev/null; then
  echo "$((BLOCK_COUNT + 1))" > "$BLOCK_COUNTER_FILE"
  echo "{\"decision\":\"block\",\"reason\":\"선언-미실행 감지: 하겠습니다라고 선언했으나 도구 호출이 없습니다. 즉시 실행하세요.\"}"
  exit 0
fi

# === Pattern 2: Asking permission instead of executing ===
# Block regardless of tool calls — "할까요" is always a violation
# Exception: risk confirmation context — push/delete/destructive operations
HAS_RISK_CONTEXT=$(echo "$LAST_RESPONSE" | grep -cE 'push|force|reset|rebase|drop|delete|삭제|복구|롤백|배포' 2>/dev/null)
HAS_RISK_CONTEXT=${HAS_RISK_CONTEXT:-0}

HAS_PERMISSION=$(echo "$LAST_RESPONSE" | grep -cE '할까요|할까 요|진행할까|원하시면|괜찮으시|어떻게 할까|어떻게할까|필요하면 말씀|원하시는지|해볼까|적용할까' 2>/dev/null)
HAS_PERMISSION=${HAS_PERMISSION:-0}

# Block only if permission-asking is NOT in a risk confirmation context
# (CLAUDE.md "Executing actions with care" allows/requires confirmation for destructive ops)
if [ "${HAS_PERMISSION:-0}" -gt 0 ] 2>/dev/null && [ "${HAS_RISK_CONTEXT:-0}" -eq 0 ] 2>/dev/null; then
  echo "$((BLOCK_COUNT + 1))" > "$BLOCK_COUNTER_FILE"
  echo "{\"decision\":\"block\",\"reason\":\"Ghost Mode 위반: 할까요/필요하면 말씀/원하시면 금지. 작업이 명확하면 즉시 실행하세요.\"}"
  exit 0
fi

# === Pattern 3: Premature impossibility without verification ===
HAS_IMPOSSIBLE=$(echo "$LAST_RESPONSE" | grep -cE '불가능합니다|안 됩니다|할 수 없습니다|지원하지 않습니다|방법이 없습니다' 2>/dev/null)
HAS_IMPOSSIBLE=${HAS_IMPOSSIBLE:-0}
HAS_SEARCH=$(echo "$LAST_RESPONSE" | grep -cE '검색|조사|확인|tavily|perplexity|검증|리서치' 2>/dev/null)
HAS_SEARCH=${HAS_SEARCH:-0}

if [ "${HAS_IMPOSSIBLE:-0}" -gt 0 ] 2>/dev/null && [ "${HAS_SEARCH:-0}" -eq 0 ] 2>/dev/null && [ "${TOOL_CALLS:-0}" -lt 2 ] 2>/dev/null && [ "${HAS_ANALYSIS:-0}" -lt 2 ] 2>/dev/null; then
  echo "$((BLOCK_COUNT + 1))" > "$BLOCK_COUNTER_FILE"
  echo "{\"decision\":\"block\",\"reason\":\"섣부른 단정 감지: 불가능하다고 결론냈으나 검증이 부족합니다. 1) 웹 검색(Tavily/Perplexity)으로 확인 2) npm search로 MCP 서버 검색 후 claude mcp add로 등록 3) 3회 다른 접근 시도. 전부 실패 후에만 불가 보고.\"}"
  exit 0
fi

# No block triggered — reset counter
echo "0" > "$BLOCK_COUNTER_FILE"
exit 0
