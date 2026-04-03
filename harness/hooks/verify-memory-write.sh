#!/bin/bash
# PreToolUse hook: Verify URLs in memory file writes before allowing
# Prevents hallucinated URLs/repos from being persisted to memory

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# Only check memory files
case "$FILE_PATH" in
  */.claude/*/memory/*|*/Obsidian-Vault/*) ;;
  *) exit 0 ;;
esac

# Get content to write
if [ "$TOOL" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)
elif [ "$TOOL" = "Edit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty' 2>/dev/null)
else
  exit 0
fi

if [ -z "$CONTENT" ]; then
  exit 0
fi

STATE_DIR="$HOME/.claude/hooks/state"
mkdir -p "$STATE_DIR"
LOG_FILE="$STATE_DIR/hallucination-check.log"

# Extract GitHub repo URLs from content
REPOS=$(echo "$CONTENT" | grep -oE 'github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+' | sed 's|github.com/||' | sort -u)

FAILED=0
FAILURES=""

for REPO in $REPOS; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://api.github.com/repos/$REPO" 2>/dev/null)
  if [ "$HTTP_CODE" = "404" ]; then
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES} $REPO(404)"
    echo "[$(date +%H:%M:%S)] MEMORY BLOCK: repo $REPO (404) in $FILE_PATH" >> "$LOG_FILE"
  fi
done

if [ "$FAILED" -gt 0 ]; then
  REASON="메모리에 존재하지 않는 GitHub repo 기록 차단:${FAILURES}"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${REASON}\"}}" >&2
  exit 2
fi

exit 0
