#!/bin/bash
# register-reset-trigger.sh — Output Remote Trigger config for reset ping
# Run by Claude during sessions to update the trigger schedule
# Usage: bash register-reset-trigger.sh

STATE_FILE="$HOME/.harness-state/next-reset.json"
[ ! -f "$STATE_FILE" ] && echo "ERROR: $STATE_FILE not found" && exit 1

# Parse reset timestamps
FIVE_H=$(jq -r '.five_hour.resets_at // empty' "$STATE_FILE" 2>/dev/null)
SEVEN_D=$(jq -r '.seven_day.resets_at // empty' "$STATE_FILE" 2>/dev/null)

# Convert ISO 8601 or epoch to UTC cron expression (+1 minute)
convert_to_cron() {
  local iso="$1"
  [ -z "$iso" ] && echo "" && return

  local epoch
  if [[ "$iso" =~ ^[0-9]+$ ]]; then
    epoch="$iso"
  else
    # Try GNU date first, fall back to Python
    epoch=$(date -u -d "$iso" +%s 2>/dev/null) || \
    epoch=$(python3 -c "
import datetime, sys
s = '$iso'.replace('Z', '+00:00')
try:
    dt = datetime.datetime.fromisoformat(s)
    print(int(dt.timestamp()))
except Exception as e:
    sys.exit(1)
" 2>/dev/null)
  fi

  [ -z "$epoch" ] && echo "" && return

  # Add 60 seconds (fire 1 minute AFTER reset)
  epoch=$((epoch + 60))

  # Format as cron: minute hour day month weekday
  local cron
  cron=$(date -u -d "@$epoch" "+%M %H %d %m *" 2>/dev/null) || \
  cron=$(python3 -c "
import datetime
t = datetime.datetime.utcfromtimestamp($epoch)
print(f'{t.minute} {t.hour} {t.day} {t.month} *')
" 2>/dev/null)

  echo "$cron"
}

FIVE_H_CRON=$(convert_to_cron "$FIVE_H")
SEVEN_D_CRON=$(convert_to_cron "$SEVEN_D")

# Also read prompt script path
PROMPT_SCRIPT="D:/jamesclew/harness/scripts/reset-ping-prompt.sh"

cat <<EOF
# Reset Ping Remote Trigger Configuration
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 5H Reset Ping
- Reset at:          ${FIVE_H:-"(not set)"}
- Cron (UTC, +1min): ${FIVE_H_CRON:-"(could not compute — check jq/date)"}
- Trigger name:      claude-5h-reset-ping

## 7D Reset Ping
- Reset at:          ${SEVEN_D:-"(not set)"}
- Cron (UTC, +1min): ${SEVEN_D_CRON:-"(could not compute — check jq/date)"}
- Trigger name:      claude-7d-reset-ping

## Prompt to inject at trigger fire
Run: bash $PROMPT_SCRIPT
(Script outputs the session re-injection prompt text)

## Next Steps for Claude — RemoteTrigger registration
Use the schedule skill or RemoteTrigger tool:

1. List existing triggers:
   RemoteTrigger(action: "list")

2. Register/update 5H ping (if FIVE_H_CRON is set):
   RemoteTrigger(
     action: "upsert",
     name: "claude-5h-reset-ping",
     cron_expression: "$FIVE_H_CRON",
     prompt: "\$(bash $PROMPT_SCRIPT)"
   )

3. Register/update 7D ping (if SEVEN_D_CRON is set):
   RemoteTrigger(
     action: "upsert",
     name: "claude-7d-reset-ping",
     cron_expression: "$SEVEN_D_CRON",
     prompt: "\$(bash $PROMPT_SCRIPT)"
   )

4. Verify:
   RemoteTrigger(action: "list")
EOF
