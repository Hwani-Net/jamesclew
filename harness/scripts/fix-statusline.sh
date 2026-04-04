#!/bin/bash
# fix-statusline.sh — Fix awesome-statusline 5H/7D N/A on Windows
# Usage: bash ~/.claude/scripts/fix-statusline.sh
#
# Patches awesome-statusline.sh for Windows compatibility:
# 1. Adds ~/.claude/.credentials.json fallback for token
# 2. Fixes stat command (GNU vs macOS)
# 3. Fixes date parsing (GNU vs macOS)
# 4. Clears usage cache

SCRIPT="$HOME/.claude/awesome-statusline.sh"

if [ ! -f "$SCRIPT" ]; then
  echo "❌ awesome-statusline.sh not found"
  exit 1
fi

# Check if already patched
if grep -q ".credentials.json" "$SCRIPT" 2>/dev/null; then
  echo "✅ Already patched. Clearing cache only."
  rm -f /tmp/.claude_usage_cache
  exit 0
fi

# Patch 1: Add Windows credentials fallback
sed -i 's|token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '"'"'.claudeAiOauth.accessToken // empty'"'"' 2>/dev/null)|token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '"'"'.claudeAiOauth.accessToken // empty'"'"' 2>/dev/null)\n    # Windows fallback\n    if [[ -z "$token" ]] \&\& [[ -f "$HOME/.claude/.credentials.json" ]]; then\n        token=$(jq -r '"'"'.claudeAiOauth.accessToken // empty'"'"' "$HOME/.claude/.credentials.json" 2>/dev/null)\n    fi|' "$SCRIPT"

# Patch 2: Fix stat command
sed -i 's|stat -f %m "$cache_file"|stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file"|g' "$SCRIPT"

# Patch 3: Fix date parsing — add GNU date fallback before macOS date
sed -i 's|local reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)|local reset_epoch=$(date -d "$normalized" "+%s" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)|g' "$SCRIPT"

# Patch 4: Add stale cache fallback on rate limit
if ! grep -q "stale cache as fallback" "$SCRIPT" 2>/dev/null; then
  sed -i 's|    return 1\n}|    # Rate limited — use stale cache as fallback\n    if [[ -f "$cache_file" ]]; then\n        cat "$cache_file"\n        return 0\n    fi\n    return 1\n}|' "$SCRIPT"
fi

# Clear cache
rm -f /tmp/.claude_usage_cache

echo "✅ Patched: $SCRIPT"
echo "   - Windows credentials fallback added"
echo "   - stat/date compatibility fixed"
echo "   - Cache cleared"
