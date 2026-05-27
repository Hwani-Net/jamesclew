#!/usr/bin/env bash
# wiki-sync-scheduler.sh — SessionStart auto-trigger for 06-raw → 05-wiki sync
# Runs Phase 2 only (file move) if 24h have passed since last run.
# Silent on error — never blocks SessionStart.
#
# DEPRECATED 2026-05-19 (P-172): gbrain import/sync phases removed.
# Phase 1 (gbrain list) and Phase 3 (gbrain import/sync) are no-ops.
# Replace: /inbox-process skill for manual wiki sync.

set -euo pipefail

STATE_DIR="$HOME/.harness-state"
LAST_SYNC_FILE="$STATE_DIR/wiki-sync-last"
LOG_FILE="$STATE_DIR/wiki-sync-scheduler.log"
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
RAW_DIR="$VAULT/06-raw"
WIKI_DIR="$VAULT/05-wiki"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG_FILE"
}

# Ensure state dir exists
mkdir -p "$STATE_DIR"

# --- 24h gate ---
NOW=$(date +%s)
LAST=0
if [ -f "$LAST_SYNC_FILE" ]; then
  LAST=$(cat "$LAST_SYNC_FILE" 2>/dev/null || echo 0)
fi
ELAPSED=$(( NOW - LAST ))

if [ "$ELAPSED" -lt 86400 ]; then
  log "SKIP — last sync ${ELAPSED}s ago (< 86400s)"
  exit 0
fi

log "START — last sync ${ELAPSED}s ago, running Phase 2 (file move only)"

# Record start time immediately to prevent concurrent runs
echo "$NOW" > "$LAST_SYNC_FILE"

# --- Phase 2: Move 06-raw → 05-wiki subdirectory ---
MOVED=0
if [ -d "$RAW_DIR" ]; then
  for f in "$RAW_DIR"/*.md; do
    [ -f "$f" ] || continue
    # Skip hidden/queue files
    basename_f=$(basename "$f")
    [[ "$basename_f" == .* ]] && continue

    # Classify destination
    CONTENT=$(head -40 "$f" 2>/dev/null || true)
    FRONTMATTER=$(head -10 "$f" 2>/dev/null || true)

    DEST_SUB="sources"  # default
    if echo "$FRONTMATTER" | grep -qi "url:"; then
      DEST_SUB="sources"
    elif echo "$basename_f $CONTENT" | grep -qi "concept\|pattern\|principle\|원칙\|개념"; then
      DEST_SUB="concepts"
    elif echo "$basename_f $CONTENT" | grep -qi "analysis\|analyses\|리서치\|research\|benchmark"; then
      DEST_SUB="analyses"
    elif echo "$basename_f" | grep -qi "source"; then
      DEST_SUB="sources"
    fi

    DEST_DIR="$WIKI_DIR/$DEST_SUB"
    mkdir -p "$DEST_DIR"

    # Move (overwrite if exists)
    mv -f "$f" "$DEST_DIR/$basename_f" 2>/dev/null && {
      log "Phase2: moved $basename_f → 05-wiki/$DEST_SUB/"
      MOVED=$((MOVED + 1))
    } || log "Phase2: failed to move $basename_f (non-fatal)"
  done
fi
log "Phase2: total moved = $MOVED"

log "DONE — moved=${MOVED} files (gbrain phases skipped, P-172)"

# Update timestamp to completion time
date +%s > "$LAST_SYNC_FILE"

exit 0
