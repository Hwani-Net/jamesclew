#!/bin/bash
# explore-router.sh — PostToolUse hook for Read|Grep|Glob|Bash|Edit|Write
# Counts ALL direct tool calls and enforces Subagent-First rule.
# Agent subagent runs in isolated context, returns only summary → 5-10x token savings.
# Critical: blog-auto session showed 194 direct calls vs 28 subagent = 87% direct = 5H drain.

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

# Threshold 1: 15 calls → subagent-first reminder
if [ "$COUNT" -eq 15 ] && ! grep -q "^15$" "$WARNED"; then
  echo "15" >> "$WARNED"
  WARN="[💡 SUBAGENT-FIRST] Read/Grep/Glob 누적 15회. 추가 탐색/수정은 Agent(model: sonnet)로 위임 검토."
fi

# Threshold 2: 30 calls → strong warning
if [ "$COUNT" -eq 30 ] && ! grep -q "^30$" "$WARNED"; then
  echo "30" >> "$WARNED"
  WARN="[⚠️ DIRECT OVERFLOW] Read/Grep/Glob 누적 30회. 직접 탐색이 토큰을 낭비 중. 다음 작업은 반드시 서브에이전트로."
fi

# Threshold 3: 50 calls → excess
if [ "$COUNT" -eq 50 ] && ! grep -q "^50$" "$WARNED"; then
  echo "50" >> "$WARNED"
  WARN="[🚨 CONTEXT WASTE] 50회 직접 작업. Opus 컨텍스트 오염 심각. 서브에이전트 위임 패턴 즉시 전환."
fi

if [ -n "$WARN" ]; then
  WARN_ESCAPED=$(echo "$WARN" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$WARN_ESCAPED\"}}"
fi

exit 0
