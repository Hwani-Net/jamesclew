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

# Threshold 1: 8 exploration calls in session → first nudge
if [ "$COUNT" -eq 8 ] && ! grep -q "^8$" "$WARNED"; then
  echo "8" >> "$WARNED"
  WARN="[💡 EXPLORE ROUTER] Read/Grep/Glob 누적 8회. 같은 영역 추가 탐색이 예상되면 Agent(subagent_type=\"Explore\")로 위임하세요. 단일 prompt로 여러 검색 묶음 → 메인 컨텍스트에 결과만 반환 → 5-10x 토큰 절감."
fi

# Threshold 2: 20 calls → stronger warning
if [ "$COUNT" -eq 20 ] && ! grep -q "^20$" "$WARNED"; then
  echo "20" >> "$WARNED"
  WARN="[⚠️ EXPLORE OVERFLOW] Read/Grep/Glob 누적 20회. 다음 탐색 작업은 반드시 Agent(Explore)로 위임. 직접 탐색은 컨텍스트 오염 비용이 큼."
fi

# Threshold 3: 50 calls → block-level warning
if [ "$COUNT" -eq 50 ] && ! grep -q "^50$" "$WARNED"; then
  echo "50" >> "$WARNED"
  WARN="[🚨 EXPLORE EXCESS] 50회 직접 탐색. 작업 패턴 재검토 필요. 큰 codebase 분석은 subagent로 위임이 표준."
fi

if [ -n "$WARN" ]; then
  WARN_ESCAPED=$(echo "$WARN" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$WARN_ESCAPED\"}}"
fi

exit 0
