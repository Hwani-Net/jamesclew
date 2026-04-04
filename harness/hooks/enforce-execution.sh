#!/bin/bash
# enforce-execution.sh — Stop hook
# Detects two anti-patterns and blocks Stop:
# 1. "Declare but don't execute" — says "하겠습니다" but 0 tool calls
# 2. "Premature impossibility" — says "불가능/안 됩니다" without trying alternatives
#
# Hook event: Stop
# Behavior: exit 2 blocks Stop, stderr is fed to agent as error

INPUT=$(cat)

RESPONSE=$(echo "$INPUT" | jq -r '.response // empty' 2>/dev/null)
TOOL_COUNT=$(echo "$INPUT" | jq -r '.tool_use_count // 0' 2>/dev/null)

[ -z "$RESPONSE" ] && exit 0

# === Pattern 1: Declare but don't execute ===
HAS_DECLARATION=$(echo "$RESPONSE" | grep -cE '(하겠습니다|반영합니다|진행합니다|구현합니다|수정합니다|추가합니다|적용합니다|배포합니다)' 2>/dev/null || echo 0)

if [ "$HAS_DECLARATION" -gt 0 ] && [ "$TOOL_COUNT" -eq 0 ] 2>/dev/null; then
  echo "⚠️ 선언-미실행 감지: '~하겠습니다'라고 선언했으나 도구 호출이 0건입니다. 지금 즉시 실행하세요." >&2
  exit 2
fi

# === Pattern 2: Premature impossibility without verification ===
HAS_IMPOSSIBLE=$(echo "$RESPONSE" | grep -cE '(불가능합니다|안 됩니다|할 수 없습니다|지원하지 않습니다|존재하지 않습니다|방법이 없습니다|해결할 수 없습니다)' 2>/dev/null || echo 0)
HAS_SEARCH=$(echo "$RESPONSE" | grep -cE '(검색|조사|확인|리서치|tavily|perplexity|검증)' 2>/dev/null || echo 0)

if [ "$HAS_IMPOSSIBLE" -gt 0 ] && [ "$HAS_SEARCH" -eq 0 ] && [ "$TOOL_COUNT" -lt 2 ] 2>/dev/null; then
  echo "⚠️ 섣부른 단정 감지: '불가능/안 됩니다'라고 결론냈으나 검증(검색/조사)이 부족합니다. 웹 검색 또는 커뮤니티 사례를 먼저 확인하세요. (3회 시도 + 대안 2개 조사 후에만 불가 판정 허용)" >&2
  exit 2
fi

exit 0
