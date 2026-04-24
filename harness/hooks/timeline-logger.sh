#!/usr/bin/env bash
# timeline-logger.sh — PostToolUse hook
# Adds gbrain timeline entries when:
#   1. A pitfall file is written  → timeline-add pitfall-NNN date "pitfall recorded"
#   2. A session-learning slug is stored → timeline-add <slug> today "session learning"
#
# Input: Claude Code PostToolUse JSON on stdin
# Output: silent (errors logged only)

LOG="$HOME/.harness-state/timeline-logger.log"
mkdir -p "$HOME/.harness-state"

# Read stdin JSON
INPUT="$(cat)"

# Extract tool name and file path
TOOL_NAME="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null || echo "")"
FILE_PATH="$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); inp=d.get('tool_input',{}); print(inp.get('file_path', inp.get('path','')))" 2>/dev/null || echo "")"

TODAY="$(date +%Y-%m-%d)"

# Only act on Write tool calls
if [[ "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

# Case 1: pitfall file written
if echo "$FILE_PATH" | grep -qE 'pitfall-[0-9]+-[^/]+\.md$'; then
  BASENAME="$(basename "$FILE_PATH" .md)"
  SLUG="$BASENAME"

  # Extract date from frontmatter or body
  DATE="$(python3 -c "
import re, sys
try:
    with open(r'$FILE_PATH', encoding='utf-8') as f:
        content = f.read()
    m = re.search(r'date:\s*[\"\'']?(\d{4}-\d{2}-\d{2})', content)
    if not m:
        m = re.search(r'\*\*발견\*\*:\s*(\d{4}-\d{2}-\d{2})', content)
    print(m.group(1) if m else '$TODAY')
except:
    print('$TODAY')
" 2>/dev/null || echo "$TODAY")"

  gbrain timeline-add "$SLUG" "$DATE" "pitfall recorded" >> "$LOG" 2>&1 || true
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] timeline-add $SLUG @ $DATE (pitfall)" >> "$LOG"
fi

# Case 2: session-learning slug (harness/scripts/session-learning.sh outputs slug to a state file)
# Watch for write to ~/.harness-state/last_learning_slug
if echo "$FILE_PATH" | grep -q 'last_learning_slug'; then
  SLUG="$(cat "$FILE_PATH" 2>/dev/null | tr -d '[:space:]')"
  if [[ -n "$SLUG" ]]; then
    gbrain timeline-add "$SLUG" "$TODAY" "session learning" >> "$LOG" 2>&1 || true
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] timeline-add $SLUG @ $TODAY (session learning)" >> "$LOG"
  fi
fi

exit 0
