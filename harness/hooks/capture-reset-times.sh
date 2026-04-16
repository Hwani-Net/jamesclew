#!/bin/bash
# capture-reset-times.sh — UserPromptSubmit hook
# Captures 5H/7D reset timestamps and saves for Remote Trigger scheduling

INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

STATE_DIR="$HOME/.harness-state"
OUTPUT="$STATE_DIR/next-reset.json"
mkdir -p "$STATE_DIR"

# Extract reset timestamps (support both Unix epoch and ISO 8601)
FIVE_H=$(printf '%s' "$INPUT" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
SEVEN_D=$(printf '%s' "$INPUT" | jq -r '.rate_limits.seven_day.resets_at // empty' 2>/dev/null)
FIVE_PCT=$(printf '%s' "$INPUT" | jq -r '.rate_limits.five_hour.used_percent // empty' 2>/dev/null)
SEVEN_PCT=$(printf '%s' "$INPUT" | jq -r '.rate_limits.seven_day.used_percent // empty' 2>/dev/null)

# If no rate_limits in input, exit silently
[ -z "$FIVE_H" ] && [ -z "$SEVEN_D" ] && exit 0

# Write JSON (UTF-8)
cat > "$OUTPUT" <<EOF
{
  "five_hour": {
    "resets_at": "${FIVE_H}",
    "used_percent": ${FIVE_PCT:-0}
  },
  "seven_day": {
    "resets_at": "${SEVEN_D}",
    "used_percent": ${SEVEN_PCT:-0}
  },
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

exit 0
