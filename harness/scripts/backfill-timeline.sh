#!/usr/bin/env bash
# backfill-timeline.sh
# One-shot: add gbrain timeline entries for all existing pitfalls
# Run once from D:/jamesclew: bash harness/scripts/backfill-timeline.sh

set -euo pipefail

PITFALL_DIR="D:/jamesclew/harness/pitfalls"
LOG="$HOME/.harness-state/timeline-backfill.log"
mkdir -p "$HOME/.harness-state"

echo "[$(date +%Y-%m-%dT%H:%M:%S)] Starting pitfall timeline backfill" | tee -a "$LOG"

success=0
skipped=0
failed=0

for filepath in "$PITFALL_DIR"/pitfall-*.md; do
  filename="$(basename "$filepath" .md)"
  slug="$filename"

  # Extract date from frontmatter (date:) or body (**발견**: YYYY-MM-DD)
  date="$(python3 -c "
import re, sys
with open(r'$filepath', encoding='utf-8') as f:
    content = f.read()
m = re.search(r'date:\s*[\"\'']?(\d{4}-\d{2}-\d{2})', content)
if not m:
    m = re.search(r'\*\*발견\*\*:\s*(\d{4}-\d{2}-\d{2})', content)
print(m.group(1) if m else '2026-04-24')
" 2>/dev/null || echo "2026-04-24")"

  # Add timeline entry
  if gbrain timeline-add "$slug" "$date" "pitfall recorded" >> "$LOG" 2>&1; then
    echo "  OK  $slug @ $date"
    ((success++)) || true
  else
    echo "  FAIL $slug @ $date" | tee -a "$LOG"
    ((failed++)) || true
  fi
done

echo "" | tee -a "$LOG"
echo "[$(date +%Y-%m-%dT%H:%M:%S)] Backfill complete: success=$success failed=$failed skipped=$skipped" | tee -a "$LOG"
echo "Run 'gbrain stats' to verify Timeline count."
