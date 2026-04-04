#!/bin/bash
# pre-compact-snapshot.sh — PreCompact hook
# Automatically saves git state + work state before compact
# Writes to MEMORY.md-style snapshot for context preservation

STATE_DIR="$HOME/.claude/hooks/state"
SNAPSHOT_FILE="$STATE_DIR/pre-compact-snapshot.md"
mkdir -p "$STATE_DIR"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Git state
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_STATUS=$(git status --short 2>/dev/null | head -10)
GIT_MODIFIED=$(git status --short 2>/dev/null | grep -c "^ M\|^M " || echo 0)
GIT_UNTRACKED=$(git status --short 2>/dev/null | grep -c "^??" || echo 0)
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "none")

# Write snapshot
cat > "$SNAPSHOT_FILE" <<EOF
## Pre-Compact Snapshot — $NOW

### Git State
- Branch: $GIT_BRANCH
- Last commit: $LAST_COMMIT
- Modified: $GIT_MODIFIED files
- Untracked: $GIT_UNTRACKED files
$([ -n "$GIT_STATUS" ] && echo -e "\n\`\`\`\n$GIT_STATUS\n\`\`\`")

### Context
$(cat "$STATE_DIR/context_milestone" 2>/dev/null && echo "% milestone" || echo "unknown")
EOF

# Inject snapshot as additionalContext so it survives compact
SNAPSHOT_CONTENT=$(cat "$SNAPSHOT_FILE" | head -c 2000 | sed 's/"/\\"/g' | tr '\n' ' ')

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreCompact\",\"additionalContext\":\"[PRE-COMPACT SNAPSHOT] $SNAPSHOT_CONTENT\"}}"
