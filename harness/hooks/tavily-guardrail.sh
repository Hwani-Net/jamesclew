#!/bin/bash
# tavily-guardrail.sh — PreToolUse hook for mcp__tavily__*
# Enforces token-efficient defaults: search_depth=basic, max_results<=5
# Rationale: Tavily returns 11.6KB avg/call — highest per-call of any tool.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

case "$TOOL" in
  mcp__tavily__tavily_search|mcp__tavily__tavily_research)
    DEPTH=$(echo "$INPUT" | jq -r '.tool_input.search_depth // "basic"' 2>/dev/null)
    MAX=$(echo "$INPUT" | jq -r '.tool_input.max_results // 5' 2>/dev/null)

    if [ "$DEPTH" = "advanced" ]; then
      MSG="❌ Tavily search_depth=\"advanced\"는 3-5x 토큰 소비. 'basic'을 기본으로 사용하세요. advanced가 꼭 필요하면 사용자에게 명시 확인 후 호출."
      echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$MSG\"}}"
      exit 0
    fi

    if [ "$MAX" -gt 5 ] 2>/dev/null; then
      MSG="❌ max_results=$MAX 너무 큼. 5 이하로 제한하세요. 평균 결과 11KB/회 — 10개 = 110KB 직격."
      echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$MSG\"}}"
      exit 0
    fi
    ;;
esac

exit 0
