#!/bin/bash
# pre-compact-snapshot.sh — PreCompact hook
# Automatically saves git state + work state before compact
# Writes to MEMORY.md-style snapshot for context preservation

STATE_DIR="$HOME/.harness-state"
SNAPSHOT_FILE="$STATE_DIR/pre-compact-snapshot.md"
mkdir -p "$STATE_DIR"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Git state
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GIT_STATUS=$(git status --short 2>/dev/null | head -10)
GIT_MODIFIED=$(git status --short 2>/dev/null | grep -cE "^ ?M" 2>/dev/null || true)
GIT_MODIFIED=${GIT_MODIFIED:-0}
GIT_UNTRACKED=$(git status --short 2>/dev/null | grep -c "^??" 2>/dev/null || true)
GIT_UNTRACKED=${GIT_UNTRACKED:-0}
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

# Inject snapshot via systemMessage (PreCompact uses top-level fields, not hookSpecificOutput)
SNAPSHOT_CONTENT=$(cat "$SNAPSHOT_FILE" | head -c 2000 | sed 's/"/\\"/g' | tr '\n' ' ')

echo "{\"systemMessage\":\"[PRE-COMPACT SNAPSHOT] $SNAPSHOT_CONTENT\"}"

# --- Obsidian Session Summary (auto-save on compact) ---
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-}"
if [ -n "$OBSIDIAN_VAULT" ]; then
  OBSIDIAN_DIR="$OBSIDIAN_VAULT/01-jamesclaw/harness"
  mkdir -p "$OBSIDIAN_DIR"

  # Topic from last commit's conventional commit prefix (e.g., feat(mcp) → mcp)
  TOPIC=$(git log --oneline -1 2>/dev/null | sed -E 's/^[a-f0-9]+ [a-z]+\(([^)]+)\).*/\1/' | head -c 20)
  [ -z "$TOPIC" ] && TOPIC="auto"

  SESSION_FILE="$OBSIDIAN_DIR/session-$(date +%Y-%m-%d)-${TOPIC}.md"

  # Don't overwrite existing session file for same day+topic
  if [ ! -f "$SESSION_FILE" ]; then
    COMMITS=$(git log --oneline -20 2>/dev/null)
    CHANGED=$(git diff --stat HEAD~10..HEAD 2>/dev/null | tail -1)
    LAST_RESULT=$(cat "$STATE_DIR/last_result.txt" 2>/dev/null | head -10)

    cat > "$SESSION_FILE" <<OBSEOF
# Session $(date +%Y-%m-%d) — ${TOPIC}

## 기간
- 시작: $(git log --reverse -20 --format="%ai" 2>/dev/null | head -1 || echo "unknown")
- 저장: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 커밋 이력
${COMMITS:-"(no commits in last 12h)"}

## 변경 요약
${CHANGED:-"(no changes)"}

## 작업 결과
${LAST_RESULT:-"(no result logged)"}

## 다음 세션
- [ ] TODO
OBSEOF
    echo "[obsidian] Session saved: $SESSION_FILE" >&2
  fi
fi

# Block compact if obsidian save was expected but failed
if [ -n "$OBSIDIAN_VAULT" ] && [ ! -d "$OBSIDIAN_DIR" ]; then
  echo '{"decision":"block","reason":"Obsidian vault not accessible. Run /저장 manually before compact."}'
  exit 2
fi
