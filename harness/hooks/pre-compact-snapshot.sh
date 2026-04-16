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

# --- Pending Tasks Extraction (BEFORE auto-save overwrites latest) ---
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-}"
PENDING_FILE="$STATE_DIR/pending_tasks.md"
if [ -n "$OBSIDIAN_VAULT" ] && [ -d "$OBSIDIAN_VAULT/01-jamesclaw/harness" ]; then
  BEST_SESSION=""
  BEST_LINES=0
  for f in $(ls -t "$OBSIDIAN_VAULT/01-jamesclaw/harness"/session-*.md 2>/dev/null); do
    LINES=$(awk '
      /^## 다음 세션/ { capture=1; next }
      capture && /^## / { capture=0 }
      capture && /^- \[ \]/ && !/TODO$/ { count++ }
      END { print count+0 }
    ' "$f")
    if [ "$LINES" -gt "$BEST_LINES" ]; then
      BEST_LINES=$LINES
      BEST_SESSION=$f
    fi
  done
  if [ -n "$BEST_SESSION" ] && [ "$BEST_LINES" -gt 0 ]; then
    {
      echo "# Pending Tasks (from $(basename "$BEST_SESSION"))"
      echo "_Saved: $NOW_"
      echo ""
      awk '
        /^## 다음 세션/ { capture=1; next }
        capture && /^## / { capture=0 }
        capture { print }
      ' "$BEST_SESSION" | sed '/^$/d'
    } > "$PENDING_FILE"
    echo "[pending] $BEST_LINES pending tasks saved from $(basename "$BEST_SESSION")" >&2
  fi
fi

# --- Obsidian Session Summary (auto-save on compact) ---
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

# --- Memory files sync to Obsidian ---
MEMORY_SRC="$HOME/.claude/projects/D--jamesclew/memory"
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
MEMORY_DST="$VAULT/01-jamesclaw/memory"
if [ -d "$MEMORY_SRC" ] && [ -d "$VAULT" ]; then
  mkdir -p "$MEMORY_DST"
  cp -u "$MEMORY_SRC"/*.md "$MEMORY_DST/" 2>/dev/null
  echo "[memory-sync] Memory files synced to Obsidian: $MEMORY_DST" >&2
fi

# --- Wiki Ingest Queue (session discoveries → wiki pipeline) ---
WIKI_RAW="${OBSIDIAN_VAULT:-}/06-raw"
WIKI_QUEUE="${OBSIDIAN_VAULT:-}/06-raw/.ingest-queue"
if [ -n "$OBSIDIAN_VAULT" ] && [ -d "$WIKI_RAW" ]; then
  # Copy session summary to raw for wiki ingest
  if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ]; then
    cp "$SESSION_FILE" "$WIKI_RAW/$(basename "$SESSION_FILE")" 2>/dev/null
  fi
  # Mark any new files in 06-raw/ for next ingest cycle
  find "$WIKI_RAW" -name "*.md" -newer "$WIKI_QUEUE" -not -name ".ingest-queue" 2>/dev/null > "$WIKI_QUEUE.new" 2>/dev/null
  if [ -s "$WIKI_QUEUE.new" ]; then
    cat "$WIKI_QUEUE.new" >> "$WIKI_QUEUE" 2>/dev/null
    rm -f "$WIKI_QUEUE.new"
    echo "[wiki] $(wc -l < "$WIKI_QUEUE" 2>/dev/null) files queued for ingest" >&2
  else
    rm -f "$WIKI_QUEUE.new"
  fi
  touch "$WIKI_QUEUE"
fi
