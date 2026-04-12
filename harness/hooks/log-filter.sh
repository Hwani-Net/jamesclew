#!/bin/bash
# log-filter.sh — PostToolUse hook for Bash
# When tool_result exceeds 50 lines, filters to error/warning/fail lines only
# and injects a compact summary via additionalContext.
# Token savings: prevents bulk log output from inflating context window.

INPUT=$(cat)

# Extract tool output from JSON — look for output field
OUTPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # Try common output field names
    for key in ['output', 'result', 'stdout', 'content']:
        if key in data and isinstance(data[key], str):
            print(data[key])
            sys.exit(0)
    # Check nested tool_result
    if 'tool_result' in data:
        tr = data['tool_result']
        if isinstance(tr, str):
            print(tr)
        elif isinstance(tr, dict):
            for key in ['output', 'content', 'stdout']:
                if key in tr:
                    print(tr[key])
                    sys.exit(0)
except Exception:
    pass
" 2>/dev/null)

if [ -z "$OUTPUT" ]; then
  exit 0
fi

LINE_COUNT=$(echo "$OUTPUT" | wc -l)

# Only filter if output exceeds 50 lines
if [ "$LINE_COUNT" -lt 50 ]; then
  exit 0
fi

# Filter to error/warning/fail related lines (case-insensitive)
FILTERED=$(echo "$OUTPUT" | grep -iE "(error|warn|fail|fatal|exception|traceback|denied|refused|abort|crash|critical|ERR|WARN)" 2>/dev/null)
FILTERED_COUNT=$(echo "$FILTERED" | grep -c . 2>/dev/null || echo 0)

if [ "$FILTERED_COUNT" -eq 0 ]; then
  # No errors found — just report line count
  MSG="[LOG-FILTER] Bash 출력 ${LINE_COUNT}줄 → 에러/경고 없음 (출력 생략). 전체 로그 필요 시 명시 요청."
else
  # Truncate filtered output to 20 lines max
  FILTERED_TRUNC=$(echo "$FILTERED" | head -20)
  FILTERED_TRUNC_ESC=$(echo "$FILTERED_TRUNC" | sed 's/"/\\"/g' | tr '\n' '|')
  MSG="[LOG-FILTER] Bash 출력 ${LINE_COUNT}줄 → ${FILTERED_COUNT}건 에러/경고 필터링: ${FILTERED_TRUNC_ESC}"
fi

MSG_ESC=$(echo "$MSG" | sed 's/"/\\"/g')
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"$MSG_ESC\"}}"

exit 0
