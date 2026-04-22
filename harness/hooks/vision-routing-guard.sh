#!/bin/bash
# PreToolUse on mcp__expect__screenshot
# 검사: 이 세션에서 snapshot 모드 선행 호출 이력이 있는가
# 경고 (차단 아님): 이중 패스 위반 경고 주입

INPUT=$(cat)
MODE=$(echo "$INPUT" | jq -r '.tool_input.mode // "screenshot"')
LOG=~/.harness-state/vision-pass.log
mkdir -p ~/.harness-state

# snapshot 모드 호출이면 로그 기록만 하고 종료
if [ "$MODE" = "snapshot" ] || [ "$MODE" = "annotated" ]; then
  echo "$(date +%s) snapshot" >> "$LOG"
  exit 0
fi

# screenshot 모드 — 이 세션에서 snapshot 기록 있나
SESSION_START=$(stat -c %Y ~/.harness-state 2>/dev/null || echo 0)
RECENT_SNAPSHOT=$(tail -20 "$LOG" 2>/dev/null | awk -v start="$SESSION_START" '$1 > start && /snapshot/' | wc -l)

if [ "$RECENT_SNAPSHOT" -eq 0 ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"[⚠️ VISION DUAL-PASS] snapshot 모드 선행 없이 screenshot 직진. ARIA 1차 → Vision 2차 이중 패스 권장. mcp__expect__screenshot(mode:'snapshot')을 먼저 시도하여 ref ID로 요소 식별 가능한지 확인하세요.\"}}"
fi

echo "$(date +%s) screenshot" >> "$LOG"
exit 0
