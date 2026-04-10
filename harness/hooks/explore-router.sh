#!/bin/bash
# explore-router.sh — PostToolUse hook for Read|Grep|Glob
# Counts cumulative exploration calls and recommends Agent(Explore) when
# threshold exceeded. Reasoning: Agent subagent runs in isolated context,
# returns only the summary, saving 5-10x tokens vs direct exploration.

INPUT=$(cat)
STATE_DIR="$HOME/.harness-state"
COUNTER="$STATE_DIR/explore_count"
WARNED="$STATE_DIR/explore_warned"
mkdir -p "$STATE_DIR"
touch "$COUNTER" "$WARNED"

# Increment counter
COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER"

WARN=""

# Threshold 1: 5 calls → subagent-first reminder
if [ "$COUNT" -eq 5 ] && ! grep -q "^5$" "$WARNED"; then
  echo "5" >> "$WARNED"
  WARN="[💡 SUBAGENT-FIRST] Read/Grep/Glob 누적 5회. Subagent-First 규칙: 추가 탐색/수정은 Agent(model: sonnet)로 위임. 메인 컨텍스트에는 결과만."
fi

# Threshold 2: 12 calls → strong warning
if [ "$COUNT" -eq 12 ] && ! grep -q "^12$" "$WARNED"; then
  echo "12" >> "$WARNED"
  WARN="[⚠️ DIRECT OVERFLOW] Read/Grep/Glob 누적 12회. 직접 탐색이 토큰을 낭비 중. 다음 작업은 반드시 서브에이전트로."
fi

# Threshold 3: 25 calls → excess
if [ "$COUNT" -eq 25 ] && ! grep -q "^25$" "$WARNED"; then
  echo "25" >> "$WARNED"
  WARN="[🚨 CONTEXT WASTE] 25회 직접 작업. Opus 컨텍스트 오염 심각. 서브에이전트 위임 패턴 즉시 전환."
fi

if [ -n "$WARN" ]; then
  WARN_ESCAPED=$(echo "$WARN" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$WARN_ESCAPED\"}}"
fi

exit 0
