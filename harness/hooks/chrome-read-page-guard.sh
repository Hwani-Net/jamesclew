#!/bin/bash
# PreToolUse on claude-in-chrome screenshot/computer tools
# 검사: read_page 선행 호출 여부

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
LOG=~/.harness-state/chrome-read-pass.log
mkdir -p ~/.harness-state

# read_page 호출이면 로그만
if [[ "$TOOL" == *"read_page"* ]] || [[ "$TOOL" == *"tabs_context"* ]]; then
  echo "$(date +%s) read_page" >> "$LOG"
  exit 0
fi

# get_screenshot / computer 계열이면 read_page 선행 확인
if [[ "$TOOL" == *"get_screenshot"* ]] || [[ "$TOOL" == *"computer"* ]] || [[ "$TOOL" == *"find"* ]]; then
  SESSION_START=$(stat -c %Y ~/.harness-state 2>/dev/null || echo 0)
  RECENT_READ=$(tail -20 "$LOG" 2>/dev/null | awk -v start="$SESSION_START" '$1 > start && /read_page/' | wc -l)

  if [ "$RECENT_READ" -eq 0 ]; then
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"[⚠️ CHROME DUAL-PASS] read_page(텍스트 DOM) 선행 없이 screenshot/computer 직진. claude-in-chrome 이중 패스 권장: read_page → get_screenshot → (필요 시) Opus Vision.\"}}"
  fi
fi

exit 0
